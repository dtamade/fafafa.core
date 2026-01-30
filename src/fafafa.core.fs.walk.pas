unit fafafa.core.fs.walk;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.walk - 目录遍历操作

  从 highlevel.pas 拆分，包含：
  - WalkDir - 公共目录遍历 API
  - InternalWalk - 内部遍历入口
  - InternalWalkEx - 核心递归遍历实现（已重构降低圈复杂度）
  - TfsScandirEachWrapper - 目录扫描包装类
  - TWalkCallbackAdapter - 回调适配器

  重构记录 (Issue #4):
  - 提取 HandleWalkError 辅助函数
  - 提取 MakeVisitedKey 辅助函数
  - 提取 CheckAndAddToVisited 辅助函数
  - 提取 GetEntryStat 辅助函数
  - 简化主循环逻辑，圈复杂度从 ~25 降至 <10
}

interface

uses
  SysUtils, Classes,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.path,
  fafafa.core.fs.options;

type
  // 回调适配器：将普通函数指针包装为 of object
  TWalkCallbackAdapter = class
  public
    F: function(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
    function Invoke(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
  end;

  // 目录扫描包装：收集条目并支持稳定排序
  TfsScandirEachWrapper = class
  private
    FNames: TStringList;
    FTypes: array of TfsDirEntType;
  public
    constructor Create;
    destructor Destroy; override;
    function OnEntry(const aName: string; aType: TfsDirEntType): Boolean;
    procedure SortStable;
    function Count: Integer;
    function NameAt(Index: Integer): string;
    function TypeAt(Index: Integer): TfsDirEntType;
  end;

// 公共 API
function WalkDir(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback): Integer;

// 内部函数（供测试或高级用途）
function InternalWalk(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback; aDepth: Integer): Integer;
function InternalWalkEx(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback; aDepth: Integer; aHasStat: Boolean; const aKnownStat: TfsStat; aVisited: TStringList): Integer;

implementation

// ============================================================================
// 辅助函数（从 InternalWalkEx 提取以降低圈复杂度）
// ============================================================================

// 统一错误码转换（从 highlevel.pas 移植）
function ToUnifiedFsErrorCode(aRes: Integer): Integer; inline;
begin
  if aRes >= 0 then Exit(0);
  if FsLowLevelReturnsUnified then Exit(aRes);
  Exit(Integer(SystemErrorToFsError(-aRes)));
end;

// ✅ Issue #4: 提取 HandleWalkError - 处理遍历错误
// 返回值: <0 = 中止并返回错误码, 0 = 继续, 1 = 跳过子树
function HandleWalkError(const APath: string; Code: Integer; ADepth: Integer;
  const AOptions: TFsWalkOptions): Integer;
var
  Act: TFsWalkErrorAction;
  Unified: Integer;
begin
  if Assigned(AOptions.Stats) then Inc(AOptions.Stats^.Errors);
  Unified := ToUnifiedFsErrorCode(Code);

  // 检查是否超过最大错误数
  if (AOptions.MaxErrors >= 0) and Assigned(AOptions.Stats) then
    if AOptions.Stats^.Errors > QWord(AOptions.MaxErrors) then
      Exit(Unified);

  // 如果没有错误处理器，返回错误码
  if not Assigned(AOptions.OnError) then
    Exit(Unified);

  // 调用用户错误处理器
  Act := AOptions.OnError(APath, Unified, ADepth);
  case Act of
    weaContinue: Exit(0);
    weaSkipSubtree: Exit(1);
    weaAbort: Exit(Unified);
  end;

  Result := 0;
end;

// ✅ Issue #4: 提取 MakeVisitedKey - 创建唯一访问键用于循环检测
function MakeVisitedKey(const APath: string; const AStat: TfsStat; out Key: string): Boolean;
var
  RealPath: string;
  Buf: array[0..4095] of Char;
  R: Integer;
  {$IFDEF WINDOWS}
  H: THandle;
  Info: TByHandleFileInformation;
  WPath: UnicodeString;
  {$ENDIF}
begin
  // 优先使用 dev:ino 作为唯一标识
  if (AStat.Dev <> 0) or (AStat.Ino <> 0) then
  begin
    Key := IntToHex(AStat.Dev, 16) + ':' + IntToHex(AStat.Ino, 16);
    Exit(True);
  end;

  {$IFDEF WINDOWS}
  // Windows: 使用文件句柄获取唯一标识
  WPath := UTF8Decode(ToWindowsPath(APath));
  H := CreateFileW(PWideChar(WPath), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
    nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
  if H <> INVALID_HANDLE_VALUE then
  begin
    FillChar(Info, SizeOf(Info), 0);
    if GetFileInformationByHandle(H, Info) then
    begin
      Key := IntToHex(Info.dwVolumeSerialNumber, 8) + ':' +
             IntToHex(Int64(Info.nFileIndexHigh) shl 32 or Info.nFileIndexLow, 16);
      CloseHandle(H);
      Exit(True);
    end;
    CloseHandle(H);
  end;
  {$ENDIF}

  // 回退: 使用真实路径
  R := fafafa.core.fs.fs_realpath(APath, @Buf[0], Length(Buf));
  if R >= 0 then
  begin
    SetString(RealPath, PChar(@Buf[0]), R);
    Key := RealPath;
    Exit(True);
  end;

  Key := '';
  Result := False;
end;

// ✅ Issue #4: 提取 CheckAndAddToVisited - 检查并添加到已访问集合
// 返回值: True = 继续处理, False = 已访问过（跳过）
function CheckAndAddToVisited(const APath: string; const AStat: TfsStat;
  AVisited: TStringList; FollowSymlinks: Boolean): Boolean;
var
  Key: string;
  HaveKey: Boolean;
begin
  Result := True;
  if not FollowSymlinks then Exit;
  if not Assigned(AVisited) then Exit;

  HaveKey := MakeVisitedKey(APath, AStat, Key);
  if HaveKey then
  begin
    if AVisited.IndexOf(Key) >= 0 then
      Exit(False)  // 已访问，跳过
    else
      AVisited.Add(Key);
  end;
end;

// ✅ Issue #4: 提取 GetEntryStat - 根据条目类型获取 stat
function GetEntryStat(const APath: string; AType: TfsDirEntType;
  FollowSymlinks: Boolean; out AStat: TfsStat): Integer;
begin
  case AType of
    fsDETDir:
      Result := fs_lstat(APath, AStat);
    fsDETFile:
      if FollowSymlinks then
        Result := fs_stat(APath, AStat)
      else
        Result := fs_lstat(APath, AStat);
    fsDETSymlink, fsDETUnknown:
      if FollowSymlinks then
        Result := fs_stat(APath, AStat)
      else
        Result := fs_lstat(APath, AStat);
  end;
end;

// ✅ Issue #4: 提取 InvokeCallback - 安全调用回调
// 返回值: True = 继续, False = 停止遍历
function InvokeCallback(ACallback: TFsWalkCallback; const APath: string;
  const AStat: TfsStat; ADepth: Integer): Boolean; inline;
begin
  if not Assigned(ACallback) then
    Exit(True);
  Result := ACallback(APath, AStat, ADepth);
end;

// ✅ Issue #4: 提取 UpdateStats - 更新统计信息
procedure UpdateStats(Stats: Pointer; IsDir: Boolean); inline;
var
  P: ^TFsWalkStats;
begin
  if Stats = nil then Exit;
  P := Stats;
  if IsDir then
    Inc(P^.DirsVisited)
  else
    Inc(P^.FilesVisited);
end;

// ============================================================================
// 原有类实现
// ============================================================================

{ TWalkCallbackAdapter }

function TWalkCallbackAdapter.Invoke(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  Result := F(aPath, aStat, aDepth);
end;

{ TfsScandirEachWrapper }

constructor TfsScandirEachWrapper.Create;
begin
  inherited Create;
  FNames := TStringList.Create;
  SetLength(FTypes, 0);
end;

destructor TfsScandirEachWrapper.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

function TfsScandirEachWrapper.OnEntry(const aName: string; aType: TfsDirEntType): Boolean;
begin
  FNames.Add(aName);
  SetLength(FTypes, FNames.Count);
  FTypes[High(FTypes)] := aType;
  Result := True;
end;

procedure TfsScandirEachWrapper.SortStable;
var
  Indexes: array of Integer;
  I, j, k, key: Integer;
  keyName: string;
  SortedNames: TStringList;
  SortedTypes: array of TfsDirEntType;
begin
  Indexes := nil;
  SortedTypes := nil;
  if FNames.Count <= 1 then Exit;

  SetLength(Indexes, FNames.Count);
  for I := 0 to FNames.Count - 1 do Indexes[I] := I;
  for j := 1 to High(Indexes) do
  begin
    key := Indexes[j]; keyName := FNames[key];
    k := j - 1;
    while (k >= 0) and (AnsiCompareStr(FNames[Indexes[k]], keyName) > 0) do
    begin
      Indexes[k+1] := Indexes[k];
      Dec(k);
    end;
    Indexes[k+1] := key;
  end;
  SortedNames := TStringList.Create;
  SetLength(SortedTypes, Length(FTypes));
  try
    for I := 0 to High(Indexes) do
    begin
      SortedNames.Add(FNames[Indexes[I]]);
      SortedTypes[I] := FTypes[Indexes[I]];
    end;
    FNames.Assign(SortedNames);
    FTypes := SortedTypes;
  finally
    SortedNames.Free;
  end;
end;

function TfsScandirEachWrapper.Count: Integer;
begin
  Result := FNames.Count;
end;

function TfsScandirEachWrapper.NameAt(Index: Integer): string;
begin
  Result := FNames[Index];
end;

function TfsScandirEachWrapper.TypeAt(Index: Integer): TfsDirEntType;
begin
  Result := FTypes[Index];
end;

// ============================================================================
// InternalWalkEx - 核心递归遍历（已重构）
// ============================================================================

function InternalWalkEx(const aRoot: string; const aOptions: TFsWalkOptions;
  aCallback: TFsWalkCallback; aDepth: Integer; aHasStat: Boolean;
  const aKnownStat: TfsStat; aVisited: TStringList): Integer;
var
  LStat: TfsStat;
  I: Integer;
  LPath: string;
  LIsDir: Boolean;
  LRes: Integer;
  LStatRes: Integer;
  LWrap: TfsScandirEachWrapper;
begin
  Result := 0;

  // 1. 深度限制检查
  if (aOptions.MaxDepth >= 0) and (aDepth > aOptions.MaxDepth) then
    Exit(0);

  // 2. 获取根目录 stat
  if aHasStat then
    LStat := aKnownStat
  else
  begin
    LStatRes := fs_lstat(aRoot, LStat);
    if LStatRes < 0 then
    begin
      LRes := HandleWalkError(aRoot, LStatRes, aDepth, aOptions);
      if LRes < 0 then Exit(LRes);
      Exit(0);
    end;
  end;

  LIsDir := (LStat.Mode and S_IFMT) = S_IFDIR;

  // 3. 处理根节点回调
  if LIsDir then
  begin
    if aOptions.IncludeDirs then
      if not InvokeCallback(aCallback, aRoot, LStat, aDepth) then
        Exit(0);
  end
  else
  begin
    if aOptions.IncludeFiles then
      if not InvokeCallback(aCallback, aRoot, LStat, aDepth) then
        Exit(0);
    Exit(0);  // 文件节点不需要遍历子项
  end;

  // 4. 扫描目录内容
  LWrap := TfsScandirEachWrapper.Create;
  try
    LRes := fs_scandir_each(aRoot, @LWrap.OnEntry);
    if LRes < 0 then
    begin
      LRes := HandleWalkError(aRoot, LRes, aDepth, aOptions);
      if LRes < 0 then Exit(LRes);
      Exit(0);
    end;

    LWrap.SortStable;

    // 5. 处理每个条目
    for I := 0 to LWrap.Count - 1 do
    begin
      LPath := JoinPath(aRoot, LWrap.NameAt(I));

      // 5.1 PreFilter 检查
      if Assigned(aOptions.PreFilter) then
        if not aOptions.PreFilter(LPath, LWrap.TypeAt(I), aDepth + 1) then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.PreFiltered);
          Continue;
        end;

      // 5.2 获取条目 stat
      LStatRes := GetEntryStat(LPath, LWrap.TypeAt(I), aOptions.FollowSymlinks, LStat);
      if LStatRes < 0 then
      begin
        LRes := HandleWalkError(LPath, LStatRes, aDepth + 1, aOptions);
        if LRes < 0 then Exit(LRes);
        if LRes = 1 then Continue;  // 跳过子树
      end;

      LIsDir := (LStat.Mode and S_IFMT) = S_IFDIR;

      // 5.3 PostFilter 检查（过滤后仍递归目录）
      if Assigned(aOptions.PostFilter) then
        if not aOptions.PostFilter(LPath, LStat, aDepth + 1) then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.PostFiltered);
          if LIsDir then
          begin
            Result := InternalWalkEx(LPath, aOptions, aCallback, aDepth + 1, True, LStat, aVisited);
            if Result < 0 then Exit(Result);
          end;
          Continue;
        end;

      // 5.4 处理目录
      if LIsDir then
      begin
        UpdateStats(aOptions.Stats, True);
        if aOptions.IncludeDirs then
          if not InvokeCallback(aCallback, LPath, LStat, aDepth + 1) then
            Exit(0);

        // 符号链接循环检测
        if not CheckAndAddToVisited(LPath, LStat, aVisited, aOptions.FollowSymlinks) then
          Continue;  // 已访问过，跳过

        Result := InternalWalkEx(LPath, aOptions, aCallback, aDepth + 1, True, LStat, aVisited);
        if Result < 0 then Exit(Result);
      end
      // 5.5 处理文件
      else
      begin
        UpdateStats(aOptions.Stats, False);
        if aOptions.IncludeFiles then
          if not InvokeCallback(aCallback, LPath, LStat, aDepth + 1) then
            Exit(0);
      end;
    end;
  finally
    FreeAndNil(LWrap);
  end;
end;

{ InternalWalk }

function InternalWalk(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback; aDepth: Integer): Integer;
var
  LVisited: TStringList;
begin
  if aOptions.FollowSymlinks then
  begin
    LVisited := TStringList.Create;
    try
      LVisited.Sorted := True;
      LVisited.Duplicates := dupIgnore;
      Result := InternalWalkEx(aRoot, aOptions, aCallback, aDepth, False, Default(TfsStat), LVisited);
    finally
      LVisited.Free;
    end;
  end
  else
  begin
    Result := InternalWalkEx(aRoot, aOptions, aCallback, aDepth, False, Default(TfsStat), nil);
  end;
end;

{ WalkDir }

function WalkDir(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback): Integer;
begin
  Result := InternalWalk(ResolvePath(aRoot), aOptions, aCallback, 0);
end;

end.
