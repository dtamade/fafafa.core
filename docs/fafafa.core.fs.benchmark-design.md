# fafafa.core.fs 竞品对照与接口基准（Rust / Go / Java）

最后更新：2025-08-11

目标：对照 Rust std::fs/std::path、Go os/filepath、Java NIO Files/Path 的公共能力、错误模型与路径行为，复核我们模块的接口设计与差距，给出最小增量改进建议。

---

## 1. 能力地图（核心操作）
- Rust std::fs
  - File::open/create/options；read/write/seek/sync；metadata/stat；remove_file/rename/create_dir/remove_dir；copy；symlink/hard_link（平台差异）；canonicalize(realpath)；read_to_string/read/write 等便利函数。
  - 错误：Result<T, io::Error>，包含 ErrorKind（NotFound/PermissionDenied/AlreadyExists/…）。
- Go os + filepath
  - os.Open/Create/Chmod/Chtimes/Stat/Remove/Rename/Mkdir/ReadDir/Link/Symlink；os.ReadFile/WriteFile；filepath.Clean/Abs/EvalSymlinks/WalkDir。
  - 错误：error 接口，常见的 os.IsNotExist/IsPermission 判定辅助。
- Java NIO (Files/Path)
  - Files.copy/move/delete/createDirectories/createTempFile/Dir；readAllBytes/readAllLines/write；isRegularFile/exists；isSymbolicLink/readSymbolicLink；walk；newByteChannel；size；getAttribute；setAttribute；mismatch。
  - 错误：抛出受检异常（IOException 等）；有选项控制 FOLLOW_LINKS。

我们现状：
- 低层 fs_*：open/close/read/write/unlink/rename/copyfile/mkdir/rmdir/scandir/stat/lstat/fstat/ftruncate/seek/tell/chmod/fchmod/utime/futime/fsync/access/link/symlink/readlink/flock/realpath/mkdtemp/mkstemp。
- 高层/路径：TFsFile（读写/Flush/Truncate/大小/位置）、ReadTextFile/WriteTextFile/ReadBinaryFile/WriteBinaryFile；路径解析/规范化/转换/比较/安全校验。

结论：覆盖度高，具备现代库常见能力。缺少点：
- 目录遍历的统一高层 Walk/WalkDir API（我们有 fs_scandir 与路径工具，可考虑门面 Walk）。
- 错误翻译/分类帮助（类似 Rust ErrorKind/Go 判定），便于调用方分支处理。
- 选项化语义（FOLLOW_SYMLINKS 等）目前分散在 lstat/stat；可通过高层函数暴露统一语义。

---

## 2. 错误模型基准
- Rust：io::ErrorKind 分类清晰；Go：os.IsNotExist/IsPermission；Java：受检异常层级。
- 我们：低层返回负错误码（-errno 或 -GetLastError），Windows 侧保留 LastFsErrorCode 便于查询。

建议：
- 在 src/fafafa.core.fs.errors.pas 提供帮助：
  - FsErrorKind(ErrorCode): (NotFound, Permission, Exists, NameTooLong, NotSupported, IOError, …)
  - IsNotFound/IsPermission/IsExists 等判定。
- 保持低层负值语义不变，高层根据需要转换异常（可选）。

---

## 3. 路径行为基准
- 规范化/绝对化：Rust canonicalize，Go filepath.Clean/Abs/EvalSymlinks，Java Files.realPath（follow links 可配置）。
- 分隔符：跨平台分隔处理与大小写敏感差异；Windows 驱动器/UNC；符号链接解析策略。

建议：
- 在 fs.path 增补/核对：
  - ResolvePath/ToRelative/IsSubPath/FindCommonPrefix 的 Windows 大小写与分隔统一策略；
  - 明确文档：是否大小写不敏感比较在 Windows 上启用，路径标准化的规则；
  - 提供 WalkDir 高层接口（可在 fs.highlevel 或 fs.path 中新增）。

---

## 4. API 取舍与最小改进
- 新增：
  - WalkDir(root, options, cb) 或返回迭代器（延迟遍历，过滤/深度/跟随符号链接选项）。
  - fs.errors 帮助函数族（ErrorKind 判定）。
- 整理：
  - 文档修正 Darwin 实现描述（当前仓库仅有 windows/unix.inc）。
  - 移除 library 单元中的 {$CODEPAGE UTF8}（与规范一致）。

---

## 5. 验收标准
- 覆盖：新增/调整 API 的测试覆盖 100%，含异常路径。
- 性能：WalkDir 对比 FreePascal 自带 FindFirst/FindNext 的开销不明显劣化；大目录下可控。
- 文档：docs/fafafa.core.fs.md 更新路径语义差异与错误模型帮助。

— 以上为第一轮基线，后续可按 IFsFile 接口化、异步整合等方向演进。

