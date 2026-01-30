# fafafa.core.fs 竞品模型调研与对齐建议（Rust / Go / Java）

最后更新：2025-08-12 负责人：Augment Agent

## 目的与范围
- 明确现代 FS/Path/遍历 API 的主流设计与行为差异
- 形成对齐策略：错误模型、路径操作、目录遍历、临时文件/真实路径
- 指导后续测试补齐与 API 迭代（Walk/WalkDir、IFsFile 草案）

---

## 概览对照

### Rust（std::fs / std::path）
- 文件：File、OpenOptions（builder 模式）；read、write 走 io::Read/Write trait
- 路径：Path/PathBuf（强类型），join、canonicalize、is_absolute 等
- 目录：read_dir（迭代器），第三方 walkdir 提供递归遍历、过滤
- 错误：Result<T, io::Error>，ErrorKind（NotFound、PermissionDenied、AlreadyExists…）
- 符号链接：symlink_metadata（不跟随）、metadata（跟随）；read_link

### Go（os + path/filepath）
- 文件：os.OpenFile、os.ReadFile/os.WriteFile、Chmod/Chown、MkdirAll
- 路径：filepath.Clean、Rel、EvalSymlinks、VolumeName（Windows 驱动器）
- 目录：WalkDir（自 1.16），支持 Skip、错误处理、性能更优；历史 Walk 也常见
- 错误：error + errors.Is(err, fs.ErrNotExist/Permission/Exist…)
- 符号链接：os.Symlink、Lstat（不跟随）、EvalSymlinks 控制

### Java（NIO Files/Path）
- 文件：Files.newByteChannel、readAllBytes、createTempFile/Directory
- 路径：Path.resolve/normalize/relativize；FileSystem 提供平台语义
- 目录：Files.walk / walkFileTree（FileVisitor + 选项，如 FOLLOW_LINKS、最大深度）
- 错误：受检异常 IOException 族，语义清晰
- 符号链接：isSymbolicLink、readSymbolicLink、copy/move 对链接策略可配置

---

## 关键主题与建议

### 1) 错误模型（Error Model）
- 竞品共识：
  - 按平台原生错误（errno / GetLastError）映射到抽象层级（ErrorKind / fs.ErrXxx / IOException 子类）
  - 高层推荐以“错误种类”进行判定分支
- 现状：
  - 低层 fs_* 返回“系统错误码的负值”（Windows: -GetLastError，Unix: -errno）
  - 高层提供 TFsErrorKind 与 FsErrorKind/IsNotFound 等辅助；FsLowLevelReturnsUnified 支持编译期开关
- 建议：
  - 保持低层“保真负错误码”的能力 + 文档强制推荐以 FsErrorKind 判定
  - 维持统一开关（FS_UNIFIED_ERRORS），不默认开启；新增测试确保两模式一致性
  - 文档强化“如何从 fs_open 失败获取统一错误”：GetSavedFsErrorCode() → SystemErrorToFsError()

### 2) 路径 API（Normalize / Resolve / Relativize / 比较）
- 跨平台要点：
  - Windows：大小写不敏感；分隔符 \ 与 / 兼容；驱动器（C:）、UNC（\\server\share）
  - Unix：大小写敏感；仅 /
- 竞品行为：
  - Go filepath.Clean ≈ 规范化，Rel 处理相对路径，EvalSymlinks 可控
  - Rust canonicalize 走真实路径（可能触磁盘与链接）、Path 的 join/normalize 相对简单
  - Java Path.normalize/resolve/relativize 明确规则
- 现状：
  - 已提供 Normalize/Resolve/ToRelative/IsSubPath/GetCommonPath/PathsEqual
- 建议：
  - 明确各函数是否触磁盘（Normalize/Resolve 不触磁盘，realpath 触磁盘）
  - PathsEqual/IsSubPath：Windows 使用大小写不敏感比较、统一分隔符；Unix 严区分
  - 文档补充 UNC/驱动器与边界（根路径、相对路径越界）

### 3) 遍历 API（Walk/WalkDir）
- 竞品模式：
  - Go WalkDir：回调式、DirEntry 提供 IsDir/Type、支持 Skip、错误回传
  - Java walkFileTree：访问者接口 + 选项（FOLLOW_LINKS、最大深度、错误处理）
  - Rust 主库 read_dir，递归常用第三方 walkdir（过滤器与 follow_links）
- 建议：提供高层 Walk/WalkDir（不破坏现有）：
  - 形态：回调 + 选项记录（是否跟随符号链接、最大深度、过滤器、错误策略继续/跳过/终止）
  - 产物：DirEntry（Name、Path、Type、Size/Stat 可懒取）、WalkResult（错误码/分类）
  - 错误：对外始终统一 TFsErrorCode（与文档一致），内部保留系统码用于诊断

### 4) 临时与真实路径（mkstemp/mkdtemp/realpath）
- 竞品：
  - Rust：tempfile（第三方）常用；canonicalize 返回绝对真实路径
  - Go：os.MkdirTemp、os.CreateTemp；EvalSymlinks 获取真实路径
  - Java：Files.createTempFile/Directory；toRealPath
- 建议：
  - fs_mkstemp/fs_mkdtemp：严格模板校验（XXXXXX）、缓冲区/长度边界测试
  - fs_realpath：明确缓冲区要求、遇到不存在路径的返回语义（负错误码→ErrorKind）

---

## 对齐落地清单（行动方案）

1) Walk/WalkDir 设计与实现（高层）
- 选项（TWalkOptions）：
  - FollowSymlinks: Boolean
  - MaxDepth: Integer (<=0 表示不限)
  - Filter: function(const Entry): Boolean
  - OnError: (ErrorCode: Integer; const Path: string): (Continue|Skip|Abort)
- 回调：OnEntry(const Entry)
- 统一错误：回调期间/结束时返回 TFsErrorCode（负值），确保业务判定稳定

2) 路径 API 边界测试矩阵（Windows/Unix）
- Normalize：重复分隔符、.、..、尾随分隔符、根路径
- Resolve：相对 → 绝对；不触磁盘（仅字符串规则）
- ToRelative：跨盘（Windows）、从 UNC 到本地的相对失败语义
- IsSubPath：大小写、分隔符、符号链接（不解引用）
- PathsEqual：大小写/分隔符合并
- realpath：不存在、权限、符号链接环
- mkstemp/mkdtemp：模板不合法/长度不足、冲突重试

3) 错误一致性验证
- FsLowLevelReturnsUnified On/Off 两模式全量测试
- FsErrorKind 分类覆盖 NotFound/Permission/Exists/Invalid/IO/DiskFull/Unknown
- fs_open 失败路径：GetSavedFsErrorCode → SystemErrorToFsError → FsErrorKind

4) 文档补充
- docs/fafafa.core.fs.md 更新：
  - 明确各 API 是否触磁盘、平台差异与边界
  - Walk/WalkDir 选项与错误策略
  - Windows 驱动器/UNC 特殊说明

---

## 与当前实现的映射
- 低层 fs_*：继续返回系统负错误码；保留统一开关
- 错误辅助（已具备）：SystemErrorToFsError、FsErrorKind/IsNotFound/IsPermission/IsExists
- 路径模块：加强平台分支（Windows 不区分大小写、UNC/驱动器处理）、补充测试
- 遍历：新增 Walk/WalkDir（高层，不破坏现有 fs_scandir/测试）

---

## 建议的 Walk/WalkDir 草案（草拟接口）

- 面向过程风格（简单引入）：

```
// 返回 <0 表示错误（TFsErrorCode 负值），0 表示正常结束
function fs_walk(const ARoot: string; const AOptions: TWalkOptions; AOnEntry: TWalkEntryProc): Integer;
```

- 面向接口风格（便于扩展）：

```
type
  IFsWalker = interface
    procedure SetOptions(const AOptions: TWalkOptions);
    function Walk(const ARoot: string; const AOnEntry: TWalkEntryProc): Integer;
  end;
```

说明：两者可共存；高层对外统一 TFsErrorCode，内部保留系统错误用于记录。

---

## 里程碑与优先级
- P0：调研（本文件）、测试环境稳定（已完成）
- P1：路径 API 边界测试补齐（不改行为的小步修正）
- P2：Walk/WalkDir 设计与测试矩阵（先文档与测试，再实现）
- P3：IFsFile 接口草案与迁移策略

---

## 参考与注记
- Rust: std::fs、std::path；常用 walkdir、tempfile
- Go: os、path/filepath；WalkDir/Rel/Clean/EvalSymlinks
- Java: java.nio.file.*（Files/Path/FileVisitor）
- 我们已具备的优势：
  - 低层保真 + 高层统一的双轨错误模型
  - 路径 API 基础已齐备，增量测试即可提升质量
  - 平台实现分发（windows/unix.inc）清晰

