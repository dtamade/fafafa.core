# fafafa.core.fs 最佳实践（可引用分片）

## 路径与解析
- 使用 ResolvePath/NormalizePath/JoinPath/ToRelativePath；不要手拼分隔符或直接字符串比较
- 需要真实落盘路径才用 Canonicalize 或 ResolvePathEx(TouchDisk=True)
- 比较/子路径判断：先 Normalize，再 PathsEqual/IsSubPath

## WalkDir
- 性能：UseStreaming=True、Sort=False；精准设置 IncludeFiles/IncludeDirs
- 过滤：优先 PreFilter（避开多余 stat），其次 PostFilter
- 错误：提供 OnError（Continue/SkipSubtree/Abort），配合 Stats 计数
- Symlink：FollowSymlinks=True 自动启用 visited-set 防环

## 目录树 Copy/Move
- FsCopyTreeEx/FsMoveTreeEx：源/目标根统一 ResolvePath；相对路径用 ToRelativePath
- 遍历：IncludeFiles=True、IncludeDirs=False（只递归进入目录，不对目录节点回调）
- 覆盖：Overwrite=False 抛 EFsError；Overwrite=True 复制前若目标存在先 fs_unlink
- Symlink：默认不跟随（FollowSymlinks=False 时跳过链接本体与其目标，不复制）；必要时 FollowSymlinks=True 并依赖环路保护
- PreserveTimes/PreservePerms：best-effort（POSIX 有效，Windows 忽略）

## 文件级操作
- 原子写：WriteFileAtomic/WriteTextFileAtomic（同目录临时 + fs_replace）
- 移动：FsMoveFileEx 优先 fs_rename，跨卷回退 copy+unlink
- 覆盖：Overwrite=True 时尽量预 unlink，减少平台差异造成的失败

## 跨平台差异
- Windows：symlink 需要管理员或开发者模式；长路径建议启用相关策略
- POSIX：PreserveTimes/Perms 有效；注意 ACL/umask/挂载点

## 测试建议
- 正向：结构/内容一致
- 负向：Overwrite=False + 目标存在 → 抛错
- Symlink：Follow=True 无环验证；Windows 测试条件化（设置环境变量 FAFAFA_TEST_SYMLINK=1 或在管理员/开发者模式下运行）

## 测试开关速查（Windows/跨平台）
- Windows 符号链接（Symlink）
  - PowerShell:  $env:FAFAFA_TEST_SYMLINK="1"
  - CMD:        set FAFAFA_TEST_SYMLINK=1
  - 说明：需要管理员权限或启用“开发者模式”后方可创建 symlink
- Windows 长路径（>260 字符）
  - PowerShell:  $env:FAFAFA_TEST_WIN_LONGPATH="1"
  - CMD:        set FAFAFA_TEST_WIN_LONGPATH=1
  - 说明：需系统 LongPathsEnabled=True；且部分 API/第三方库可能不兼容 \?\ 前缀
- POSIX PreserveTimes/Perms 精度
  - 纳秒级 utimensat/futimens（若可用），否则回退微秒；断言应容忍 1–3s 浮动


## 组织与风格
- 回调统一用 of object，必要时小型适配器/类封装上下文
- 选项（Overwrite/Preserve*/FollowSymlinks）集中下沉到核心路径，避免分散逻辑
- 默认值在文档与注释中明确，避免“隐式行为”

