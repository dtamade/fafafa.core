# fafafa.core.fs API Inventory & Light Deprecation Map (2025-08-14)

目标：列出对外 API 并标注潜在重叠/别名建议。本轮冻结期仅文档化，不改代码。

## 1) 低层 fs_*（门面单元：src/fafafa.core.fs.pas）

- 句柄/常量
  - type TfsFile = THandle
  - 常量：O_RDONLY/O_WRONLY/O_RDWR/O_APPEND/O_CREAT/O_EXCL/O_TRUNC
  - 常量：S_IFMT/S_IFDIR/S_IFREG/S_IFLNK；权限位 S_IRWXU/G/O 等
  - 常量：SEEK_SET/SEEK_CUR/SEEK_END；F_OK/R_OK/W_OK/X_OK；LOCK_*

- 基础 I/O
  - fs_open(path; flags; mode): TfsFile
  - fs_close(f): Integer
  - fs_read(f; buf; len; offset): Integer
  - fs_write(f; buf; len; offset): Integer
  - fs_seek(f; offset; whence): Int64
  - fs_tell(f): Int64
  - fs_ftruncate(f; newSize): Integer

- 文件/目录操作
  - fs_unlink(path), fs_rename(old,new), fs_copyfile(src,dst,flags)
  - fs_replace(src,dst) 备注：跨卷自动回退 copy+原子覆盖
  - fs_mkdir(path, mode), fs_rmdir(path)
  - fs_access(path, mode)

- 属性/时间/同步
  - fs_stat(path, out stat), fs_lstat(path, out stat), fs_fstat(f, out stat)
  - fs_chmod(path, mode), fs_fchmod(f, mode)
  - fs_utime(path, atime, mtime), fs_futime(f, atime, mtime)
  - fs_fsync(f)

- 链接/真实路径
  - fs_link(old,new), fs_symlink(target, link)
  - fs_readlink(path, buf, size)
  - fs_realpath(path, buf, size)
  - 便捷：fs_realpath_s(path, out resolved), fs_readlink_s(path, out target)

- 枚举/遍历
  - fs_scandir(path, var entries: TStringList)
  - fs_scandir_each(path, onEntry: TfsScandirEachProc)

- 临时
  - fs_mkdtemp(template): string
  - fs_mkstemp(template): TfsFile

- 工具
  - IsValidHandle(h): Boolean

重叠/别名建议（仅文档化）：
- realpath/readlink 的 _s 便捷版优先用于高层文档，缓冲区版保留给性能/低层场景
- scandir_each 推荐替代旧的 scandir（减少中间集合），但两者并存

## 2) 高层（src/fafafa.core.fs.highlevel.pas）

- IFsFile（接口优先，便于依赖注入）
  - 生命周期：Open(path, mode); Close; IsOpen
  - 定位与大小：Seek/Tell/Size/Truncate
  - 同步：Flush
  - I/O：Read/Write；PRead/PWrite（默认基于 Seek+Read/Write 实现）
  - 工厂：NewFsFile()

- Walk API
  - TFsWalkOptions：FollowSymlinks/IncludeFiles/IncludeDirs/MaxDepth/PreFilter/PostFilter/Stats
  - FsDefaultWalkOptions(): 默认不跟随 symlink、包含文件与目录、深度无限
  - WalkDir(root, options, callback): Integer（回调返回 True 继续，False 早停）
  - TFsDirEntType：fsDETUnknown/fsDETFile/fsDETDir/fsDETSymlink（基础类型）

建议：
- 高层文档使用 WalkDir + 选项的推荐姿势，弱化直接 fs_scandir 的使用

## 3) 路径（src/fafafa.core.fs.path.pas）

- 解析/构造：ParsePath, JoinPath, NormalizePath, ResolvePath, ResolvePathEx
- 查询：IsAbsolutePath, IsRelativePath, PathExists, GetPathType
- 提取：ExtractDirectory/FileName/BaseName/FileExtension/Drive
- 转换：ToAbsolutePath/ToRelativePath/ToUnixPath/ToWindowsPath/ToNativePath
- 比较：PathsEqual, IsSubPath, GetCommonPath, FindCommonPrefix
- 操作：ChangeExtension, AppendPath, GetParentPath, GetPathDepth
- 特殊路径：GetCurrentDirectory, GetTempDirectory, GetHomeDirectory, GetExecutableDirectory
- 验证/净化：IsValidPath, IsValidFileName, SanitizePath, SanitizeFileName
- 枚举：EnumeratePathComponents

建议：
- ResolvePath 保持“不触盘”；ResolvePathEx 提供“可触盘+可跟随”的真实路径，失败回退
- 文档中给出选择矩阵，避免误用

## 4) 错误模型与条件化测试约定

- FS_UNIFIED_ERRORS：默认启用；推荐业务仅依赖 FsErrorKind 分类
- 条件化测试
  - Windows 长路径：FAFAFA_TEST_WIN_LONGPATH=1
  - Symlink：Unix 默认开；Windows 需 FAFAFA_TEST_SYMLINK=1

## 5) 去重/弃用候选（仅建议，冻结期不改）
- 文档层推荐 _s 便捷函数优先；缓冲区版保留以兼容/性能
- scandir_each 优先；scandir 逐步弱化文档露出
- 若未来解冻：考虑统一 PathExists/Resolve/Stat 的“可触盘/不可触盘”选项风格

— 仅供本轮归档与对齐，未做代码变更

