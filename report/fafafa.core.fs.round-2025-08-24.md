# fafafa.core.fs — 本轮进展（2025-08-24）

## 概览
- 已完成快速盘点：模块已较为完整，覆盖低层 API、路径工具、错误模型、高层文件对象、目录遍历与复制/移动树、临时文件/目录等
- 对齐竞品要点（Rust/Go/Java）：
  - 错误分类（FsErrorKind）与异常/无异常双语义（IFsFile/TFsFileNoExcept）
  - 路径规范化与“触盘/不触盘”解析（Resolve/ResolvePathEx/Canonicalize）
  - 目录遍历 WalkDir：支持 PreFilter/PostFilter、OnError 策略（Continue/SkipSubtree/Abort）、统计、是否跟随符号链接、环路防护（Windows 文件索引/Unix dev+ino）
  - 复制/移动（文件与目录树）具备覆盖、保留时间/权限、符号链接策略、根行为（Merge/Replace/Error）

## 已完成项
- 代码现状确认：
  - 低层（fafafa.core.fs + .windows/.unix.inc）：open/close/read/write/unlink/rename/link/symlink/readlink/flock/realpath/mkstemp/mkdtemp 等
  - 错误（fafafa.core.fs.errors）：统一错误码、系统错误映射、检查与分类辅助
  - 路径（fafafa.core.fs.path/.optimized）：Normalize/Resolve/ResolvePathEx/Canonicalize/PathsEqual/IsSubPath 等
  - 高层（fafafa.core.fs.highlevel）：IFsFile + 便捷读写、无异常封装、WalkDir/WALK 过滤/错误策略/统计、FsCopyFileEx/FsMoveFileEx、FsCopyTreeEx/FsMoveTreeEx
  - 其他：walkers 辅助类、mmap，异步最小实现（async.*）
- 测试现状：tests/fafafa.core.fs/* 覆盖广泛（walk、错误语义、symlink、longpath、copytree、preserve perms/times、errno 映射等）

## 问题与改进机会（高 ROI 候选）
1) 原子写入助手（FsAtomicWrite/WriteFileAtomic）
   - 典型语义：写到临时文件 + Flush + 原子 rename 替换；可选保留权限/时间；用于配置/日志/快照安全落盘
   - 复用现有 FsCopy/FsMove 语义与错误模型；小改动即可落地

2) 目录删除（RemoveTreeEx）一致化
   - 与 Copy/MoveTree 对齐的选项与策略（ErrorPolicy、FollowSymlinks、Stats、RootBehavior）
   - 安全默认：不跟随符号链接，支持 SkipSubtree

3) Windows 长路径健壮性再强化
   - 对齐 ToWindowsPath/ResolvePath 行为，必要时在低层 open/rename 等引入 \?\ 前缀策略（仅当长度越界且合法时）
   - 增补极限场景测试用例（已存在 longpath 测试，可扩展矩阵）

4) mmap/use-cases 补充测试
   - 为 mmap 单元添加基本读写/切片/边界测试，用于防回归

## 建议的下一轮交付（按优先级）
- P1: FsAtomicWrite 助手 + 单测（成功/覆盖/失败回滚）
- P1: RemoveTreeEx（策略/统计）+ 单测（错误策略矩阵、符号链接）
- P2: Windows 长路径补强（微调低层 + 扩展测试）
- P3: mmap 基础单测

## 风险与对策
- 平台差异：以单元测试的行为矩阵固化；Windows/Unix 用条件编译隔离
- 兼容性：新增 API 不破坏现有接口；默认行为与现状保持一致

## 下一步
- 待产品确认优先级后开工；本轮不改动现有代码，仅提交计划与报告

## 本轮落地补充（2025-08-25 更新）
- 新增能力：
  - WriteFileAtomic / WriteTextFileAtomic（同目录临时 + fs_replace 原子替换，默认 UTF-8）
  - RemoveTreeEx（FollowSymlinks + ErrorPolicy 策略，统计 FilesRemoved/DirsRemoved/Errors）
- 单测：
  - 新增 TTestCase_RemoveAndAtomic（Test_WriteFileAtomic_Basic、Test_RemoveTreeEx_Basic）
  - 修复：RemoveTreeEx 反向删除目录时容忍 IsNotFound（并发/重复路径容错）
- 构建/测试：
  - tests/fafafa.core.fs 全量通过（本轮新增用例通过）

## 后续待办
- 补充 RemoveTreeEx 测试矩阵：ErrorPolicy Continue/SkipSubtree；FollowSymlinks True/False
- WriteFileAtomic 回滚用例：目标被占用、临时目录不可写等
- P2：Windows 长路径 \?\ 前缀策略补强（低层统一入口 + 测试）




## 2025-08-25 更新
- 启用 Windows 长路径策略开关（FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH），范围仅影响 WinGetPathW 内部路径转换，短路径行为不变
- 新增长路径用例：rename + realpath（仍受环境变量 FAFAFA_TEST_WIN_LONGPATH=1 控制）
- 执行 tests/fafafa.core.fs/BuildOrTest.bat test：构建成功；用例执行中发现 4 个与 RemoveTreeEx 相关错误（Windows：目录符号链接删除/文件锁冲突）
- 计划：
  1) 在 fs_unlink（Windows）中识别“目录型符号链接”（reparse + directory），改用 RemoveDirectoryW 删除链接本体（不跟随）
  2) 完成 RemoveTreeEx 行为矩阵测试（Abort/Continue/SkipSubtree × FollowSymlinks），并修正与共享/锁相关的边界（优先不破坏既有 API）
