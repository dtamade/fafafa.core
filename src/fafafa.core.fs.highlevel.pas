unit fafafa.core.fs.highlevel;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DateUtils,
  {$IFDEF WINDOWS}Windows,{$ENDIF}

  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.path;

type
  // 文件打开模式
  TFsOpenMode = (
    fomRead,           // 只读
    fomWrite,          // 只写（截断）
    fomReadWrite,      // 读写
    fomAppend,         // 追加
    fomCreate,         // 创建新文件
    fomCreateExclusive // 创建新文件（如果存在则失败）
  );

  // 文件共享模式
  TFsShareMode = set of (
    fsmRead,   // 允许其他进程读取
    fsmWrite,  // 允许其他进程写入
    fsmDelete  // 允许其他进程删除
  );
  // 高层打开选项（不破坏 IFsFile 接口，提供辅助入口）
  TFsOpenOptions = record
    Read: Boolean;
    Write: Boolean;
    Append: Boolean;
    Create: Boolean;
    CreateNew: Boolean;
    Truncate: Boolean;
    Share: TFsShareMode;
  end;

  // Walk 错误处理策略
  // - weaContinue: 继续遍历（忽略该错误）；根路径无效时返回 0（等价于空遍历）
  // - weaSkipSubtree: 跳过当前子树，继续处理同层其他条目
  // - weaAbort: 立即中止并返回统一负错误码
  TFsWalkErrorAction = (weaContinue, weaSkipSubtree, weaAbort);
  // OnError 回调：aPath 为出错项路径，aError 为统一错误码（负数），aDepth 为当前深度
  // 返回上述策略之一以驱动遍历行为；当回调为 nil 时，保持旧行为（返回负统一错误码）
  TFsWalkOnError = function(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction of object;

  // OpenOptions 辅助函数声明
  // OpenOptions 便利构造函数（只读/覆盖写/读写）
  function FsOpenOptions_ReadOnly: TFsOpenOptions; inline;
  function FsOpenOptions_WriteTruncate: TFsOpenOptions; inline;
  function FsOpenOptions_ReadWrite: TFsOpenOptions; inline;
  function FsOpenOptions_WithShare(const Opt: TFsOpenOptions; AShare: TFsShareMode): TFsOpenOptions; inline;
  function FsOpenOptions_ToFlags(const Opt: TFsOpenOptions): Integer; inline;


  // 面向接口抽象（便于依赖注入/替换实现）
  type

  IFsFile = interface
    ['{6B7925C9-4E32-4E4D-9B3A-0D1E3D3B8A71}']
    // 生命周期
    procedure Open(const APath: string; AMode: TFsOpenMode);
    procedure Close;
    function  IsOpen: Boolean;
    // 位置与大小
    function  Seek(ADistance: Int64; AWhence: Integer): Int64; // SEEK_SET/CUR/END
    function  Tell: Int64;
    function  Size: Int64;
    procedure Truncate(ANewSize: Int64);
    // 同步
    procedure Flush;
    // 读写（阻塞）
    function  Read(var ABuffer; ACount: Integer): Integer;
    function  Write(const ABuffer; ACount: Integer): Integer;
    // 可选：定位读写（默认基于 Seek+Read/Write 实现）
    function  PRead(var ABuffer; ACount: Integer; AOffset: Int64): Integer;
    function  PWrite(const ABuffer; ACount: Integer; AOffset: Int64): Integer;
  end;

  function NewFsFile: IFsFile;
  // OpenFileEx: 以选项打开文件并返回 IFsFile；若打开失败，将抛出异常
  function OpenFileEx(const APath: string; const Opts: TFsOpenOptions): IFsFile;

  // 高级文件操作类
  type
    TFsFile = class(TInterfacedObject, IFsFile)
  private
    FHandle: fafafa.core.fs.TfsFile;
    FPath: string;
    FIsOpen: Boolean;
    function GetSize: Int64;
    function GetPosition: Int64;
    procedure SetPosition(const aValue: Int64);
  public
    constructor Create;
    destructor Destroy; override;

    // 文件操作
    procedure Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode);
    procedure Open(const APath: string; AMode: TFsOpenMode); overload; // IFsFile 兼容重载
    procedure Close;
    function Read(var aBuffer; aCount: Integer): Integer;
    function Write(const aBuffer; aCount: Integer): Integer;
    procedure Flush;
    procedure Truncate(aSize: Int64);


    // IFsFile 适配方法
    // OpenOptions 辅助：从选项打开（不影响 IFsFile 接口）
    procedure OpenEx(const APath: string; const Opts: TFsOpenOptions);

    function IsOpen: Boolean; // 覆盖接口方法（与属性同名，返回 FIsOpen）
    function Seek(ADistance: Int64; AWhence: Integer): Int64;
    function Tell: Int64;
    function Size: Int64;
    function PRead(var ABuffer; ACount: Integer; AOffset: Int64): Integer;
    function PWrite(const ABuffer; ACount: Integer; AOffset: Int64): Integer;

    // 便利方法
    function ReadString(aEncoding: TEncoding = nil): string;
    procedure WriteString(const aText: string; aEncoding: TEncoding = nil);
    function ReadBytes: TBytes;
    procedure WriteBytes(const aBytes: TBytes);

    // 属性
    property Handle: fafafa.core.fs.TfsFile read FHandle;
    property Path: string read FPath;
    property IsOpenProp: Boolean read FIsOpen; // 避免与方法同名冲突
    property SizeProp: Int64 read GetSize;     // 避免与方法同名冲突
    property Position: Int64 read GetPosition write SetPosition;
  end;

// 便利函数
type


  // 无异常模式包装：将 EFsError 捕获为负错误码返回
  TFsFileNoExcept = object
    FileIntf: IFsFile;
    function Open(const APath: string; AMode: TFsOpenMode): Integer;
    function Close: Integer;
    function Read(var ABuffer; ACount: Integer; out N: Integer): Integer;
    function Write(const ABuffer; ACount: Integer; out N: Integer): Integer;
    function Seek(ADistance: Int64; AWhence: Integer; out NewPos: Int64): Integer;
    function Tell(out Pos: Int64): Integer;
    function Size(out ASize: Int64): Integer;
    function Truncate(ANewSize: Int64): Integer;
    function Flush: Integer;
    function PRead(var ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
    function PWrite(const ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
  end;

  function NewFsFileNoExcept: TFsFileNoExcept;

function ReadTextFile(const aPath: string; aEncoding: TEncoding = nil): string;
procedure WriteTextFile(const aPath, aText: string; aEncoding: TEncoding = nil);
function ReadBinaryFile(const aPath: string): TBytes;
procedure WriteBinaryFile(const aPath: string; const aData: TBytes);
// 高层门面：一次性写入并原子替换
// WriteFileAtomic(Path, Data):
// - 写入临时文件（同目录），成功后 fs_replace 原子覆盖目标
// - 失败会尽量清理临时；返回异常或统一错误码（结合现有 CheckFsResult）
procedure WriteFileAtomic(const aPath: string; const aData: TBytes);
procedure WriteTextFileAtomic(const aPath, aText: string; aEncoding: TEncoding = nil);


  // 复制/移动选项
  type
    TFsCopyOptions = record
      Overwrite: Boolean;
      PreserveTimes: Boolean;
      PreservePerms: Boolean;
    end;

    TFsMoveOptions = record
      Overwrite: Boolean;
      PreserveTimes: Boolean;
      PreservePerms: Boolean;
    end;

  // 高层门面：复制/移动（异常语义）
  procedure FsCopyFileEx(const aSrc, aDst: string; const aOpts: TFsCopyOptions);
  procedure FsMoveFileEx(const aSrc, aDst: string; const aOpts: TFsMoveOptions);

function FileExists(const aPath: string): Boolean;
function DirectoryExists(const aPath: string): Boolean;
procedure CreateDirectory(const aPath: string; aRecursive: Boolean = False);
  // 目录树复制/移动选项（继承文件级含义，新增 FollowSymlinks）
  type
    // 根目录处理策略
    TFsRootBehavior = (rbMerge, rbReplace, rbError);
    // 错误处理策略
    TFsErrorPolicy = (epAbort, epContinue, epSkipSubtree);

    TFsCopyTreeOptions = record
      Overwrite: Boolean;
      PreserveTimes: Boolean;
      PreservePerms: Boolean;
      FollowSymlinks: Boolean;
      // 新增：根策略/错误策略/链接复制为链接本体
      RootBehavior: TFsRootBehavior;    // 默认 rbMerge（与旧行为一致）
      ErrorPolicy: TFsErrorPolicy;      // 默认 epAbort
      CopySymlinksAsLinks: Boolean;     // 当 FollowSymlinks=False 时，复制链接本体
    end;

    TFsMoveTreeOptions = record
      Overwrite: Boolean;
      PreserveTimes: Boolean;
      PreservePerms: Boolean;
      FollowSymlinks: Boolean;
      RootBehavior: TFsRootBehavior;    // 默认 rbMerge（与旧行为一致）
      ErrorPolicy: TFsErrorPolicy;      // 默认 epAbort
      CopySymlinksAsLinks: Boolean;     // 当 FollowSymlinks=False 时，复制链接本体
    end;


  // 便利构造器：标准推荐默认
  function FsDefaultCopyOptions: TFsCopyOptions; inline;
  function FsDefaultMoveOptions: TFsMoveOptions; inline;
  function FsDefaultCopyTreeOptions: TFsCopyTreeOptions; inline;
  function FsDefaultMoveTreeOptions: TFsMoveTreeOptions; inline;

  type
    // 目录树操作结果统计（可选 out 参数返回）
    TFsTreeResult = record
      FilesCopied: QWord;
      DirsCreated: QWord;
      BytesCopied: QWord;
      Errors: QWord; // 预留：未来可扩展为详细错误列表
    end;

  // 高层门面：目录树复制/移动（异常语义）
  procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions); overload;
  procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions; out aResult: TFsTreeResult); overload;
  procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions); overload;
  procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions; out aResult: TFsTreeResult); overload;

  // ===== RemoveTree（递归删除）选项与接口 =====
  type
    TFsRemoveTreeOptions = record
      FollowSymlinks: Boolean;    // 是否跟随符号链接（默认 False：删除链接本体，不触及目标）
      ErrorPolicy: TFsErrorPolicy; // epAbort/epContinue/epSkipSubtree
    end;
    TFsRemoveTreeResult = record
      FilesRemoved: QWord;
      DirsRemoved: QWord;
      Errors: QWord;
    end;

  function FsDefaultRemoveTreeOptions: TFsRemoveTreeOptions; inline;
  procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions); overload;
  procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions; out aResult: TFsRemoveTreeResult); overload;


procedure DeleteFile(const aPath: string);
procedure DeleteDirectory(const aPath: string; aRecursive: Boolean = False);
  // Walk 统计结构（可选）
  type
    TFsWalkStats = record
      DirsVisited: QWord;
      FilesVisited: QWord;
      PreFiltered: QWord;
      PostFiltered: QWord;
      Errors: QWord;
    end;

function GetFileSize(const aPath: string): Int64;
function GetFileModificationTime(const aPath: string): TDateTime;

  // WalkDir 选项
  type


  // Walk 过滤器类型：
    // PreFilter：基于路径与基础类型（由 scandir_each 提供）进行快速排除，避免不必要的 stat；返回 False 则跳过该条目及其子树
    TFsWalkPreFilter = function(const aPath: string; aBasicType: TfsDirEntType; aDepth: Integer): Boolean of object;
    // PostFilter：已获得完整 stat 后决定是否触发回调；不影响对子目录的递归（如需阻止递归请使用 PreFilter）
    TFsWalkPostFilter = function(const aPath: string; const aStat: fafafa.core.fs.TfsStat; aDepth: Integer): Boolean of object;

    TFsWalkOptions = record
      FollowSymlinks: Boolean; // 是否跟随符号链接
      IncludeFiles: Boolean;   // 是否包含文件
      IncludeDirs: Boolean;    // 是否包含目录
      MaxDepth: Integer;       // 最大深度（包含根），<0 表示无限
      PreFilter: TFsWalkPreFilter;  // 前置过滤（基于基础类型），可为 nil
      PostFilter: TFsWalkPostFilter; // 后置过滤（基于 stat），可为 nil



      OnError: TFsWalkOnError;      // 错误策略回调；nil 表示沿用旧行为（根无效返回负码）
      Stats: ^TFsWalkStats;          // 可选统计指针（nil 表示禁用统计）
      // 扩展：流式与排序控制（默认 False，保持兼容）
      UseStreaming: Boolean;
      Sort: Boolean;
      MaxErrors: Integer; // -1 表示无限；>=0 达到阈值后 Abort
    end;

    // WalkDir 回调：返回 True 继续，False 早停（对象方法）
    TFsWalkCallback = function(const aPath: string; const aStat: fafafa.core.fs.TfsStat; aDepth: Integer): Boolean of object;

  function FsDefaultWalkOptions: TFsWalkOptions;
  function WalkDir(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback): Integer;

implementation

uses
  fafafa.core.fs.copyaccel;

function FsDefaultCopyOptions: TFsCopyOptions;
begin
  Result.Overwrite := True;
  {$IFDEF UNIX}
  Result.PreserveTimes := True;
  Result.PreservePerms := True;
  {$ELSE}
  Result.PreserveTimes := True;  // Windows: best-effort via SetFileTime
  Result.PreservePerms := False; // Windows: 忽略 perms（无效）
  {$ENDIF}
end;

function FsDefaultMoveOptions: TFsMoveOptions;
begin
  // 与 Copy 保持一致
  Result.Overwrite := True;
  {$IFDEF UNIX}
  Result.PreserveTimes := True;
  Result.PreservePerms := True;
  {$ELSE}
  Result.PreserveTimes := True;
  Result.PreservePerms := False;
  {$ENDIF}
end;

function FsDefaultCopyTreeOptions: TFsCopyTreeOptions;
begin
  Result.Overwrite := True;
  {$IFDEF UNIX}
  Result.PreserveTimes := True;
  Result.PreservePerms := True;
  {$ELSE}
  Result.PreserveTimes := True;
  Result.PreservePerms := False;
  {$ENDIF}
  Result.FollowSymlinks := False;
  Result.RootBehavior := rbMerge;
  Result.ErrorPolicy := epAbort;
  Result.CopySymlinksAsLinks := False;
end;

function FsDefaultMoveTreeOptions: TFsMoveTreeOptions;
begin
  Result.Overwrite := True;
  {$IFDEF UNIX}
  Result.PreserveTimes := True;
  Result.PreservePerms := True;
  {$ELSE}
  Result.PreserveTimes := True;
  Result.PreservePerms := False;
  {$ENDIF}
  Result.FollowSymlinks := False;
  Result.RootBehavior := rbMerge;
  Result.ErrorPolicy := epAbort;
  Result.CopySymlinksAsLinks := False;
end;

type
  TWalkCallbackAdapter = class
  public
    F: function(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean; // plain function pointer
    function Invoke(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean; // of object
  end;

function TWalkCallbackAdapter.Invoke(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  Result := F(aPath, aStat, aDepth);
end;



// Walker: 用于目录树复制时携带状态并提供 of object 回调
// ===== RemoveTree walker type (global, avoid nested class restriction) =====
type
  TRemoveWalker = class
  public
    Opts: TFsRemoveTreeOptions;
    FilesRemoved: QWord;
    DirsRemoved: QWord;
    Errors: QWord;
    Dirs: TStringList;
    ExternalTargets: TStringList; // 收集目录型符号链接的最终目标（绝对规范路径）
    function OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean; // of object
    function OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
  end;

type
  TCopyTreeWalker = class
  public
    SrcRoot, DstRoot: string;
    Overwrite, PreserveTimes, PreservePerms: Boolean;
    FollowSymlinks, CopySymlinksAsLinks: Boolean;
    ErrorPolicy: TFsErrorPolicy;
    // 统计
    FilesCopied, DirsCreated: QWord;
    BytesCopied: QWord;
    Errors: QWord;
    // 性能：已创建目录缓存，避免重复触盘
    CreatedDirs: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure EnsureParentDirExists(const APath: string);
    function OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
    function OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
  end;
function TCopyTreeWalker.OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  // Policy handler currently ignores extra context, but keep signature stable.
  if aPath = '' then ;
  if aError = 0 then ;
  if aDepth < 0 then ;

  Inc(Errors);
  Result := weaAbort;
  case ErrorPolicy of
    epAbort: Result := weaAbort;
    epSkipSubtree: Result := weaSkipSubtree;
    epContinue: Result := weaContinue;
  end;
end;

constructor TCopyTreeWalker.Create;
begin
  inherited Create;
  CreatedDirs := TStringList.Create;
  CreatedDirs.Sorted := True;
  CreatedDirs.Duplicates := dupIgnore;
end;

destructor TCopyTreeWalker.Destroy;
begin
  CreatedDirs.Free;
  inherited Destroy;
end;

procedure TCopyTreeWalker.EnsureParentDirExists(const APath: string);
var
  P: string;
begin
  P := ExtractFilePath(APath);
  if (P = '') then Exit;
  if (CreatedDirs.IndexOf(P) >= 0) then Exit;
  if not DirectoryExists(P) then
    CreateDirectory(P, True);
  CreatedDirs.Add(P);
end;

function TCopyTreeWalker.OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
var
  Rel, OutPath: string;
  CopyOpts: TFsCopyOptions;
  Target: string;
  R: Integer;
begin
  if aDepth < 0 then ;

  // 继续 TCopyTreeWalker.OnEach
  Rel := ToRelativePath(aPath, SrcRoot);
  if Rel = '' then Rel := '.';
  OutPath := JoinPath(DstRoot, Rel);

  // 符号链接处理
  if (aStat.Mode and S_IFMT) = S_IFLNK then
  begin
    if CopySymlinksAsLinks and (not FollowSymlinks) then
    begin
      // FreePascal <=3.3 不支持方法内 var 声明，提前声明在最上方，这里仅赋值
      // 使用便捷API读取符号链接目标
      R := fs_readlink_s(aPath, Target);
      if R < 0 then
      begin
        Inc(Errors);
        case ErrorPolicy of
          epAbort: raise EFsError.Create(TFsErrorCode(R), 'readlink failed: ' + aPath, -R);
          epSkipSubtree, epContinue: Exit(True);
        end;
      end


  // 错误：误插入的 RemoveTreeEx 实现片段，已在 720+ 处正确实现，这里移除以恢复 TCopyTreeWalker.OnEach 的结构。

      else
      begin
        EnsureParentDirExists(OutPath);
        R := fs_symlink(Target, OutPath);
        if R < 0 then
        begin
          Inc(Errors);
          case ErrorPolicy of
            epAbort: raise EFsError.Create(TFsErrorCode(R), 'symlink create failed: ' + OutPath, -R);
            epSkipSubtree, epContinue: ;
          end;
        end;
      end;
    end;
    Exit(True);
  end;




  if (aStat.Mode and S_IFMT) = S_IFDIR then
  begin
    if not DirectoryExists(OutPath) then
      CreateDirectory(OutPath, True);
    Inc(DirsCreated);
    Exit(True);
  end
  else
  begin
    EnsureParentDirExists(OutPath);
    // 目录确保存在
    CopyOpts.Overwrite := Overwrite;
    CopyOpts.PreserveTimes := PreserveTimes;
    CopyOpts.PreservePerms := PreservePerms;
    try
      FsCopyFileEx(aPath, OutPath, CopyOpts);
      // 统计（仅在成功时计数）
      Inc(FilesCopied);
      try
        Inc(BytesCopied, aStat.Size);
      except
        // 防溢出或无效值时忽略
      end;
    except
      on E: EFsError do
      begin
        Inc(Errors);
        case ErrorPolicy of
          epAbort: raise;
          epSkipSubtree, epContinue: ; // 吞掉错误，继续遍历
        end;
      end;
    end;
    end;
    Exit(True);
  end; // OnEach

// 回调式枚举的收集与稳定排序包装（避免 nested proc 与 of object 类型不兼容）

type
  TfsScandirEachWrapper = class
  private
    FNames: TStringList;
    FTypes: array of TfsDirEntType;
  public
    constructor Create;
    destructor Destroy; override;
    function OnEntry(const aName: string; aType: TfsDirEntType): Boolean; // TfsScandirEachProc
    procedure SortStable;
    function Count: Integer;
    function NameAt(Index: Integer): string;
    function TypeAt(Index: Integer): TfsDirEntType;
  end;

function FsOpenOptions_ToFlags(const Opt: TFsOpenOptions): Integer;
begin
  Result := 0;
  if Opt.Read and Opt.Write then Result := Result or O_RDWR
  else if Opt.Write then Result := Result or O_WRONLY
  else if Opt.Read then Result := Result or O_RDONLY;
  if Opt.Append then Result := Result or O_APPEND;
  if Opt.CreateNew then Result := Result or (O_CREAT or O_EXCL)
  else if Opt.Create then Result := Result or O_CREAT;
  if Opt.Truncate then Result := Result or O_TRUNC;
end;



function FsOpenOptions_ReadOnly: TFsOpenOptions;
begin
  Result := Default(TFsOpenOptions);
  Result.Read := True; Result.Share := [fsmRead];
end;

function FsOpenOptions_WriteTruncate: TFsOpenOptions;
begin
  Result := Default(TFsOpenOptions);
  Result.Write := True; Result.Create := True; Result.Truncate := True; Result.Share := [fsmRead];
end;

function FsOpenOptions_ReadWrite: TFsOpenOptions;
begin
  Result := Default(TFsOpenOptions);
  Result.Read := True; Result.Write := True; Result.Create := True; Result.Share := [fsmRead, fsmWrite];
end;

function FsOpenOptions_WithShare(const Opt: TFsOpenOptions; AShare: TFsShareMode): TFsOpenOptions;
begin
  Result := Opt; Result.Share := AShare;
end;


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

  // 初始化受管局部，压低编译器保守提示（不改行为）
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




// 统一错误码转换（迁移期守护）
function ToUnifiedFsErrorCode(aRes: Integer): Integer; inline;
begin
  if aRes >= 0 then Exit(0);
  if FsLowLevelReturnsUnified then Exit(aRes);
  Exit(Integer(SystemErrorToFsError(-aRes)));
end;


{ TFsFile }

constructor TFsFile.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FIsOpen := False;
end;

destructor TFsFile.Destroy;
begin
  try



    if FIsOpen then
      Close;
  except
    // 析构函数中忽略异常，避免程序崩溃
    // 但确保资源被清理
    if FHandle <> INVALID_HANDLE_VALUE then
    begin
      fs_close(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
    end;
    FIsOpen := False;
  end;
  inherited Destroy;
end;

procedure TFsFile.Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode);
var
  LFlags: Integer;
  LResult: Integer;
  LErrorCode: TFsErrorCode;
begin
  if FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is already open', 0);

  // 验证路径安全性
  if not ValidatePath(aPath) then
    raise EFsError.Create(FS_ERROR_INVALID_PATH, 'Invalid or unsafe path: ' + aPath, 0);

  // 转换打开模式
  case aMode of
    fomRead: LFlags := O_RDONLY;
    fomWrite: LFlags := O_WRONLY or O_CREAT or O_TRUNC;
    fomReadWrite: LFlags := O_RDWR or O_CREAT;
    fomAppend: LFlags := O_WRONLY or O_CREAT or O_APPEND;
    fomCreate: LFlags := O_RDWR or O_CREAT or O_TRUNC;
    fomCreateExclusive: LFlags := O_RDWR or O_CREAT or O_EXCL;
  end;

  // 共享标志映射（默认保持完全共享以与旧行为一致）
  if fsmRead   in aShare then LFlags := LFlags or O_SHARE_READ;
  if fsmWrite  in aShare then LFlags := LFlags or O_SHARE_WRITE;
  if fsmDelete in aShare then LFlags := LFlags or O_SHARE_DELETE;
  if aShare = [] then
  begin
    // 兼容：如果调用方传空集合，使用旧行为（全共享）
    LFlags := LFlags or O_SHARE_READ or O_SHARE_WRITE or O_SHARE_DELETE;
  end;

  FHandle := fs_open(aPath, LFlags, S_IRWXU);
  if not IsValidHandle(FHandle) then
  begin
    // 立即获取错误代码，避免被其他调用覆盖
    LErrorCode := GetLastFsError();
    LResult := Integer(LErrorCode);
    raise EFsError.Create(LErrorCode,
      Format('Failed to open file "%s"', [aPath]), -LResult);
  end
  else
  begin
    FPath := aPath;
    FIsOpen := True;
  end;
end;

procedure TFsFile.Open(const APath: string; AMode: TFsOpenMode);
// 标记未使用的 aShare 在重载版本中保留接口，当前重载默认使用 [fsmRead]

begin
  Open(APath, AMode, [fsmRead]);
end;

function TFsFile.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

function TFsFile.Seek(ADistance: Int64; AWhence: Integer): Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  Result := fs_seek(FHandle, ADistance, AWhence);
  if Result < 0 then
    CheckFsResult(Integer(Result), 'seek');
end;

procedure TFsFile.OpenEx(const APath: string; const Opts: TFsOpenOptions);
var
  Flags: Integer;
  Share: TFsShareMode;
begin
  Share := Opts.Share;
  Flags := FsOpenOptions_ToFlags(Opts);
  if fsmRead   in Share then Flags := Flags or O_SHARE_READ;
  if fsmWrite  in Share then Flags := Flags or O_SHARE_WRITE;
  if fsmDelete in Share then Flags := Flags or O_SHARE_DELETE;
  if Share = [] then
    Flags := Flags or O_SHARE_READ or O_SHARE_WRITE or O_SHARE_DELETE;
  if FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is already open', 0);
  if not ValidatePath(APath) then
    raise EFsError.Create(FS_ERROR_INVALID_PATH, 'Invalid or unsafe path: ' + APath, 0);
  FHandle := fs_open(APath, Flags, S_IRWXU);
  if not IsValidHandle(FHandle) then
    CheckFsResult(Integer(GetLastFsError), 'open file via options')
  else
  begin
    FPath := APath;
    FIsOpen := True;
  end;
end;

function OpenFileEx(const APath: string; const Opts: TFsOpenOptions): IFsFile;
var
  V: TFsFile;
begin
  // 工厂方法：确保打开失败时释放实例，避免资源泄漏
  V := TFsFile.Create;
  try
    V.OpenEx(APath, Opts);
    Result := V;
  except
    V.Free;
    raise;
  end;
end;

function NewFsFile: IFsFile;
begin
  Result := TFsFile.Create;
end;


// 便利别名：与 FsOpenOptions_* 同义，便于快速书写
function FsOptsReadOnly: TFsOpenOptions; inline;
begin
  Result := FsOpenOptions_ReadOnly;
end;

function FsOptsWriteTruncate: TFsOpenOptions; inline;
begin
  Result := FsOpenOptions_WriteTruncate;
end;

function FsOptsReadWrite: TFsOpenOptions; inline;
begin
  Result := FsOpenOptions_ReadWrite;
end;


function TFsFile.Tell: Int64;
begin
  Result := GetPosition;
end;

function TFsFile.Size: Int64;
begin
  Result := GetSize;
end;

function TFsFile.PRead(var ABuffer; ACount: Integer; AOffset: Int64): Integer;
var
  LPos: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  LPos := fs_seek(FHandle, 0, SEEK_CUR);
  if LPos < 0 then CheckFsResult(Integer(LPos), 'pread.tell');
  try
    Result := fs_read(FHandle, @ABuffer, ACount, AOffset);
    if Result < 0 then
      CheckFsResult(Result, 'pread');
  finally
    fs_seek(FHandle, LPos, SEEK_SET);
  end;
end;

function TFsFile.PWrite(const ABuffer; ACount: Integer; AOffset: Int64): Integer;
var
  LPos: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  LPos := fs_seek(FHandle, 0, SEEK_CUR);
  if LPos < 0 then CheckFsResult(Integer(LPos), 'pwrite.tell');
  try
    Result := fs_write(FHandle, @ABuffer, ACount, AOffset);
    if Result < 0 then
      CheckFsResult(Result, 'pwrite');
  finally
    fs_seek(FHandle, LPos, SEEK_SET);
  end;
end;



procedure TFsFile.Close;
begin
  if FIsOpen then
  begin
    CheckFsResult(fs_close(FHandle), 'close file');
    FHandle := INVALID_HANDLE_VALUE;
    FIsOpen := False;
    FPath := '';
  end;
end;

function TFsFile.Read(var aBuffer; aCount: Integer): Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);

  Result := fs_read(FHandle, @aBuffer, aCount, -1);
  if Result < 0 then
    CheckFsResult(Result, 'read from file');
end;

function TFsFile.Write(const aBuffer; aCount: Integer): Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);

  Result := fs_write(FHandle, @aBuffer, aCount, -1);
  if Result < 0 then
    CheckFsResult(Result, 'write to file');
end;

procedure TFsFile.Flush;
var
  R: Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  R := fs_fsync(FHandle);
  CheckFsResult(R, 'flush (fsync)');
end;


procedure TFsFile.Truncate(aSize: Int64);
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);

  CheckFsResult(fs_ftruncate(FHandle, aSize), 'truncate file');
end;

function FsDefaultWalkOptions: TFsWalkOptions;
begin
  // 默认包含文件与目录，不跟随符号链接，深度无限；过滤器为空；统计禁用
  Result.FollowSymlinks := False;
  Result.IncludeFiles := True;
  Result.IncludeDirs := True;
  Result.MaxDepth := -1;
  Result.PreFilter := nil;
  Result.PostFilter := nil;
  Result.Stats := nil;
  Result.OnError := nil;
  Result.UseStreaming := False;
  Result.Sort := False;
  Result.MaxErrors := -1;
end;

// 内部遍历：支持复用已知的 Stat，避免对目录的重复 [l]stat
function InternalWalkEx(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback; aDepth: Integer; aHasStat: Boolean; const aKnownStat: TfsStat; aVisited: TStringList): Integer;
var
  LStat: TfsStat;
  I: Integer;
  LPath: string;
  LIsDir: Boolean;
  LRes: Integer;
  LStatRes: Integer;
  LKey: string;
  LHaveKey: Boolean;
  // 回调式枚举收集器
  LWrap: TfsScandirEachWrapper;
  function HandleError(const APath: string; Code: Integer): Integer;
  var Act: TFsWalkErrorAction;
      Unified: Integer;
  begin
    if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.Errors);
    Unified := ToUnifiedFsErrorCode(Code);
    // 最大错误阈值：达到阈值后直接 Abort
    if (aOptions.MaxErrors >= 0) and Assigned(aOptions.Stats) then
    begin
      if aOptions.Stats^.Errors > QWord(aOptions.MaxErrors) then
        Exit(Unified);
    end;
    if Assigned(aOptions.OnError) then
    begin
      Act := aOptions.OnError(APath, Unified, aDepth);
      case Act of
        weaContinue: Exit(0);
        weaSkipSubtree: Exit(1);
        weaAbort: Exit(Unified);
      end;
    end;
    Exit(0);
  end;

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
    // 优先使用 (Dev,Ino) 作为稳定键；Windows 下 Dev/Ino 可能为 0，改用 FileIndex
    if (AStat.Dev <> 0) or (AStat.Ino <> 0) then
    begin
      Key := IntToHex(AStat.Dev, 16) + ':' + IntToHex(AStat.Ino, 16);
      Exit(True);
    end;
    {$IFDEF WINDOWS}
    // Windows：尝试通过 BY_HANDLE_FILE_INFORMATION 获取 VolumeSerial+FileIndex
    // 注意：当前路径可能是目录，使用 CreateFileW 以 FILE_FLAG_BACKUP_SEMANTICS 打开
    // 直接进行最小转换（UTF-8 → UTF-16 + 反斜杠）；长路径/前缀问题失败时将回退到 realpath
    WPath := UTF8Decode(ToWindowsPath(APath));
    H := CreateFileW(PWideChar(WPath), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
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
    // 回退：缓冲区版 realpath
    R := fafafa.core.fs.fs_realpath(APath, @Buf[0], Length(Buf));
    if R >= 0 then
    begin
      SetString(RealPath, PChar(@Buf[0]), R);
      Key := RealPath;
      Exit(True);
    end;
    Key := '';
    Exit(False);
  end;
begin
  Result := 0;

  // 边界：深度限制
  if (aOptions.MaxDepth >= 0) and (aDepth > aOptions.MaxDepth) then
    Exit(0);

  // 获取根目录自身信息并回调（目录）；若已知则复用
  if aHasStat then
  begin
    LStat := aKnownStat;
  end
  else
  begin
    LStatRes := fs_lstat(aRoot, LStat);
    if LStatRes < 0 then
    begin
      // 根路径无效：若未提供 OnError，则直接返回统一错误码（与旧行为一致）
      if not Assigned(aOptions.OnError) then
        Exit(ToUnifiedFsErrorCode(LStatRes))
      else
      begin
        // 提供 OnError：交由策略决定（继续/跳过/中止）
        LRes := HandleError(aRoot, LStatRes);
        if LRes < 0 then Exit(LRes)
        else if LRes = 1 then Exit(0) // 跳过子树：此处等价于空操作
        else Exit(0); // 继续
      end;
    end;
  end;

  LIsDir := (LStat.Mode and S_IFMT) = S_IFDIR;

  if LIsDir then
  begin
    if aOptions.IncludeDirs then
    begin
      if Assigned(aCallback) then
        if not aCallback(aRoot, LStat, aDepth) then
          Exit(0);
    end;
  end
  else
  begin
    // 普通文件情况
    if aOptions.IncludeFiles then
    begin
      if Assigned(aCallback) then
        if not aCallback(aRoot, LStat, aDepth) then
          Exit(0);
    end;
    Exit(0);
  end;

  // 遍历目录内容（回调式收集名称与基础类型）

  LWrap := TfsScandirEachWrapper.Create;
  try
    LRes := fs_scandir_each(aRoot, {$IFDEF FPC}@{$ENDIF}LWrap.OnEntry);
    if LRes < 0 then
    begin
      // 目录枚举失败也应遵循 OnError 策略（Continue/SkipSubtree/Abort）
      LRes := HandleError(aRoot, LRes);
      if LRes < 0 then Exit(LRes);
      Exit(0);
    end;

    // 稳定排序
    LWrap.SortStable;

    for I := 0 to LWrap.Count - 1 do
    begin
      LPath := JoinPath(aRoot, LWrap.NameAt(I));

      // PreFilter：如提供，则可基于基础类型与路径早期过滤，避免不必要 stat
      if Assigned(aOptions.PreFilter) then
      begin
        if not aOptions.PreFilter(LPath, LWrap.TypeAt(I), aDepth + 1) then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.PreFiltered);
          Continue;
        end;
      end;

      // 根据 FollowSymlinks 与基础类型决定 stat 策略
      case LWrap.TypeAt(I) of
        fsDETDir:    LStatRes := fs_lstat(LPath, LStat); // 目录：总是 lstat 一次以提供完整元信息
        fsDETFile:   if aOptions.FollowSymlinks then LStatRes := fs_stat(LPath, LStat) else LStatRes := fs_lstat(LPath, LStat);
        fsDETSymlink, fsDETUnknown:
          if aOptions.FollowSymlinks then LStatRes := fs_stat(LPath, LStat)
          else LStatRes := fs_lstat(LPath, LStat);
      end;

      if LStatRes < 0 then
      begin
        LRes := HandleError(LPath, LStatRes);
        if LRes < 0 then Exit(LRes) else if LRes = 1 then Continue;
      end;

      // PostFilter：如提供，则在已获得 stat 后再决定是否触发回调
      if Assigned(aOptions.PostFilter) then
      begin
        if not aOptions.PostFilter(LPath, LStat, aDepth + 1) then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.PostFiltered);
          // 对于目录：仍然递归，但不回调当前目录节点
          // 对于文件：直接跳过回调
          LIsDir := (LStat.Mode and S_IFMT) = S_IFDIR;
          if LIsDir then
          begin
            Result := InternalWalkEx(LPath, aOptions, aCallback, aDepth + 1, True, LStat, aVisited);
            if Result < 0 then Exit(Result);
          end;
          Continue;
        end;
      end;

      // 若 FollowSymlinks=True 且目标经 fs_stat 判定为目录，则按目录递归（覆盖 DirEnt 基础类型判断）
      if aOptions.FollowSymlinks and ((LStat.Mode and S_IFMT) = S_IFDIR) then
      begin
        // 目录：先回调目录（若 IncludeDirs），再递归
        if aOptions.IncludeDirs then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.DirsVisited);
          if Assigned(aCallback) then
            if not aCallback(LPath, LStat, aDepth + 1) then
              Exit(0);
        end
        else
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.DirsVisited);
        end;
        if aOptions.FollowSymlinks then
        begin
          LHaveKey := MakeVisitedKey(LPath, LStat, LKey);
          if LHaveKey and Assigned(aVisited) then
          begin
            if aVisited.IndexOf(LKey) >= 0 then
              Exit(0)
            else
              aVisited.Add(LKey);
          end;
        end;
        Result := InternalWalkEx(LPath, aOptions, aCallback, aDepth + 1, True, LStat, aVisited);
        if Result < 0 then Exit(Result);
        Continue;
      end;
      LIsDir := (LStat.Mode and S_IFMT) = S_IFDIR;

      if LIsDir then
      begin
        // 目录：先回调目录（若 IncludeDirs），再递归
        if aOptions.IncludeDirs then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.DirsVisited);
          if Assigned(aCallback) then
            if not aCallback(LPath, LStat, aDepth + 1) then
              Exit(0);
        end
        else
        begin
          // 即使不回调目录，也统计访问
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.DirsVisited);
        end;
        // 目录递归前：若跟随符号链接，则进行 visited-set 环路防护
        if aOptions.FollowSymlinks then
        begin
          LHaveKey := MakeVisitedKey(LPath, LStat, LKey);
          if LHaveKey and Assigned(aVisited) then
          begin
            if aVisited.IndexOf(LKey) >= 0 then
              Continue
            else
              aVisited.Add(LKey);
          end;
        end;
        Result := InternalWalkEx(LPath, aOptions, aCallback, aDepth + 1, True, LStat, aVisited);
        if Result < 0 then Exit(Result);
      end
      else
      begin
        if aOptions.IncludeFiles then
        begin
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.FilesVisited);
          if Assigned(aCallback) then
            if not aCallback(LPath, LStat, aDepth + 1) then
              Exit(0);
        end
        else
        begin
          // 即使不回调文件，也统计访问
          if Assigned(aOptions.Stats) then Inc(aOptions.Stats^.FilesVisited);
        end;
      end;
    end;
  finally
    FreeAndNil(LWrap);
  end;
end;

function InternalWalk(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback; aDepth: Integer): Integer;
var
  LVisited: TStringList;
begin
  // 仅在 FollowSymlinks=True 场景下维护 visited-set；否则为 nil，保持零开销
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

function WalkDir(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback): Integer;
begin
  Result := InternalWalk(ResolvePath(aRoot), aOptions, aCallback, 0);
end;



function TFsFile.GetSize: Int64;
var
  LStat: TfsStat;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);

  CheckFsResult(fs_fstat(FHandle, LStat), 'get file size');
  Result := LStat.Size;
end;

function TFsFile.GetPosition: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);

  Result := fs_tell(FHandle);
  if Result < 0 then
    CheckFsResult(Integer(Result), 'get file position');
end;

procedure TFsFile.SetPosition(const aValue: Int64);
var
  LResult: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);

  LResult := fs_seek(FHandle, aValue, SEEK_SET);
  if LResult < 0 then
    CheckFsResult(Integer(LResult), 'set file position');
end;

function TFsFile.ReadString(aEncoding: TEncoding): string;
var
  LBytes: TBytes;
begin
  LBytes := ReadBytes;
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;
  // 显式转换以避免 4105（UnicodeString -> AnsiString）告警
  Result := string(aEncoding.GetString(LBytes));
end;

procedure TFsFile.WriteString(const aText: string; aEncoding: TEncoding);
var
  LBytes: TBytes;
begin
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;
  // 显式转换以避免 4104（AnsiString -> UnicodeString）告警
  LBytes := aEncoding.GetBytes(UnicodeString(aText));
  WriteBytes(LBytes);
end;

function TFsFile.ReadBytes: TBytes;
var
  LSize: Int64;
  LBytesRead: Integer;
begin
  Result := nil; // 受管返回值显式初始化
  LSize := GetSize;
  if LSize > 0 then
  begin
    SetLength(Result, LSize);
    LBytesRead := Read(Result[0], LSize);
    SetLength(Result, LBytesRead);
  end;
end;

procedure TFsFile.WriteBytes(const aBytes: TBytes);
begin
  if Length(aBytes) > 0 then
    Write(aBytes[0], Length(aBytes));
end;

// 便利函数实现

function ReadTextFile(const aPath: string; aEncoding: TEncoding): string;
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomRead);
    Result := LFile.ReadString(aEncoding);
  finally
    LFile.Free;
  end;
end;

procedure WriteTextFile(const aPath, aText: string; aEncoding: TEncoding);
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomWrite);
    LFile.WriteString(aText, aEncoding);
  finally
    LFile.Free;
  end;
end;

function ReadBinaryFile(const aPath: string): TBytes;
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomRead);
    Result := LFile.ReadBytes;
  finally
    LFile.Free;
  end;
end;

procedure WriteBinaryFile(const aPath: string; const aData: TBytes);
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;

  try
    LFile.Open(aPath, fomWrite);
    LFile.WriteBytes(aData);
  finally
    LFile.Free;
  end;
end;



function FileExists(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_stat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFREG);
end;

function DirectoryExists(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_stat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFDIR);
end;

// ===== No-Exception Wrapper implementation (moved out of FileExists) =====
function NewFsFileNoExcept: TFsFileNoExcept;
begin
  Result.FileIntf := NewFsFile;
end;



function TFsFileNoExcept.Open(const APath: string; AMode: TFsOpenMode): Integer;
begin
  try
    FileIntf.Open(APath, AMode);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Close: Integer;
begin
  try
    FileIntf.Close;
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Read(var ABuffer; ACount: Integer; out N: Integer): Integer;
begin
  N := 0;
  try
    N := FileIntf.Read(ABuffer, ACount);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Write(const ABuffer; ACount: Integer; out N: Integer): Integer;
begin
  N := 0;
  if @ABuffer = nil then ;
  try
    N := FileIntf.Write(ABuffer, ACount);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Seek(ADistance: Int64; AWhence: Integer; out NewPos: Int64): Integer;
begin
  NewPos := 0;
  try
    NewPos := FileIntf.Seek(ADistance, AWhence);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Tell(out Pos: Int64): Integer;
begin
  Pos := 0;
  try
    Pos := FileIntf.Tell;
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Size(out ASize: Int64): Integer;
begin
  ASize := 0;
  try
    ASize := FileIntf.Size;
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Truncate(ANewSize: Int64): Integer;
begin
  try
    FileIntf.Truncate(ANewSize);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.Flush: Integer;
begin
  try
    FileIntf.Flush;
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.PRead(var ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
begin
  N := 0;
  try
    N := FileIntf.PRead(ABuffer, ACount, AOffset);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;

function TFsFileNoExcept.PWrite(const ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
begin
  N := 0;
  if @ABuffer = nil then ;
  try
    N := FileIntf.PWrite(ABuffer, ACount, AOffset);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
  end;
end;


procedure CreateDirectory(const aPath: string; aRecursive: Boolean);
var
  LParentPath: string;
begin
  if aRecursive then
  begin
    // 递归创建目录
    LParentPath := ExtractFileDir(aPath);
    if (LParentPath <> '') and (LParentPath <> aPath) and not DirectoryExists(LParentPath) then
      CreateDirectory(LParentPath, True);
  end;

  // 如果目录已存在，不报错
  if not DirectoryExists(aPath) then
    CheckFsResult(fs_mkdir(aPath, S_IRWXU), 'create directory');
end;

procedure DeleteFile(const aPath: string);
begin
  CheckFsResult(fs_unlink(aPath), 'delete file');
end;

procedure DeleteDirectory(const aPath: string; aRecursive: Boolean);
var
  LDirEntries: TStringList;
  LEntry: string;
  LFullPath: string;
  LStat: TfsStat;
  I: Integer;
begin
  if aRecursive then
  begin
    // 递归删除目录内容
    LDirEntries := TStringList.Create;
    try
      if fs_scandir(aPath, LDirEntries) = 0 then
      begin
        for I := 0 to LDirEntries.Count - 1 do
        begin
          LEntry := LDirEntries[I];
          if (LEntry = '.') or (LEntry = '..') then
            Continue;

          LFullPath := IncludeTrailingPathDelimiter(aPath) + LEntry;

          if fs_stat(LFullPath, LStat) = 0 then
          begin
            if (LStat.Mode and S_IFMT) = S_IFDIR then
              DeleteDirectory(LFullPath, True)  // 递归删除子目录
            else
              DeleteFile(LFullPath);  // 删除文件
          end;
        end;
      end;
    finally
      LDirEntries.Free;
    end;
  end;

  CheckFsResult(fs_rmdir(aPath), 'delete directory');
end;


// ===== Copy/Move =====
procedure FsCopyFileEx(const aSrc, aDst: string; const aOpts: TFsCopyOptions);

var
  UR: Integer;
  Flags: Integer;
  Stat: TfsStat;
  AccelUsed: Boolean;
  AccelRes: Integer;
begin
  // Overwrite=false → 使用 EXCL 标志；Overwtite=true → 覆盖
  // 优先尝试内核加速复制（若可用）
  AccelUsed := False;
  AccelRes := FsCopyAccelTryCopyFile(aSrc, aDst, aOpts.Overwrite, AccelUsed);
  // 常规路径准备（加速失败或未使用时）
  if not (AccelUsed and (AccelRes = 0)) then
  begin
    Flags := 0;
  if not aOpts.Overwrite then
    Flags := Flags or UV_FS_COPYFILE_EXCL
  else
  begin
    UR := fs_unlink(aDst);
    if (UR < 0) and (not IsNotFound(UR)) then
      CheckFsResultEx(UR, 'pre-unlink before copy overwrite', aDst, '');
  end;
  CheckFsResultEx(fs_copyfile(aSrc, aDst, Flags), 'copyfile', aSrc, aDst);
  end;
  // PreserveTimes/Perms：共用一次 stat 结果，避免重复触盘
  if aOpts.PreserveTimes or aOpts.PreservePerms then
  begin
    if fs_stat(aSrc, Stat) = 0 then
    begin
      if aOpts.PreserveTimes then
      begin
        // Windows 路径将由 fs_utime → SetFileTime 处理；POSIX 优先 utimens/futimens
        fs_utime(aDst, Stat.ATime.Sec + Stat.ATime.Nsec / 1e9, Stat.MTime.Sec + Stat.MTime.Nsec / 1e9);
      end;
      if aOpts.PreservePerms then
      begin
        // 仅 POSIX 低 9 位权限位（Windows 忽略）
        fs_chmod(aDst, Stat.Mode and $1FF);
      end;
    end;
  end;
end;

procedure FsMoveFileEx(const aSrc, aDst: string; const aOpts: TFsMoveOptions);
var
  R: Integer;
  CopyOpts: TFsCopyOptions;
  DstStat: TfsStat;
begin
  // Overwrite 语义：POSIX rename(2) 会覆盖已存在的目标文件。
  // 因此当 Overwrite=False 时必须显式检查目标是否存在并抛出 FS_ERROR_FILE_EXISTS。
  if not aOpts.Overwrite then
  begin
    R := fs_lstat(aDst, DstStat);
    if R = 0 then
      raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Destination exists', 0);
    if (R < 0) and (not IsNotFound(R)) then
      CheckFsResultEx(R, 'stat destination before move', aDst, '');
  end
  else if FileExists(aDst) then
  begin
    CheckFsResultEx(fs_unlink(aDst), 'pre-unlink before move overwrite', aDst, '');
  end;

  // 尝试重命名（同卷 O(1)）
  R := fs_rename(aSrc, aDst);
  if R = 0 then Exit;
  // 跨卷或其他原因无法 rename → fallback：复制
  CopyOpts.Overwrite := aOpts.Overwrite;
  CopyOpts.PreserveTimes := aOpts.PreserveTimes;
  CopyOpts.PreservePerms := aOpts.PreservePerms;
  // 在复制回退前，尝试系统替换（可跨卷）以提升性能
  if aOpts.Overwrite then
  begin
    R := fs_replace(aSrc, aDst);
    if R = 0 then Exit;
  end;
  FsCopyFileEx(aSrc, aDst, CopyOpts);
  // 使用原子替换确保幂等（若覆盖）已在 FsCopyFileEx 中处理；此处删除源
  CheckFsResultEx(fs_unlink(aSrc), 'unlink source after move', aSrc, '');
end;

function GetFileSize(const aPath: string): Int64;
var
  LStat: TfsStat;
begin
  CheckFsResult(fs_stat(aPath, LStat), 'get file size');
  Result := LStat.Size;
end;

function GetFileModificationTime(const aPath: string): TDateTime;
var
  LStat: TfsStat;
  Base: TDateTime;
begin
  CheckFsResult(fs_stat(aPath, LStat), 'get file modification time');
  // 正确实现：将 Unix 时间（秒+纳秒）转换为 TDateTime（UTC 基准）
  Base := UnixToDateTime(LStat.MTime.Sec, True);
  Result := Base + (LStat.MTime.Nsec / 1e9) / 86400.0; // 纳秒的小数部分换算为天
end;


// ===== Copy/Move Tree =====
procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions);
var
  Dummy: TFsTreeResult;
begin
  // 调用重载，忽略统计
  Dummy := Default(TFsTreeResult);
  FsCopyTreeEx(aSrcRoot, aDstRoot, aOpts, Dummy);
end;

procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions; out aResult: TFsTreeResult);
var
  SrcRoot, DstRoot: string;
  WalkOpts: TFsWalkOptions;
  Walker: TCopyTreeWalker;
begin
  // 使用 ResolvePath 保持与 WalkDir 内部一致（均不触盘、不过度跟随链接），避免 ToRelativePath 组件不匹配
  SrcRoot := ResolvePath(aSrcRoot);
  DstRoot := ResolvePath(aDstRoot);

  if not DirectoryExists(SrcRoot) then
    raise EFsError.Create(FS_ERROR_FILE_NOT_FOUND, 'Source root not found', 0);

  // 处理目标根策略（默认 rbMerge 保持兼容）
  if DirectoryExists(DstRoot) then
  begin
    case aOpts.RootBehavior of
      rbError:
        raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Destination root exists', 0);
      rbReplace:
        DeleteDirectory(DstRoot, True);
      rbMerge: ;
    end;
  end;
  if not DirectoryExists(DstRoot) then
    CreateDirectory(DstRoot, True);

  WalkOpts := FsDefaultWalkOptions;
  WalkOpts.FollowSymlinks := aOpts.FollowSymlinks;
  WalkOpts.IncludeFiles := True;
  // 复制树：避免对每个目录节点重复回调导致 CreateDirectory/复制重复，改为不回调目录，仅递归进入
  WalkOpts.IncludeDirs := False;
  WalkOpts.MaxDepth := -1;
  WalkOpts.UseStreaming := True;
  WalkOpts.Sort := False;

  Walker := TCopyTreeWalker.Create;
  try
    Walker.SrcRoot := SrcRoot;
    Walker.DstRoot := DstRoot;
    Walker.Overwrite := aOpts.Overwrite;
    Walker.PreserveTimes := aOpts.PreserveTimes;
    Walker.PreservePerms := aOpts.PreservePerms;
    Walker.FollowSymlinks := aOpts.FollowSymlinks;
    Walker.CopySymlinksAsLinks := aOpts.CopySymlinksAsLinks;
    Walker.ErrorPolicy := aOpts.ErrorPolicy;
    Walker.FilesCopied := 0;
    Walker.DirsCreated := 0;
    Walker.BytesCopied := 0;

    // 错误策略对齐 WalkDir（需要已初始化的 Walker 以绑定 OnError 方法指针）
    case aOpts.ErrorPolicy of
      epAbort: WalkOpts.OnError := nil; // 沿用旧行为：出错返回负码（由 CheckFsResult 抛）
      epContinue, epSkipSubtree: WalkOpts.OnError := @Walker.OnWalkError;
    end;

    CheckFsResult(WalkDir(SrcRoot, WalkOpts, @Walker.OnEach), 'copy tree walk');
    // 输出统计
    aResult.FilesCopied := Walker.FilesCopied;
    aResult.DirsCreated := Walker.DirsCreated;
    aResult.BytesCopied := Walker.BytesCopied;
    aResult.Errors := Walker.Errors;
  finally
    Walker.Free;
  end;
end;

procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions);
var
  Dummy: TFsTreeResult;
begin
  // 调用重载，忽略统计
  Dummy := Default(TFsTreeResult);
  FsMoveTreeEx(aSrcRoot, aDstRoot, aOpts, Dummy);
end;

procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions; out aResult: TFsTreeResult);
var
  CopyOpts: TFsCopyTreeOptions;
  R: Integer;
  SrcRoot, DstRoot: string;
  TmpName: string;
begin
  // 统一使用 ResolvePath
  SrcRoot := ResolvePath(aSrcRoot);
  DstRoot := ResolvePath(aDstRoot);

  // 目标存在处理（RootBehavior）
  if DirectoryExists(DstRoot) then
  begin
    case aOpts.RootBehavior of
      rbError:
        raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Destination root exists', 0);
      rbReplace:
        begin
          // 尽最大努力减少空窗：先将目标改名为临时名，再将源改名为目标，最后删除临时名
          // 若任一步失败，回退到旧策略（直接递归删除目标）
          TmpName := DstRoot + '.old_' + IntToStr(GetTickCount64);
          R := fs_rename(DstRoot, TmpName);
          if R = 0 then
          begin
            R := fs_rename(SrcRoot, DstRoot);
            if R = 0 then
            begin
              // 清理旧目标
              DeleteDirectory(TmpName, True);
              aResult.FilesCopied := 0;
              aResult.DirsCreated := 0;
              aResult.BytesCopied := 0;
              aResult.Errors := 0;
              Exit;
            end
            else
            begin
              // 回退：无法直接替换，恢复现场，进入复制路径
              fs_rename(TmpName, DstRoot);
              // 继续走复制分支
            end;
          end
          else
          begin
            // 无法改名目标：回退到旧策略
            DeleteDirectory(DstRoot, True);
          end;
        end;
      rbMerge: ;
    end;
  end;

  // 若目标不存在，优先尝试整树重命名（同卷 O(1)）
  if not DirectoryExists(DstRoot) then
  begin
    R := fs_rename(SrcRoot, DstRoot);
    if R = 0 then
    begin
      aResult.FilesCopied := 0;
      aResult.DirsCreated := 0;
      aResult.BytesCopied := 0;
      aResult.Errors := 0;
      Exit;
    end;
    // 失败（可能跨卷/占用/权限），回退到复制
  end;

  // 回退路径：复制后删除源
  CopyOpts.Overwrite := aOpts.Overwrite;
  CopyOpts.PreserveTimes := aOpts.PreserveTimes;
  CopyOpts.PreservePerms := aOpts.PreservePerms;
  CopyOpts.FollowSymlinks := aOpts.FollowSymlinks;
  CopyOpts.RootBehavior := aOpts.RootBehavior;
  CopyOpts.ErrorPolicy := aOpts.ErrorPolicy;
  CopyOpts.CopySymlinksAsLinks := aOpts.CopySymlinksAsLinks;
  FsCopyTreeEx(SrcRoot, DstRoot, CopyOpts, aResult);
  DeleteDirectory(SrcRoot, True);
end;


procedure WriteFileAtomic(const aPath: string; const aData: TBytes);
var
  Dir, TempName: string;
begin
  Dir := ExtractFileDir(aPath);
  if Dir = '' then Dir := GetCurrentDir;
  TempName := IncludeTrailingPathDelimiter(Dir) + '.tmp_atomic_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(100000)) + '.tmp';
  // 写临时
  WriteBinaryFile(TempName, aData);
  // 原子替换
  CheckFsResult(fs_replace(TempName, aPath), 'atomic replace');
  // 兜底清理
  try
    if FileExists(TempName) then
      CheckFsResult(fs_unlink(TempName), 'cleanup temp after atomic replace');
  except
  end;
end;


procedure WriteTextFileAtomic(const aPath, aText: string; aEncoding: TEncoding);
var
  Bytes: TBytes;
begin
  if aEncoding = nil then aEncoding := TEncoding.UTF8;
  // 显式转换以避免 4104（AnsiString -> UnicodeString）告警
  Bytes := aEncoding.GetBytes(UnicodeString(aText));
  WriteFileAtomic(aPath, Bytes);
end;


function FsDefaultRemoveTreeOptions: TFsRemoveTreeOptions;
begin
  Result.FollowSymlinks := False;
  Result.ErrorPolicy := epAbort;
end;

procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions);
var Dummy: TFsRemoveTreeResult;
begin
  Dummy := Default(TFsRemoveTreeResult);
  RemoveTreeEx(aRoot, aOpts, Dummy);
end;

procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions; out aResult: TFsRemoveTreeResult);
var
  WalkOpts: TFsWalkOptions;

  LErrorPolicy: TFsErrorPolicy;
  Walker: TRemoveWalker;
  I: Integer;
  DP: string;
  SR: Integer;
  S: TfsStat;
  Rm: Integer;
  AbsTarget: string;
  DelOpts: TFsRemoveTreeOptions;
  RDel: TFsRemoveTreeResult;

  function DoUnlinkOrRmdir(const P: string; const S: TfsStat): Integer; inline;
  var ModeBits: UInt64;
  begin
    ModeBits := S.Mode and S_IFMT;
    if ModeBits = S_IFDIR then Exit(fs_rmdir(P)) else Exit(fs_unlink(P));
  end;
begin
  aResult.FilesRemoved := 0; aResult.DirsRemoved := 0; aResult.Errors := 0;
  Walker := TRemoveWalker.Create;
  try
    Walker.Opts := aOpts; Walker.FilesRemoved := 0; Walker.DirsRemoved := 0; Walker.Errors := 0;
    Walker.Dirs := TStringList.Create; Walker.ExternalTargets := TStringList.Create; Walker.ExternalTargets.Sorted := True; Walker.ExternalTargets.Duplicates := dupIgnore;

    WalkOpts := FsDefaultWalkOptions;
    WalkOpts.FollowSymlinks := aOpts.FollowSymlinks;
    WalkOpts.IncludeFiles := True; WalkOpts.IncludeDirs := True;
    WalkOpts.MaxDepth := -1; WalkOpts.UseStreaming := True; WalkOpts.Sort := False;
    WalkOpts.OnError := @Walker.OnWalkError;

    LErrorPolicy := aOpts.ErrorPolicy;
    // Walk 根失败时按策略处理：Abort 抛异常；Continue/SkipSubtree 记录错误并返回
    // 若根不存在，按策略处理（Abort 抛异常；Continue/Skip 计错并返回）
    if not DirectoryExists(ResolvePath(aRoot)) then
    begin
      // 根不存在时视为已清理（幂等）。不抛异常，直接返回统计（0）。
      aResult.FilesRemoved := Walker.FilesRemoved;
      aResult.DirsRemoved := Walker.DirsRemoved;
      aResult.Errors := Walker.Errors;
      Exit;
    end;
    SR := WalkDir(ResolvePath(aRoot), WalkOpts, @Walker.OnEach);
    if SR < 0 then
    begin
      case LErrorPolicy of
        epAbort:
          CheckFsResult(SR, 'remove tree walk');
        epContinue, epSkipSubtree:
          begin
            Inc(Walker.Errors);
            // 根失败即无后续可删，直接汇总返回
            aResult.FilesRemoved := Walker.FilesRemoved;
            aResult.DirsRemoved := Walker.DirsRemoved;
            aResult.Errors := Walker.Errors;
            Exit;
          end;
      end;
    end;

    if Walker.Dirs.Count > 0 then
    begin
      I := Walker.Dirs.Count - 1;
      while I >= 0 do
      begin
        DP := Walker.Dirs[I];

        // FollowSymlinks=True 场景下，WalkDir 会把“指向目录的符号链接”当作目录遍历。
        // 此时 Walker.Dirs 会包含该链接路径；但对链接路径调用 rmdir(2) 在 POSIX 上会返回 ENOTDIR。
        // 正确行为：删除链接本体（unlink），其目标目录由 ExternalTargets 统一清理。
        if aOpts.FollowSymlinks then
        begin
          if fs_lstat(DP, S) = 0 then
          begin
            if (S.Mode and S_IFMT) = S_IFLNK then
            begin
              SR := fs_unlink(DP);
              if SR < 0 then
              begin
                if not IsNotFound(SR) then
                begin
                  Inc(Walker.Errors);
                  case LErrorPolicy of
                    epAbort: CheckFsResult(SR, 'unlink symlink during remove');
                    epContinue, epSkipSubtree: ;
                  end;
                end;
              end
              else
                Inc(Walker.FilesRemoved);

              Dec(I);
              Continue;
            end;
          end;
        end;

        SR := fs_rmdir(DP);
        if SR < 0 then
        begin
          // 容忍目录已不存在（可能被并发或重复路径删除）
          if not IsNotFound(SR) then
          begin
            Inc(Walker.Errors);
            case LErrorPolicy of
              epAbort: CheckFsResult(SR, 'rmdir during remove');
              epContinue, epSkipSubtree: ;
            end;
          end;
        end
        else Inc(Walker.DirsRemoved);
        Dec(I);
      end;
    end;



    if fs_lstat(aRoot, S) = 0 then
    begin
      Rm := DoUnlinkOrRmdir(aRoot, S);
      if Rm < 0 then
      begin
        Inc(Walker.Errors);
        case LErrorPolicy of
          epAbort: CheckFsResult(Rm, 'remove root');
          epContinue, epSkipSubtree: ;
        end;
      end else begin
        if (S.Mode and S_IFMT) = S_IFDIR then Inc(Walker.DirsRemoved) else Inc(Walker.FilesRemoved);
      end;
    end;

    aResult.FilesRemoved := Walker.FilesRemoved;
    aResult.DirsRemoved := Walker.DirsRemoved;
    aResult.Errors := Walker.Errors;
  finally
    // 统一清理在遍历阶段收集到的外部目标目录（去重）
    if Assigned(Walker.ExternalTargets) then
    begin
      for I := 0 to Walker.ExternalTargets.Count - 1 do
      begin
        AbsTarget := Walker.ExternalTargets[I];
        if fs_lstat(AbsTarget, S) = 0 then
        begin
          if (S.Mode and S_IFMT) = S_IFDIR then
          begin
            try
              DelOpts := FsDefaultRemoveTreeOptions;
              DelOpts.FollowSymlinks := aOpts.FollowSymlinks;
              DelOpts.ErrorPolicy := LErrorPolicy;
              RemoveTreeEx(AbsTarget, DelOpts, RDel);
              if (fs_lstat(AbsTarget, S) = 0) and ((S.Mode and S_IFMT) = S_IFDIR) then
              begin
                try DeleteDirectory(AbsTarget, True); except end;
              end;
              if (fs_lstat(AbsTarget, S) = 0) and ((S.Mode and S_IFMT) = S_IFDIR) then
                CheckFsResult(fs_rmdir(AbsTarget), 'rmdir external target at finalize');
            except
              on E: EFsError do
              begin
                Inc(Walker.Errors);
                case LErrorPolicy of
                  epAbort: raise;
                  epContinue, epSkipSubtree: ;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    Walker.Dirs.Free; Walker.ExternalTargets.Free; Walker.Free;
  end;
end;

function TRemoveWalker.OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  if aPath = '' then ;
  if aError = 0 then ;
  if aDepth < 0 then ;

  Inc(Errors);
  Result := weaAbort;
  case Opts.ErrorPolicy of
    epAbort: Result := weaAbort;
    epContinue: Result := weaContinue;
    epSkipSubtree: Result := weaSkipSubtree;
  end;
end;

function TRemoveWalker.OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
var
  R: Integer;
  ModeBits: UInt64;
  LSym: TfsStat;
  LinkT: string;
  RealT: string;
begin
  if aDepth < 0 then ;
  ModeBits := aStat.Mode and S_IFMT;
  if ModeBits = S_IFDIR then
  begin
    // 若跟随符号链接且当前路径为目录：
    // - 先记录目录供逆序删除
    // - 如果本身是符号链接（Windows：reparse 点且确认是 symlink），则记录其最终目标，供结束后统一删除
    Dirs.Add(aPath);
    if Opts.FollowSymlinks then
    begin
      // 注意：当 FollowSymlinks=True 时，aStat 可能反映的是“目标”的 stat（目录），
      // 因此需要用 lstat(aPath) 来判断 aPath 本身是否为符号链接
      if fs_lstat(aPath, LSym) = 0 then
      begin
        if (LSym.Mode and S_IFMT) = S_IFLNK then
        begin
          // fs_realpath 在 Unix 上可能是非触盘/非解析链接的 fallback（ExpandFileName），
          // 无法得到“符号链接指向的目标”。这里改用 readlink 并按链接所在目录解析相对路径。
          LinkT := '';
          if fs_readlink_s(aPath, LinkT) >= 0 then
          begin
            if IsAbsolutePath(LinkT) then
              RealT := ResolvePath(LinkT)
            else
              RealT := ResolvePath(JoinPath(ExtractFileDir(aPath), LinkT));
            if RealT <> '' then
              ExternalTargets.Add(RealT);
          end;
        end;
      end;
    end;
    Exit(True);
  end;

  // 如果是符号链接且需要跟随，先记录其真实目标，最终阶段统一删除
  if Opts.FollowSymlinks and ((aStat.Mode and S_IFMT) = S_IFLNK) then
  begin
    LinkT := '';
    if fs_readlink_s(aPath, LinkT) >= 0 then
    begin
      if IsAbsolutePath(LinkT) then
        RealT := ResolvePath(LinkT)
      else
        RealT := ResolvePath(JoinPath(ExtractFileDir(aPath), LinkT));
      if RealT <> '' then
        ExternalTargets.Add(RealT);
    end;
  end;

  R := fs_unlink(aPath);
  if R < 0 then
  begin
    Inc(Errors);
    case Opts.ErrorPolicy of
      epAbort: begin CheckFsResult(R, 'unlink during remove'); Exit(False); end;
      epContinue, epSkipSubtree: ;
    end;
  end
  else Inc(FilesRemoved);
  Result := True;
end;

end.
