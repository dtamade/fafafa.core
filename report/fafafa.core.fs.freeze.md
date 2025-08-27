# fafafa.core.fs 本轮范围与API冻结说明（2025-08-14）

## 目的
在本轮迭代中冻结对外行为与范围，专注稳定性、文档一致性与可交付收尾，避免需求蔓延与回归。

## 冻结对象（对外契约）
- 低层 API：fs_* 全家（open/close/read/write/unlink/rename/mkdir/rmdir/access/chmod/stat/fsync/realpath/flock/link/symlink/readlink/mkstemp/mkdtemp…）
- 高层接口：IFsFile（Open/Close/Read/Write/Seek/Tell/Size/Truncate/Flush/PRead/PWrite）
- 路径模块：Normalize/Resolve/ResolvePathEx/ToRelative/PathsEqual/IsSubPath/GetCommonPath 等
- 遍历：FsDefaultWalkOptions / WalkDir

## 行为基线（不改变）
- FS_UNIFIED_ERRORS：默认启用（文档与实现一致）
- ResolvePath：不触盘的绝对化/规范化
- ResolvePathEx：可选触盘（存在时调用 realpath）+ 可选跟随符号链接；失败回退
- Walk：回调式、稳定排序、PreFilter/PostFilter 分层；FollowSymlinks 默认 False

## 本轮不做
- 不新增/删除对外 API，不改签名，不改默认行为
- 不进行会改变语义的重构/优化
- 不引入环境敏感的强制性测试（长路径、symlink 仅条件化）

## 允许的工作
- 缺陷修复（不改变对外语义）
- 文档/注释纠偏
- 测试清洁化（稳定断言顺序、减少环境依赖）
- 构建与示例的最小修复（仅为可编可跑）

## 验收标准
- 全量单测通过；heaptrc 零泄漏
- 文档与实现一致（默认值、行为、示例）
- 示例可编可运行（允许保留明确标注的 TODO）
- 性能仅记录基线，不做优化；如有>±10% 回归仅报备

## 生效与退出
- 本冻结说明自 2025-08-14 起对本轮生效
- 完成“测试/文档/示例/记录”稳态后，待负责人同意可解冻进入下一轮功能工作

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）

