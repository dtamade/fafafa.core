unit fafafa.core.fs.watch;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes
  {$IFDEF WINDOWS}, Windows{$ENDIF};

const
  // ✅ 错误码常量：与 fafafa.core.fs.errors.FS_ERROR_UNKNOWN 保持一致
  // 用于表示功能不支持
  FS_WATCH_ERROR_NOT_SUPPORTED = -999;

type
  // 事件类型（对齐多平台能力，合并最小公约数）
  TFsWatchEventKind = (
    wekCreated,
    wekModified,
    wekDeleted,
    wekRenamed,
    wekOverflow,
    wekAttrib
  );

  TFsWatchEventKinds = set of TFsWatchEventKind;

  // 文件系统事件（回调参数）
  TFsWatchEvent = record
    Kind: TFsWatchEventKind;
    Path: string;      // 受影响路径（绝对路径）
    OldPath: string;   // 若为重命名，提供旧路径；否则为空
    IsDir: Boolean;    // 是否目录（尽力提供，后端可能不完全可靠）
    Timestamp: QWord;  // 单调时钟或系统时钟（后端决定）；用于排序/去抖
    RawError: Integer; // 溢出/后端错误信息（非 0 表示异常提示）
  end;

  // 后端类型（自动/原生/轮询）
  TFsWatchBackend = (
    wbAuto,
    wbNative,
    wbPolling
  );

  // 过滤器（简单通配符首版；正则可留待增强）
  TFsWatchFilters = record
    IncludeKinds: TFsWatchEventKinds;   // 关心的事件类型
    IncludePatterns: array of string;   // 包含通配符（如: '*.pas'）
    ExcludePatterns: array of string;   // 排除通配符（如: '.git/*'）
  end;

  // 观察选项
  TFsWatchOptions = record
    Recursive: Boolean;          // 是否递归子目录
    CoalesceLatencyMs: Integer;  // 事件合并/去抖延迟，0 表示尽快回调
    MaxQueue: Integer;           // 队列最大长度（防止内存膨胀）
    FollowSymlinks: Boolean;     // 递归时是否跟随符号链接
    Filters: TFsWatchFilters;    // 过滤器
    Backend: TFsWatchBackend;    // 后端选择
  end;

  // 观察者（回调接口）
  IFsWatchObserver = interface
    ['{2A2E7EC2-3FA0-4B3B-B32C-0A9A2A4D70B7}']
    procedure OnEvent(const E: TFsWatchEvent);
    procedure OnError(const Code: Integer; const Message: string);
  end;

  // 观察器（核心接口）
  IFsWatcher = interface
    ['{E9E4F4A2-8D3D-4FDE-A4C2-7F3E8C3F4C6D}']
    // 开始观察：Root 为根路径（绝对路径建议）；返回 0 成功，<0 为 FsErrorCode 负码
    function Start(const Root: string; const Opts: TFsWatchOptions; const Obs: IFsWatchObserver): Integer;
    // 停止观察：幂等
    procedure Stop;
    // 是否运行中
    function IsRunning: Boolean;
    // 统计：Dropped（丢弃数），Delivered（已投递数）；返回 True 表示可用
    function Stats(out Dropped: QWord; out Delivered: QWord): Boolean;
    // 动态增删子路径（部分后端可选支持）
    function AddPath(const SubRoot: string): Integer;
    function RemovePath(const SubRoot: string): Integer;
  end;

// 提供默认选项（便于快速上手）
function DefaultFsWatchOptions: TFsWatchOptions;
// 工厂：创建默认后端的观察器（首版可返回未实现的占位实现）
function CreateFsWatcher: IFsWatcher;

implementation

type
  {$IFDEF WINDOWS}
  PFileNotifyInformation = ^TFileNotifyInformation;
  TFileNotifyInformation = packed record
    NextEntryOffset: DWORD;
    Action: DWORD;
    FileNameLength: DWORD;
    FileName: array[0..0] of WideChar;
  end;

  TWatchThread = class(TThread)
  private
    FDirHandle: THandle;
    FRoot: UnicodeString;
    FObs: IFsWatchObserver;
    FStopEvent: THandle;
    FDropped, FDelivered: QWord;
    FOpts: TFsWatchOptions;
    FPendingOldName: UnicodeString;
    FPendingRenames: TStringList; // store OldName=timestamp(ms) as string
    function ShouldDeliver(const Kind: TFsWatchEventKind; const RelName: UnicodeString): Boolean;
    procedure DispatchEvent(const Kind: TFsWatchEventKind; const RelName, OldRelName: UnicodeString);
    procedure AddPendingOld(const OldRelName: UnicodeString);
    function PopRecentOld(out OldRelName: UnicodeString; const WindowMs: QWord): Boolean;
    procedure CleanupStaleRenames(const WindowMs: QWord);
  protected
    procedure Execute; override;
  public
    constructor Create(const ARoot: UnicodeString; const AObs: IFsWatchObserver; const AOpts: TFsWatchOptions);
    destructor Destroy; override;
    procedure RequestStop;
    function Stats(out Dropped, Delivered: QWord): Boolean;
  end;

  TFsWatcherWin = class(TInterfacedObject, IFsWatcher)
  private
    FThread: TWatchThread;
    FRunning: Boolean;
  public
    function Start(const Root: string; const Opts: TFsWatchOptions; const Obs: IFsWatchObserver): Integer;
    procedure Stop;
    function IsRunning: Boolean;
    function Stats(out Dropped: QWord; out Delivered: QWord): Boolean;
    function AddPath(const SubRoot: string): Integer;
    function RemovePath(const SubRoot: string): Integer;
  end;
  {$ENDIF}

  // 占位实现：非 Windows 或不支持平台
  TFsWatcherStub = class(TInterfacedObject, IFsWatcher)
  private
    FRunning: Boolean;
    FDropped, FDelivered: QWord;
  public
    function Start(const Root: string; const Opts: TFsWatchOptions; const Obs: IFsWatchObserver): Integer;
    procedure Stop;
    function IsRunning: Boolean;
    function Stats(out Dropped: QWord; out Delivered: QWord): Boolean;
    function AddPath(const SubRoot: string): Integer;
    function RemovePath(const SubRoot: string): Integer;
  end;

function DefaultFsWatchOptions: TFsWatchOptions;
begin
  Result.Recursive := True;
  Result.CoalesceLatencyMs := 50;  // 50ms 去抖
  Result.MaxQueue := 4096;
  Result.FollowSymlinks := False;
  Result.Filters.IncludeKinds := [wekCreated, wekModified, wekDeleted, wekRenamed];
  SetLength(Result.Filters.IncludePatterns, 0);
  SetLength(Result.Filters.ExcludePatterns, 0);
  Result.Backend := wbAuto;
end;

{$IFDEF WINDOWS}
{ TWatchThread }
constructor TWatchThread.Create(const ARoot: UnicodeString; const AObs: IFsWatchObserver; const AOpts: TFsWatchOptions);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRoot := ARoot;
  FObs := AObs;
  FOpts := AOpts;
  FDropped := 0;
  FDelivered := 0;
  FPendingRenames := TStringList.Create;
  FPendingRenames.Sorted := False;
  FPendingRenames.Duplicates := dupAccept;
  FStopEvent := CreateEventW(nil, True, False, nil);
  FDirHandle := CreateFileW(PWideChar(FRoot), FILE_LIST_DIRECTORY,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
    nil, OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OVERLAPPED,
    0);
end;

destructor TWatchThread.Destroy;
begin
  if FDirHandle <> INVALID_HANDLE_VALUE then CloseHandle(FDirHandle);
  if FStopEvent <> 0 then CloseHandle(FStopEvent);
  FreeAndNil(FPendingRenames);
  inherited Destroy;
end;

procedure TWatchThread.RequestStop;
begin
  if FStopEvent <> 0 then SetEvent(FStopEvent);
end;

function TWatchThread.ShouldDeliver(const Kind: TFsWatchEventKind; const RelName: UnicodeString): Boolean;
  function WildcardMatchW(const P, S: UnicodeString): Boolean;
    // 支持简单通配符: * 任意序列, ? 任意单字符；大小写不敏感（Windows）
    function MatchAt(pi, si: Integer): Boolean;
    begin
      while True do
      begin
        if (pi > Length(P)) then Exit(si > Length(S));
        case P[pi] of
          '*':
            begin
              // 跳过连续的*
              while (pi <= Length(P)) and (P[pi] = '*') do Inc(pi);
              if pi > Length(P) then Exit(True);
              while (si <= Length(S)) do
              begin
                if MatchAt(pi, si) then Exit(True);
                Inc(si);
              end;
              Exit(False);
            end;
          '?':
            begin
              if si > Length(S) then Exit(False);
              Inc(pi); Inc(si);
            end;
        else
          begin
            if (si > Length(S)) then Exit(False);
            if UpCase(P[pi]) <> UpCase(S[si]) then Exit(False);
            Inc(pi); Inc(si);
          end;
        end;
      end;
    end;
  begin
    if P = '' then Exit(False);
    Result := MatchAt(1, 1);
  end;
var
  i: Integer;
  pat: UnicodeString;
begin
  // 事件种类过滤
  if not (Kind in FOpts.Filters.IncludeKinds) then Exit(False);

  // IncludePatterns：若非空，则至少匹配一个
  if Length(FOpts.Filters.IncludePatterns) > 0 then
  begin
    Result := False;
    for i := 0 to High(FOpts.Filters.IncludePatterns) do
    begin
      pat := UTF8Decode(FOpts.Filters.IncludePatterns[i]);
      if WildcardMatchW(pat, RelName) then begin Result := True; Break; end;
    end;
    if not Result then Exit(False);
  end
  else
    Result := True;

  // ExcludePatterns：任一匹配则排除
  for i := 0 to High(FOpts.Filters.ExcludePatterns) do
  begin
    pat := UTF8Decode(FOpts.Filters.ExcludePatterns[i]);
    if WildcardMatchW(pat, RelName) then Exit(False);
  end;
end;

procedure TWatchThread.AddPendingOld(const OldRelName: UnicodeString);
var
  ts: QWord;
begin
  ts := GetTickCount64;
  FPendingRenames.Add(UTF8Encode(OldRelName) + '=' + IntToStr(ts));
end;

function TWatchThread.PopRecentOld(out OldRelName: UnicodeString; const WindowMs: QWord): Boolean;
var
  i: Integer;
  s, nameUtf8: string;
  p: SizeInt;
  ts, nowms: QWord;
begin
  Result := False;
  OldRelName := '';
  nowms := GetTickCount64;
  for i := FPendingRenames.Count-1 downto 0 do
  begin
    s := FPendingRenames[i];
    p := Pos('=', s);
    if p > 0 then
    begin
      nameUtf8 := Copy(s, 1, p-1);
      ts := StrToQWordDef(Copy(s, p+1, MaxInt), 0);
      if (ts>0) and (nowms - ts <= WindowMs) then
      begin
        OldRelName := UTF8Decode(nameUtf8);
        FPendingRenames.Delete(i);
        Exit(True);
      end;
    end;
  end;
end;

procedure TWatchThread.CleanupStaleRenames(const WindowMs: QWord);
var
  i: Integer;
  s: string;
  p: SizeInt;
  ts, nowms: QWord;
begin
  nowms := GetTickCount64;
  for i := FPendingRenames.Count-1 downto 0 do
  begin
    s := FPendingRenames[i];
    p := Pos('=', s);
    if p > 0 then
    begin
      ts := StrToQWordDef(Copy(s, p+1, MaxInt), 0);
      if (ts=0) or (nowms - ts > WindowMs) then
        FPendingRenames.Delete(i);
    end
    else
      FPendingRenames.Delete(i);
  end;
end;

procedure TWatchThread.DispatchEvent(const Kind: TFsWatchEventKind; const RelName, OldRelName: UnicodeString);
var
  E: TFsWatchEvent;
  FullW: UnicodeString;
  Attr: DWORD;
begin
  if not ShouldDeliver(Kind, RelName) then Exit;
  FillChar(E, SizeOf(E), 0);
  E.Kind := Kind;
  FullW := FRoot + '\' + RelName;
  E.Path := UTF8Encode(FullW);
  if OldRelName <> '' then
    E.OldPath := UTF8Encode(FRoot + '\' + OldRelName)  // ✅ 修复：使用单个反斜杠，与 E.Path 保持一致
  else
    E.OldPath := '';
  Attr := GetFileAttributesW(PWideChar(FullW));
  E.IsDir := (Attr <> INVALID_FILE_ATTRIBUTES) and ((Attr and FILE_ATTRIBUTE_DIRECTORY) <> 0);
  E.Timestamp := GetTickCount64;
  if Assigned(FObs) then
    FObs.OnEvent(E);
  Inc(FDelivered);
end;

procedure TWatchThread.Execute;
const
  BUF_SIZE = 64*1024;
var
  Buffer: array[0..BUF_SIZE-1] of Byte;
  BytesReturned: DWORD;
  Overl: TOverlapped;
  Events: array[0..1] of THandle;
  WaitRes: DWORD;
  Info: PFileNotifyInformation;
  Offset: DWORD;
  NameLen: DWORD;
  RelName: UnicodeString;
  Filter: DWORD;
  TimeoutMs: DWORD;
begin
  if FDirHandle = INVALID_HANDLE_VALUE then Exit;
  ZeroMemory(@Overl, SizeOf(Overl));
  Overl.hEvent := CreateEventW(nil, True, False, nil);
  try
    Events[0] := FStopEvent;
    Events[1] := Overl.hEvent;

    Filter := FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME or
              FILE_NOTIFY_CHANGE_ATTRIBUTES or FILE_NOTIFY_CHANGE_SIZE or
              FILE_NOTIFY_CHANGE_LAST_WRITE;

    while WaitForSingleObject(FStopEvent, 0) <> WAIT_OBJECT_0 do
    begin
      ResetEvent(Overl.hEvent);
      if not ReadDirectoryChangesW(FDirHandle, @Buffer[0], BUF_SIZE, FOpts.Recursive,
        Filter, @BytesReturned, @Overl, nil) then
      begin
        Inc(FDropped);
        Sleep(10);
        Continue;
      end;

      // 等待窗口：使用 CoalesceLatencyMs 以简单合并
      TimeoutMs := 1000;
      if FOpts.CoalesceLatencyMs > 0 then
        TimeoutMs := DWORD(FOpts.CoalesceLatencyMs);
      WaitRes := WaitForMultipleObjects(2, @Events[0], False, TimeoutMs);
      if WaitRes = WAIT_OBJECT_0 then Exit; // stop
      if WaitRes = WAIT_TIMEOUT then Continue;

      Offset := 0; FPendingOldName := '';
      // 简易去重：同一批中相邻相同事件与名称不重复投递
      var PrevName: UnicodeString = '';
      var PrevKind: TFsWatchEventKind = wekAttrib;
      const RENAME_WINDOW_MS = 2000;
      repeat
        Info := PFileNotifyInformation(@Buffer[Offset]);
        NameLen := Info^.FileNameLength div SizeOf(WideChar);
        SetString(RelName, PWideChar(@Info^.FileName[0]), NameLen);
        case Info^.Action of
          FILE_ACTION_ADDED:
            if not ((PrevKind=wekCreated) and (PrevName=RelName)) then
              DispatchEvent(wekCreated, RelName, '');
          FILE_ACTION_REMOVED:
            if not ((PrevKind=wekDeleted) and (PrevName=RelName)) then
              DispatchEvent(wekDeleted, RelName, '');
          FILE_ACTION_MODIFIED:
            if not ((PrevKind=wekModified) and (PrevName=RelName)) then
              DispatchEvent(wekModified, RelName, '');
          FILE_ACTION_RENAMED_OLD_NAME:
            begin
              FPendingOldName := RelName;
              AddPendingOld(RelName);
            end;
          FILE_ACTION_RENAMED_NEW_NAME:
            begin
              if FPendingOldName <> '' then
                DispatchEvent(wekRenamed, RelName, FPendingOldName)
              else
              begin
                var OldRel: UnicodeString;
                if PopRecentOld(OldRel, RENAME_WINDOW_MS) then
                  DispatchEvent(wekRenamed, RelName, OldRel)
                else
                  DispatchEvent(wekRenamed, RelName, '');
              end;
            end;
        else
          if not ((PrevKind=wekAttrib) and (PrevName=RelName)) then
            DispatchEvent(wekAttrib, RelName, '');
        end;
        // 更新前一个记录（重命名 NEW_NAME 也更新）
        case Info^.Action of
          FILE_ACTION_ADDED: begin PrevKind:=wekCreated; PrevName:=RelName; end;
          FILE_ACTION_REMOVED: begin PrevKind:=wekDeleted; PrevName:=RelName; end;
          FILE_ACTION_MODIFIED: begin PrevKind:=wekModified; PrevName:=RelName; end;
          FILE_ACTION_RENAMED_NEW_NAME: begin PrevKind:=wekRenamed; PrevName:=RelName; end;
        else
          begin PrevKind:=wekAttrib; PrevName:=RelName; end;
        end;
        if Info^.NextEntryOffset = 0 then Break;
        Inc(Offset, Info^.NextEntryOffset);
      until False;
      CleanupStaleRenames(RENAME_WINDOW_MS);
    end;
  finally
    CloseHandle(Overl.hEvent);
  end;
end;

function TWatchThread.Stats(out Dropped, Delivered: QWord): Boolean;
begin
  Dropped := FDropped;
  Delivered := FDelivered;
  Result := True;
end;

{ TFsWatcherWin }
function TFsWatcherWin.Start(const Root: string; const Opts: TFsWatchOptions; const Obs: IFsWatchObserver): Integer;
var
  R: UnicodeString;
begin
  if Assigned(FThread) then
  begin
    Result := 0;
    Exit;
  end;
  R := UTF8Decode(Root);
  FThread := TWatchThread.Create(R, Obs, Opts);
  FThread.Start;
  FRunning := True;
  Result := 0;
end;

procedure TFsWatcherWin.Stop;
begin
  if Assigned(FThread) then
  begin
    FThread.RequestStop;
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
  FRunning := False;
end;

function TFsWatcherWin.IsRunning: Boolean;
begin
  Result := FRunning;
end;

function TFsWatcherWin.Stats(out Dropped: QWord; out Delivered: QWord): Boolean;
begin
  if Assigned(FThread) then
    Result := FThread.Stats(Dropped, Delivered)
  else
  begin
    Dropped := 0; Delivered := 0; Result := True;
  end;
end;

function TFsWatcherWin.AddPath(const SubRoot: string): Integer;
begin
  // 当前实现不支持动态添加子路径
  // 设计限制：每个 IFsWatcher 实例仅支持单根监控
  // 若需监控多个独立目录，请创建多个 IFsWatcher 实例
  if SubRoot = '' then ; // 避免编译器提示
  Result := FS_WATCH_ERROR_NOT_SUPPORTED;
end;

function TFsWatcherWin.RemovePath(const SubRoot: string): Integer;
begin
  // 当前实现不支持动态移除子路径
  // 设计限制：请使用 Stop 停止整个监控
  if SubRoot = '' then ; // 避免编译器提示
  Result := FS_WATCH_ERROR_NOT_SUPPORTED;
end;
{$ENDIF}


function CreateFsWatcher: IFsWatcher;
begin
  {$IFDEF WINDOWS}
  Result := TFsWatcherWin.Create;
  {$ELSE}
  Result := TFsWatcherStub.Create;
  {$ENDIF}
end;

{ TFsWatcherStub }

function TFsWatcherStub.Start(const Root: string; const Opts: TFsWatchOptions; const Obs: IFsWatchObserver): Integer;
begin
  // touch params to keep build hint-free on non-Windows
  if Root = '' then ;
  if Opts.MaxQueue < 0 then ;
  if Obs = nil then ;

  FRunning := False;
  Result := FS_WATCH_ERROR_NOT_SUPPORTED;
end;

procedure TFsWatcherStub.Stop;
begin
  FRunning := False;
end;

function TFsWatcherStub.IsRunning: Boolean;
begin
  Result := FRunning;
end;

function TFsWatcherStub.Stats(out Dropped: QWord; out Delivered: QWord): Boolean;
begin
  Dropped := FDropped;
  Delivered := FDelivered;
  Result := True;
end;

function TFsWatcherStub.AddPath(const SubRoot: string): Integer;
begin
  // 占位实现 - 功能不支持
  if SubRoot = '' then ;
  Result := FS_WATCH_ERROR_NOT_SUPPORTED;
end;

function TFsWatcherStub.RemovePath(const SubRoot: string): Integer;
begin
  // 占位实现 - 功能不支持
  if SubRoot = '' then ;
  Result := FS_WATCH_ERROR_NOT_SUPPORTED;
end;

end.

