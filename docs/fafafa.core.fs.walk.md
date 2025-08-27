# fafafa.core.fs WalkDir 高层 API

本文档描述 WalkDir 的接口、选项与行为，并提供使用示例。

## 1. API 概览

类型：
- TFsWalkOptions
  - FollowSymlinks: Boolean
  - IncludeFiles: Boolean
  - IncludeDirs: Boolean
  - MaxDepth: Integer （包含根，<0 表示无限）
- TFsWalkCallback = function(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean of object

函数：
- function FsDefaultWalkOptions: TFsWalkOptions;
- function WalkDir(const aRoot: string; const aOptions: TFsWalkOptions; aCallback: TFsWalkCallback): Integer;

返回值：
- 0 表示成功
- 负值为错误码（统一映射为 TFsErrorCode，便于识别：如 -2=NotFound，-3=AccessDenied，-5=InvalidPath 等）

## 2. 行为约定
- 遍历采用深度优先，使用 fs_scandir 获取目录内容，并进行排序，保证跨平台稳定输出顺序
- 回调触发：
  - 根为目录：如 IncludeDirs=True，会以 depth=0 回调根目录
  - 子项：目录或文件在进入时各触发一次回调；目录在回调后若未早停会递归进入
- FollowSymlinks 控制选择 fs_stat（跟随）或 fs_lstat（不跟随）
- IncludeFiles/IncludeDirs 控制回调对象类型
- MaxDepth 控制递归深度（包含根），<0 表示无限
- 回调返回 False 时将早停并返回 0（视作非错误的停止）
- 错误码与系统错误的关系：WalkDir 内部将底层系统错误统一为 TFsErrorCode，调用方无需直接处理系统错误码。
- 构建模式影响：无。无论是否定义 FS_UNIFIED_ERRORS，WalkDir 对外始终返回 TFsErrorCode 负值（已在高层守护）。更多细节见“错误模型/构建开关”。
- 目录回调行为：为避免重复，目录仅在进入其递归遍历时回调一次（depth 对应实际层级）。
- 根路径规范化（ResolvePath）：WalkDir 对传入的根路径进行规范化解析（不触磁盘的绝对化/规范化），确保遍历起点稳定；若路径无效/不存在，立即返回统一错误码。
- 符号链接环路风险：当 FollowSymlinks=True 时，若文件系统存在环路，深度优先遍历可能导致无限递归。建议合理设置 MaxDepth 作为保护，或关闭 FollowSymlinks。
- 防环（FOLLOW_LINKS=True）
  - 自本轮起，WalkDir 在 FollowSymlinks=True 时内置“环路检测”：
    - 目录递归前维护已访问集合（优先 Dev+Ino 作为键，退化使用 realpath）
    - 命中已访问则跳过递归，避免自环/小环/父环造成的无限递归
    - 与 MaxDepth 配合：MaxDepth 仍然生效；防环只在 FollowSymlinks=True 时启用

### 性能提示
- FollowSymlinks=True 时才启用 visited-set 防环；默认 False 为零开销
- 充分利用 PreFilter 在未 stat 之前尽早排除不必要的子树，减少系统调用与递归
- PostFilter 只影响回调是否触发，不阻止对子目录的递归；若需彻底跳过子树，请用 PreFilter
- 避免在热路径频繁调用 realpath（触盘）；必要时在上层做少量缓存
- Sort=False（默认）避免 O(n log n) 排序开销；如需稳定顺序再开启
- MaxDepth 适当限制深度可显著降低成本，尤其在大目录树与跟随符号链接时
- Windows 上杀毒/索引服务会影响 I/O 时延；基准测试建议在静音环境下进行
- UseStreaming 可降低一次性内存占用，但在有稳定排序/汇总需求时需权衡


- Windows 上 X_OK 语义：Windows 的 fs_access 对 X_OK 仅能近似判断，可执行语义受扩展名/PE 头/策略影响。建议结合 fs_stat 判断对象是否为目录（代表“可进入”），或通过扩展名/额外验证逻辑判定可执行性。

### 错误模型与统一返回
- 低层可能返回系统负错误码（-GetLastError / -errno），WalkDir 内部统一转换为 TFsErrorCode 负值；调用方可用 FsErrorKind(aResult) 分类。
- fs_open 等失败后如需获取统一码：Windows 可 GetSavedFsErrorCode() → SystemErrorToFsError()。

### 符号链接策略（Unix）
- FollowSymlinks=False：符号链接作为普通条目回调，不进入其目标。
- FollowSymlinks=True：进入符号链接指向的目录；建议具备“环检测”（inode+dev 或已访问路径集合）保护。

### 选项边界
- IncludeFiles=False 且 IncludeDirs=False：不会回调任何项，但遍历过程会快速结束并返回 0。
- MaxDepth：0=仅根，1=根的直接子项，<=0 表示不限制。
- OnError 错误策略（新增）：
  - 枚举：`TFsWalkErrorAction = (weaContinue, weaSkipSubtree, weaAbort)`
  - 回调：`TFsWalkOnError = function(const Path: string; Error: Integer; Depth: Integer): TFsWalkErrorAction of object;`
  - 语义：
    - weaContinue：忽略该错误并继续；若根路径无效，整体等价空遍历（返回 0）
    - weaSkipSubtree：跳过当前子树，继续同层
    - weaAbort：立即返回统一负错误码
  - 默认行为（OnError=nil）：保持旧语义；根路径无效时直接返回负统一错误码
  - 统计：若提供 `Stats` 指针，发生错误时 `Stats.Errors` 将递增




## 3. FAQ（常见问题）

- MaxDepth 与 FollowSymlinks 应如何组合？
  - 建议在 FollowSymlinks=True 时，设置 MaxDepth 为有限值（如 16 或 32）以避免环导致的深度爆炸。
  - 若必须不限深（MaxDepth<=0），务必启用环检测（通过 inode+dev 或已访问路径集）并在文档提示可能的性能影响。

- WalkDir 是否会改变返回值语义受 FS_UNIFIED_ERRORS 影响？
  - 不会。无论是否定义 FS_UNIFIED_ERRORS，WalkDir 始终对外返回 TFsErrorCode 的负值（统一错误）。

- 根路径不存在或者无权限如何处理？
  - 立即返回统一错误码；回调不会被调用。

- IncludeFiles 与 IncludeDirs 可以同时为 False 吗？
  - 可以，此时不会回调任何条目，遍历会快速结束并返回 0。

- 遍历顺序是否稳定？
  - 默认按文件系统原始顺序。若需要稳定排序，建议在选项中增加 Sort=True（默认 False），内部按名称排序，成本为 O(n log n)。

- 符号链接是否总是可用？
  - Windows 上符号链接创建/解析受系统策略与权限控制，示例与测试在 Windows 默认跳过符号链接用例；Unix 上按 FollowSymlinks 控制。

- 是否会触磁盘？
  - WalkDir 必然触磁盘（枚举/Stat）。路径规范化（ResolvePath）不触盘，realpath 触盘。


## 3. 使用示例

示例：统计文件数量（对象方法回调）

class helper
  TCounter = class
  public
    Count: Integer;
    function Visit(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
  end;
end;

function TCounter.Visit(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  if (AStat.Mode and S_IFMT) <> S_IFDIR then
    Inc(Count);
  Result := True;
end;

procedure Run;
var
  Opts: TFsWalkOptions;
  C: TCounter;
begin
  C := TCounter.Create;
  try
    Opts := FsDefaultWalkOptions;
    Opts.IncludeDirs := False;
    if WalkDir('some_root', Opts, @C.Visit) <> 0 then
      raise Exception.Create('WalkDir failed');
  finally
    C.Free;
  end;
end;

## 5. 实战建议与常见场景
- 系统/仓库目录权限问题：遍历如 .git、System32 等目录时，可能返回 AccessDenied/InvalidPath 等错误码。建议：
  - 选择“干净”的根目录进行遍历，或
  - 在回调中按需过滤（例如遇到 .git、node_modules 直接忽略或早停），或
  - 在进入 WalkDir 前根据 FsErrorKind() 对返回值分类处理。
- 过滤策略：当前版本不内建过滤器；可通过回调中分析 APath/AStat 自行实现（如跳过过深目录、跳过隐藏文件）。
- 性能提示：目录项排序保证跨平台稳定输出，如需极致性能可在自定义版本中关闭排序（需修改源码）。

## 4. 常见问题
- 错误处理如何进行？
  - WalkDir 在 stat/scandir 失败时会返回统一的 TFsErrorCode 负值；回调返回 False 仅作为早停且返回 0

- 如何使用嵌套函数作为回调？
  - 当前签名使用 of object，建议使用对象方法（示例见上）；嵌套函数可通过包装类适配
- 如何跳过某些目录？
  - 在回调中检测 APath 或 AStat 后直接返回 True 继续；若要完全不回调某些目录，可在回调里忽略它们，同时 WalkDir 仍会递归进入；后续版本将考虑提供过滤器以跳过递归
- 错误处理如何进行？
  - WalkDir 在 stat/scandir失败时返回底层负错误码；回调返回 False 仅作为早停且返回 0



## 6. 附录：TFsErrorCode 与 FsErrorKind 参考

- TFsErrorCode（负值为错误，0 为成功）：
  - 0 = FS_SUCCESS
  - -1 = FS_ERROR_INVALID_HANDLE
  - -2 = FS_ERROR_FILE_NOT_FOUND
  - -3 = FS_ERROR_ACCESS_DENIED
  - -4 = FS_ERROR_DISK_FULL
  - -5 = FS_ERROR_INVALID_PATH
  - -6 = FS_ERROR_FILE_EXISTS
  - -7 = FS_ERROR_DIRECTORY_NOT_EMPTY
  - -8 = FS_ERROR_INVALID_PARAMETER
  - -9 = FS_ERROR_IO_ERROR
  - -10 = FS_ERROR_PERMISSION_DENIED
  - 其他 = FS_ERROR_UNKNOWN（-999 作为兜底）

- FsErrorKind（错误分类，用于快速分支处理）：
  - fekNone          → aResult >= 0（成功）
  - fekNotFound      → FS_ERROR_FILE_NOT_FOUND
  - fekPermission    → FS_ERROR_ACCESS_DENIED, FS_ERROR_PERMISSION_DENIED
  - fekExists        → FS_ERROR_FILE_EXISTS
  - fekInvalid       → FS_ERROR_INVALID_PATH, FS_ERROR_INVALID_PARAMETER, FS_ERROR_INVALID_HANDLE
  - fekDiskFull      → FS_ERROR_DISK_FULL
  - fekIO            → FS_ERROR_IO_ERROR
  - fekUnknown       → 其他未分类错误

使用建议：
- 在调用 WalkDir 后，若返回值 < 0，可先用 FsErrorKind(aResult) 做分类；对 Permission/Invalid 等可选择忽略或降级日志；对 DiskFull/IO 则建议立即反馈或中止。
- 需要原始系统错误码时，可在异常语境下使用 EFsError.SystemErrorCode，或在 Windows 下调用 GetSavedFsErrorCode（用于 fs_open 等立即失败的场景）。
