# fafafa.core.fs 统一错误码对照表

本文档列出统一负错误码（TFsErrorCode）与各平台系统错误码的典型映射，便于排障。

## 统一错误码（TFsErrorCode）

- 0: FS_SUCCESS
- -1: FS_ERROR_INVALID_HANDLE
- -2: FS_ERROR_FILE_NOT_FOUND
- -3: FS_ERROR_ACCESS_DENIED
- -4: FS_ERROR_DISK_FULL
- -5: FS_ERROR_INVALID_PATH
- -6: FS_ERROR_FILE_EXISTS
- -7: FS_ERROR_DIRECTORY_NOT_EMPTY
- -8: FS_ERROR_INVALID_PARAMETER
- -9: FS_ERROR_IO_ERROR
- -10: FS_ERROR_PERMISSION_DENIED
- -999: FS_ERROR_UNKNOWN

## Windows 常见映射（示例）

- FS_ERROR_FILE_NOT_FOUND: ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND
- FS_ERROR_ACCESS_DENIED: ERROR_ACCESS_DENIED
- FS_ERROR_DISK_FULL: ERROR_DISK_FULL, ERROR_HANDLE_DISK_FULL
- FS_ERROR_INVALID_PATH: ERROR_INVALID_NAME, ERROR_BAD_PATHNAME
- FS_ERROR_FILE_EXISTS: ERROR_FILE_EXISTS, ERROR_ALREADY_EXISTS
- FS_ERROR_DIRECTORY_NOT_EMPTY: ERROR_DIR_NOT_EMPTY
- FS_ERROR_INVALID_PARAMETER: ERROR_INVALID_PARAMETER, ERROR_INVALID_HANDLE
- 其它: 映射为 FS_ERROR_UNKNOWN

备注：Windows 场景下 GetSavedFsErrorCode() 会在低层捕获最近系统错误码，然后用 SystemErrorToFsError 统一为 TFsErrorCode。

## Unix 常见映射（示例）

- FS_SUCCESS: 0
- FS_ERROR_FILE_NOT_FOUND: ENOENT
- FS_ERROR_ACCESS_DENIED: EACCES
- FS_ERROR_DISK_FULL: ENOSPC
- FS_ERROR_INVALID_PARAMETER: EINVAL
- FS_ERROR_FILE_EXISTS: EEXIST
- FS_ERROR_DIRECTORY_NOT_EMPTY: ENOTEMPTY
- FS_ERROR_PERMISSION_DENIED: EPERM
- FS_ERROR_IO_ERROR: EIO
- 其它: 映射为 FS_ERROR_UNKNOWN

## 分类辅助（高层）

- FsErrorKind(aErrorCode): 返回 NotFound/Permission/Exists/Invalid/DiskFull/IO/Unknown
- IsNotFound/IsPermission/IsExists：便捷判断

## 使用建议

- 低层：返回统一负错误码；调用方判断 res < 0 即错误
- 高层：抛出 EFsError（携带统一错误码与系统错误码），或提供 NoExcept 版本返回统一错误码
- 日志：建议输出统一错误码及其字符串（FsErrorToString）+ 系统错误码，便于跨平台排障



## 句柄型 API 与线程局部错误码
- 句柄型 API（fs_open）：失败统一返回 INVALID_HANDLE_VALUE；错误码通过线程局部 fs_errno() 获取
- FS_UNIFIED_ERRORS=On（默认）：fs_errno 返回统一负错误码（-FS_ERROR_*）
- FS_UNIFIED_ERRORS=Off：fs_errno 返回负系统错误码（Windows: -GetLastError；Unix: -errno）
- 建议：在业务侧以 FsErrorKind(Err) 分类，不直接依赖数值
