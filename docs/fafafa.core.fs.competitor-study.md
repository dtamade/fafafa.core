# fafafa.core.fs 竞品调研（Rust/Go/Java）

## 结论速览
- API 外观与职责划分基本对齐现代实践：纯函数 + 结构体/接口（TFsFile/IFsFile）。
- 路径语义：当前 Resolve/Normalize 行为与 Go filepath.Clean/Abs 接近；可增补 ResolvePathEx 以覆盖 realpath 触盘场景。
- 错误模型：已具备统一错误码与分类（FsErrorKind/IsXXX）。建议高层主要依赖分类，避免平台细节。
- 可选增强：Walk 过滤器与统计已具备，后续可按 Go/Java NIO 借鉴更多策略（如 FollowLinks 行为矩阵已实现）。

## Rust std::fs / tokio::fs
- 同步 std::fs：File、OpenOptions、read、write、metadata、read_dir、remove、rename。
- 错误处理：Result<T, Error>；ErrorKind 提供分类（NotFound、PermissionDenied、AlreadyExists…）。
- 异步 tokio::fs：API 形态相近，内部线程池 offloading。
- 启示：
  - 我们的 IFsFile/NoExcept 已提供两种语义（异常 / 负码）；与 Rust 的 Result 思路一致。
  - 错误分类 TFsErrorKind 已具备。

## Go os + io/fs + path/filepath
- 接口最小化：io/fs.FS 只需 Open；其余通过可选接口扩展（StatFS、ReadFileFS…).
- filepath 清理/拼接/相对化强；os 提供 ReadFile/WriteFile/ReadDir/Stat 等便利函数。
- 启示：
  - 我们的高层提供 FileExists/DirectoryExists、WalkDir（带过滤器/统计），与 Go 的便利函数、Walk 模式一致。
  - 建议：保留小而美核心；更多扩展走接口化（已在 IFsFile/TFsFile 落地）。

## Java NIO (Files/Path/Paths/WatchService)
- Files 提供丰富静态方法：exists、copy、move、walk、readAllBytes、lines 等。
- Path 对象抽象路径；支持符号链接策略枚举，文件属性视图。
- WatchService 目录监控。
- 启示：
  - 我们的 Walk 已支持 FollowLinks 控制与最大深度；后续可评估 Watch（跨平台差异较大，暂缓）。

## 落地建议（与现状对齐）
1) 路径 API：新增 ResolvePathEx(FollowLinks, TouchDisk)；测试覆盖存在/不存在、符号链接。
2) 错误分类：面向外部仅暴露 FsErrorKind/Is* 帮助；内部保留 LastFsErrorCode（Windows）。
3) Walk：保持过滤器/统计的零拷贝实现；提供流式迭代与收集两种模式（已具备）。
4) 文档：在 docs/fafafa.core.fs.md 增加“对齐现代库”的章节，说明语义取舍。

