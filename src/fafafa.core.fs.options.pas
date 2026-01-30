unit fafafa.core.fs.options;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{**
 * fafafa.core.fs.options - 文件系统操作选项类型
 *
 * 从 fafafa.core.fs.highlevel.pas 拆分而来，包含：
 * - 文件打开选项 (TFsOpenMode, TFsShareMode, TFsOpenOptions)
 * - 复制/移动选项 (TFsCopyOptions, TFsMoveOptions)
 * - 目录树操作选项 (TFsCopyTreeOptions, TFsMoveTreeOptions, TFsRemoveTreeOptions)
 * - 目录遍历选项 (TFsWalkOptions, TFsWalkCallback 等)
 * - 默认选项构造函数
 *
 * @author Claude Code (技术债务修复 - highlevel.pas 拆分)
 * @date 2025-12-23
 *}

interface

uses
  fafafa.core.fs;

type
  // ===== 文件打开选项 =====

  {** 文件打开模式 *}
  TFsOpenMode = (
    fomRead,           // 只读
    fomWrite,          // 只写（截断）
    fomReadWrite,      // 读写
    fomAppend,         // 追加
    fomCreate,         // 创建新文件
    fomCreateExclusive // 创建新文件（如果存在则失败）
  );

  {** 文件共享模式 *}
  TFsShareMode = set of (
    fsmRead,   // 允许其他进程读取
    fsmWrite,  // 允许其他进程写入
    fsmDelete  // 允许其他进程删除
  );

  {** 高层打开选项记录 *}
  TFsOpenOptions = record
    Read: Boolean;
    Write: Boolean;
    Append: Boolean;
    Create: Boolean;
    CreateNew: Boolean;
    Truncate: Boolean;
    Share: TFsShareMode;
  end;

  // ===== 复制/移动选项 =====

  {** 文件复制选项 *}
  TFsCopyOptions = record
    Overwrite: Boolean;     // 是否覆盖已存在的目标文件
    PreserveTimes: Boolean; // 是否保留时间戳
    PreservePerms: Boolean; // 是否保留权限（Unix 有效，Windows 忽略）
  end;

  {** 文件移动选项 *}
  TFsMoveOptions = record
    Overwrite: Boolean;
    PreserveTimes: Boolean;
    PreservePerms: Boolean;
  end;

  // ===== 目录树操作选项 =====

  {** 根目录处理策略 *}
  TFsRootBehavior = (
    rbMerge,   // 合并到已存在的目标目录
    rbReplace, // 替换已存在的目标目录
    rbError    // 如果目标存在则报错
  );

  {** 错误处理策略 *}
  TFsErrorPolicy = (
    epAbort,       // 立即中止
    epContinue,    // 继续处理
    epSkipSubtree  // 跳过当前子树
  );

  {** 目录树复制选项 *}
  TFsCopyTreeOptions = record
    Overwrite: Boolean;
    PreserveTimes: Boolean;
    PreservePerms: Boolean;
    FollowSymlinks: Boolean;
    RootBehavior: TFsRootBehavior;   // 默认 rbMerge
    ErrorPolicy: TFsErrorPolicy;     // 默认 epAbort
    CopySymlinksAsLinks: Boolean;    // 当 FollowSymlinks=False 时，复制链接本体
  end;

  {** 目录树移动选项 *}
  TFsMoveTreeOptions = record
    Overwrite: Boolean;
    PreserveTimes: Boolean;
    PreservePerms: Boolean;
    FollowSymlinks: Boolean;
    RootBehavior: TFsRootBehavior;
    ErrorPolicy: TFsErrorPolicy;
    CopySymlinksAsLinks: Boolean;
  end;

  {** 目录树删除选项 *}
  TFsRemoveTreeOptions = record
    FollowSymlinks: Boolean;    // 是否跟随符号链接（默认 False）
    ErrorPolicy: TFsErrorPolicy;
  end;

  // ===== 操作结果统计 =====

  {** 目录树操作结果 *}
  TFsTreeResult = record
    FilesCopied: QWord;
    DirsCreated: QWord;
    BytesCopied: QWord;
    Errors: QWord;
  end;

  {** 目录树删除结果 *}
  TFsRemoveTreeResult = record
    FilesRemoved: QWord;
    DirsRemoved: QWord;
    Errors: QWord;
  end;

  // ===== 目录遍历选项 =====

  {** Walk 错误处理动作 *}
  TFsWalkErrorAction = (
    weaContinue,    // 继续遍历（忽略该错误）
    weaSkipSubtree, // 跳过当前子树
    weaAbort        // 立即中止
  );

  {** Walk 错误回调 *}
  TFsWalkOnError = function(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction of object;

  {** Walk 前置过滤器（基于路径与基础类型） *}
  TFsWalkPreFilter = function(const aPath: string; aBasicType: TfsDirEntType; aDepth: Integer): Boolean of object;

  {** Walk 后置过滤器（基于完整 stat） *}
  TFsWalkPostFilter = function(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean of object;

  {** Walk 统计结构 *}
  TFsWalkStats = record
    DirsVisited: QWord;
    FilesVisited: QWord;
    PreFiltered: QWord;
    PostFiltered: QWord;
    Errors: QWord;
  end;

  {** Walk 选项 *}
  TFsWalkOptions = record
    FollowSymlinks: Boolean;  // 是否跟随符号链接
    IncludeFiles: Boolean;    // 是否包含文件
    IncludeDirs: Boolean;     // 是否包含目录
    MaxDepth: Integer;        // 最大深度（<0 表示无限）
    PreFilter: TFsWalkPreFilter;   // 前置过滤（可为 nil）
    PostFilter: TFsWalkPostFilter; // 后置过滤（可为 nil）
    OnError: TFsWalkOnError;       // 错误策略回调（nil 使用默认行为）
    Stats: ^TFsWalkStats;          // 可选统计指针（nil 禁用）
    UseStreaming: Boolean;         // 流式模式
    Sort: Boolean;                 // 是否排序
    MaxErrors: Integer;            // 最大错误数（-1 无限）
  end;

  {** Walk 回调（返回 True 继续，False 早停）*}
  TFsWalkCallback = function(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean of object;

// ===== 默认选项构造函数 =====

function FsDefaultCopyOptions: TFsCopyOptions;
function FsDefaultMoveOptions: TFsMoveOptions;
function FsDefaultCopyTreeOptions: TFsCopyTreeOptions;
function FsDefaultMoveTreeOptions: TFsMoveTreeOptions;
function FsDefaultRemoveTreeOptions: TFsRemoveTreeOptions;
function FsDefaultWalkOptions: TFsWalkOptions;

// ===== OpenOptions 辅助函数 =====

function FsOpenOptions_ReadOnly: TFsOpenOptions;
function FsOpenOptions_WriteTruncate: TFsOpenOptions;
function FsOpenOptions_ReadWrite: TFsOpenOptions;
function FsOpenOptions_WithShare(const Opt: TFsOpenOptions; AShare: TFsShareMode): TFsOpenOptions;
function FsOpenOptions_ToFlags(const Opt: TFsOpenOptions): Integer;

implementation

// ===== 默认选项实现 =====

function FsDefaultCopyOptions: TFsCopyOptions;
begin
  Result.Overwrite := True;
  {$IFDEF UNIX}
  Result.PreserveTimes := True;
  Result.PreservePerms := True;
  {$ELSE}
  Result.PreserveTimes := True;
  Result.PreservePerms := False; // Windows: 忽略 perms
  {$ENDIF}
end;

function FsDefaultMoveOptions: TFsMoveOptions;
begin
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

function FsDefaultRemoveTreeOptions: TFsRemoveTreeOptions;
begin
  Result.FollowSymlinks := False;
  Result.ErrorPolicy := epAbort;
end;

function FsDefaultWalkOptions: TFsWalkOptions;
begin
  Result.FollowSymlinks := False;
  Result.IncludeFiles := True;
  Result.IncludeDirs := True;
  Result.MaxDepth := -1; // 无限深度
  Result.PreFilter := nil;
  Result.PostFilter := nil;
  Result.OnError := nil;
  Result.Stats := nil;
  Result.UseStreaming := False;
  Result.Sort := False;
  Result.MaxErrors := -1;
end;

// ===== OpenOptions 辅助函数实现 =====

function FsOpenOptions_ReadOnly: TFsOpenOptions;
begin
  Result.Read := True;
  Result.Write := False;
  Result.Append := False;
  Result.Create := False;
  Result.CreateNew := False;
  Result.Truncate := False;
  Result.Share := [fsmRead];
end;

function FsOpenOptions_WriteTruncate: TFsOpenOptions;
begin
  Result.Read := False;
  Result.Write := True;
  Result.Append := False;
  Result.Create := True;
  Result.CreateNew := False;
  Result.Truncate := True;
  Result.Share := [];
end;

function FsOpenOptions_ReadWrite: TFsOpenOptions;
begin
  Result.Read := True;
  Result.Write := True;
  Result.Append := False;
  Result.Create := False;
  Result.CreateNew := False;
  Result.Truncate := False;
  Result.Share := [];
end;

function FsOpenOptions_WithShare(const Opt: TFsOpenOptions; AShare: TFsShareMode): TFsOpenOptions;
begin
  Result := Opt;
  Result.Share := AShare;
end;

function FsOpenOptions_ToFlags(const Opt: TFsOpenOptions): Integer;
begin
  Result := 0;

  // 读写模式
  if Opt.Read and Opt.Write then
    Result := O_RDWR
  else if Opt.Write then
    Result := O_WRONLY
  else
    Result := O_RDONLY;

  // 创建标志
  if Opt.Create then
    Result := Result or O_CREAT;
  if Opt.CreateNew then
    Result := Result or O_CREAT or O_EXCL;
  if Opt.Truncate then
    Result := Result or O_TRUNC;
  if Opt.Append then
    Result := Result or O_APPEND;
end;

end.
