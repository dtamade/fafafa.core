// Windows特有常量定义

threadvar
  LastFsErrorCode: DWORD;  // 线程本地：保存最后的文件系统错误代码

const
  SYMBOLIC_LINK_FLAG_DIRECTORY = $1;
  IO_REPARSE_TAG_SYMLINK = $A000000C;
  FSCTL_GET_REPARSE_POINT = $900A8;
  MAXIMUM_REPARSE_DATA_BUFFER_SIZE = 16384;
  FILE_FLAG_OPEN_REPARSE_POINT = $00200000;
  ERROR_NOT_A_REPARSE_POINT = 4390;

// Windows API函数声明
function CreateHardLinkW(lpFileName, lpExistingFileName: PWideChar; lpSecurityAttributes: Pointer): BOOL; stdcall; external 'kernel32.dll';
function CreateSymbolicLinkW(lpSymlinkFileName, lpTargetFileName: PWideChar; dwFlags: DWORD): BOOL; stdcall; external 'kernel32.dll';
function DeviceIoControl(hDevice: THandle; dwIoControlCode: DWORD; lpInBuffer: Pointer; nInBufferSize: DWORD; lpOutBuffer: Pointer; nOutBufferSize: DWORD; var lpBytesReturned: DWORD; lpOverlapped: Pointer): BOOL; stdcall; external 'kernel32.dll';


// Optional newer Win32 APIs (available on Vista+). We declare here and fall back when unsupported.
// FindFirstFileExW with LargeFetch
const
  // Kept minimal: only the flags that are actually used to avoid unused-const hints
  FIND_FIRST_EX_LARGE_FETCH            = $00000002; // Vista+/NTFS optimization

  // For GetFinalPathNameByHandleW flags (used)
  FILE_NAME_NORMALIZED = $0;
  VOLUME_NAME_DOS      = $0;

  // The following flags are defined for completeness but currently unused:
  // FIND_FIRST_EX_CASE_SENSITIVE       = $00000001;
  // FIND_FIRST_EX_ON_DISK_ENTRIES_ONLY = $00000004;
  // FILE_NAME_OPENED                   = $8;
  // VOLUME_NAME_GUID                   = $1;
  // VOLUME_NAME_NT                     = $2;
  // VOLUME_NAME_NONE                   = $4;

// Use integer params to avoid enum type availability differences across RTLs
function FindFirstFileExW(lpFileName: PWideChar; fInfoLevelId: Integer; lpFindFileData: Pointer; fSearchOp: Integer; lpSearchFilter: Pointer; dwAdditionalFlags: DWORD): THandle; stdcall; external 'kernel32.dll';
function GetFinalPathNameByHandleW(hFile: THandle; lpszFilePath: PWideChar; cchFilePath: DWORD; dwFlags: DWORD): DWORD; stdcall; external 'kernel32.dll';

// Remove extended path prefix (\\?\ or \\?\UNC\) for external presentation/UTF-8 conversion
function WinStripExtendedPrefix(const W: WideString): WideString; inline;
begin
  if (Length(W) >= 4) and (Copy(W,1,4) = '\\?\') then
  begin
    if (Length(W) >= 8) and (Copy(W,1,8) = '\\?\UNC\') then
      Exit('\\' + Copy(W, 9, MaxInt))
    else
      Exit(Copy(W, 5, MaxInt));
  end;
  Result := W;
end;

type
  PREPARSE_DATA_BUFFER = ^REPARSE_DATA_BUFFER;
  REPARSE_DATA_BUFFER = record
    ReparseTag: DWORD;
    ReparseDataLength: WORD;
    Reserved: WORD;
    case Integer of
      0: (SymbolicLinkReparseBuffer: record
            SubstituteNameOffset: WORD;
            SubstituteNameLength: WORD;
            PrintNameOffset: WORD;
            PrintNameLength: WORD;
            Flags: DWORD;
            PathBuffer: array[0..0] of WCHAR;
          end);
      1: (MountPointReparseBuffer: record
            SubstituteNameOffset: WORD;
            SubstituteNameLength: WORD;
            PrintNameOffset: WORD;
            PrintNameLength: WORD;
            PathBuffer: array[0..0] of WCHAR;
          end);
      2: (GenericReparseBuffer: record
            DataBuffer: array[0..0] of Byte;
          end);
  end;
{$IFDEF FS_UNIFIED_ERRORS}
function __MapWinErrToUnified(aErr: DWORD): Integer; inline;
begin
  case aErr of
    ERROR_SUCCESS: Exit(0);
    ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND: Exit(-2);
    ERROR_ACCESS_DENIED, ERROR_SHARING_VIOLATION: Exit(-3);
    ERROR_DISK_FULL, ERROR_HANDLE_DISK_FULL: Exit(-4);
    ERROR_INVALID_NAME, ERROR_BAD_PATHNAME, ERROR_FILENAME_EXCED_RANGE: Exit(-5);
    ERROR_FILE_EXISTS, ERROR_ALREADY_EXISTS: Exit(-6);
    ERROR_DIR_NOT_EMPTY: Exit(-7);
    ERROR_INVALID_PARAMETER, ERROR_INVALID_HANDLE, ERROR_NOT_SUPPORTED: Exit(-8);
  else
    Exit(-999);
  end;
end;
{$ENDIF}


// 用于抑制未使用参数提示（安全无副作用）
procedure FsIgnoreInt(const Dummy: Integer); inline;
begin
  // 通过条件恒假的读取标记参数为“已使用”，避免提示且无运行时开销
  if False and (Dummy = 0) then ;
end;


// 将 UTF-8 路径转换为宽字符串，并在启用开关时追加 Win32 扩展前缀（\\?\ 或 \\?\UNC\）
function WinGetPathW(const aPath: string): WideString;
  function IsExtendedPrefixed(const W: WideString): Boolean; inline;
  begin
    Result := (Length(W) >= 4) and (Copy(W,1,4) = '\\?\');
  end;
  function IsUncPath(const W: WideString): Boolean; inline;
  begin
    Result := (Length(W) >= 2) and (Copy(W,1,2) = '\\');
  end;
  function IsDriveAbs(const W: WideString): Boolean; inline;
  begin
    Result := (Length(W) >= 3) and (W[2] = ':') and ((W[3] = '\') or (W[3] = '/'));
  end;
var
  W: WideString;
begin
  W := UTF8Decode(aPath);
  {$IFDEF FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH}
  if (Length(W) > 0) and (not IsExtendedPrefixed(W)) then
  begin
    // 仅对“可能超长”的绝对路径加前缀，短路径保持原样，减少对旧组件的影响
    if (Length(W) >= MAX_PATH-12) then
    begin
      if IsUncPath(W) then
        Exit('\\?\UNC\' + Copy(W, 3, MaxInt))
      else if IsDriveAbs(W) then
        Exit('\\?\' + W);
    end;
  end;
  {$ENDIF}
  Result := W;
end;


procedure FileTimeToTimeSpec(const aFileTime: TFileTime; var aTimeSpec: TTimeSpec);
var
  LLarge: Int64;
begin
  LLarge := (Int64(aFileTime.dwHighDateTime) shl 32) or aFileTime.dwLowDateTime;
  LLarge := (LLarge - 116444736000000000);
  aTimeSpec.Sec := LLarge div 10000000;
  aTimeSpec.Nsec := (LLarge mod 10000000) * 100;
end;

procedure Win32AttrsToFsStat(const aWin32Data: TWin32FileAttributeData; out aStat: TfsStat);
begin
  // 初始化结构体为零
  FillChar(aStat, SizeOf(TfsStat), 0);
  aStat.Size := (Int64(aWin32Data.nFileSizeHigh) shl 32) or aWin32Data.nFileSizeLow;
  if (aWin32Data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
    aStat.Mode := S_IFDIR
  else
    aStat.Mode := S_IFREG;
  FileTimeToTimeSpec(aWin32Data.ftLastAccessTime, aStat.ATime);
  FileTimeToTimeSpec(aWin32Data.ftLastWriteTime, aStat.MTime);
  FileTimeToTimeSpec(aWin32Data.ftCreationTime, aStat.CTime);
  FileTimeToTimeSpec(aWin32Data.ftCreationTime, aStat.BTime);
end;

function fs_open(const aPath: string; aFlags, aMode: Integer): TfsFile;
var
  LDesiredAccess, LShareMode, LCreationDisposition: DWORD;
  LFlagsAndAttributes: DWORD;
  LPath: WideString;
begin
  LDesiredAccess := 0;
  if (aFlags and O_RDWR) <> 0 then
    LDesiredAccess := GENERIC_READ or GENERIC_WRITE
  else if (aFlags and O_WRONLY) <> 0 then
    LDesiredAccess := GENERIC_WRITE
  else
    LDesiredAccess := GENERIC_READ;

  if (aFlags and O_APPEND) <> 0 then
    LDesiredAccess := LDesiredAccess or FILE_APPEND_DATA;

  // 默认保持完全共享；若上层传入 O_SHARE_* 则按位生效
  if (aFlags and O_SHARE_MASK) = 0 then
    LShareMode := FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE
  else begin
    LShareMode := 0;
    if (aFlags and O_SHARE_READ) <> 0 then LShareMode := LShareMode or FILE_SHARE_READ;
    if (aFlags and O_SHARE_WRITE) <> 0 then LShareMode := LShareMode or FILE_SHARE_WRITE;
    if (aFlags and O_SHARE_DELETE) <> 0 then LShareMode := LShareMode or FILE_SHARE_DELETE;
  end;

  case (aFlags and (O_CREAT or O_EXCL or O_TRUNC)) of
    O_CREAT or O_EXCL:
      LCreationDisposition := CREATE_NEW;
    O_CREAT or O_TRUNC:
      LCreationDisposition := CREATE_ALWAYS;
    O_TRUNC:
      LCreationDisposition := TRUNCATE_EXISTING;
    O_CREAT:
      LCreationDisposition := OPEN_ALWAYS;
  else
    LCreationDisposition := OPEN_EXISTING;
  end;

  LFlagsAndAttributes := FILE_ATTRIBUTE_NORMAL;
  {$IFDEF FS_USE_OVERLAPPED}
  // 实验开关：以 OVERLAPPED 方式打开句柄，默认关闭保持行为不变
  LFlagsAndAttributes := LFlagsAndAttributes or FILE_FLAG_OVERLAPPED;
  {$ENDIF}

  // 先转换路径，避免在CreateFileW之后调用可能清除错误代码的函数
  LPath := WinGetPathW(aPath);

  Result := CreateFileW(PWideChar(LPath),
                        LDesiredAccess,
                        LShareMode,
                        nil,
                        LCreationDisposition,
                        LFlagsAndAttributes,
                        0);

  // 如果失败，立即保存错误代码到全局变量
  if Result = INVALID_HANDLE_VALUE then
  begin
    LastFsErrorCode := GetLastError();
  end
  else
  begin
    LastFsErrorCode := 0;  // 成功时清除错误代码
  end;

  // 注意：fs_open返回句柄，错误检查由调用者负责
  // 调用者应该检查 Result = INVALID_HANDLE_VALUE
end;

function fs_close(aFile: TfsFile): Integer;
begin
  if CloseHandle(aFile) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_read(aFile: TfsFile; const aBuffer: Pointer; aLength: SizeUInt; aOffset: Int64): Integer;
var
  LOverlapped: OVERLAPPED;
  LBytesRead: DWORD;
  LOverlappedPtr: POverlapped;
{$IFDEF DEBUG}
  // 保守初始化，压低未初始化提示（不改变行为）
  // 注意：实际使用前已 FillChar 归零
{$ENDIF}
begin
  FillChar(LOverlapped, SizeOf(LOverlapped), 0);
  if aOffset = -1 then
  begin
    LOverlappedPtr := nil;
  end
  else
  begin
    LOverlapped.Offset := DWORD(aOffset);
    LOverlapped.OffsetHigh := DWORD(aOffset shr 32);
    LOverlappedPtr := @LOverlapped;
  end;

  LBytesRead := 0;
  if ReadFile(aFile, aBuffer^, aLength, LBytesRead, LOverlappedPtr) then
    Result := Integer(LBytesRead)
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_write(aFile: TfsFile; const aBuffer: Pointer; aLength: SizeUInt; aOffset: Int64): Integer;
var
  LOverlapped: OVERLAPPED;
  LBytesWritten: DWORD;
  LOverlappedPtr: POverlapped;
{$IFDEF DEBUG}
  // 保守初始化，压低未初始化提示（不改变行为）
{$ENDIF}
begin
  FillChar(LOverlapped, SizeOf(LOverlapped), 0);
  if aOffset = -1 then
  begin
    LOverlappedPtr := nil;
  end
  else
  begin
    LOverlapped.Offset := DWORD(aOffset);
    LOverlapped.OffsetHigh := DWORD(aOffset shr 32);
    LOverlappedPtr := @LOverlapped;
  end;

  LBytesWritten := 0;
  if WriteFile(aFile, aBuffer^, aLength, LBytesWritten, LOverlappedPtr) then
    Result := Integer(LBytesWritten)
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_unlink(const aPath: string): Integer;
var
  Attrs: DWORD;
  IsDirSymlink: Boolean;
  W: PWideChar;
begin
  // 先判断是否为“目录型符号链接”（reparse + directory），此类应使用 RemoveDirectoryW 删除链接本体
  Attrs := GetFileAttributesW(PWideChar(WinGetPathW(aPath)));
  if Attrs <> INVALID_FILE_ATTRIBUTES then
  begin
    IsDirSymlink := ((Attrs and FILE_ATTRIBUTE_REPARSE_POINT) <> 0) and ((Attrs and FILE_ATTRIBUTE_DIRECTORY) <> 0);
    if IsDirSymlink then
    begin
      if RemoveDirectoryW(PWideChar(WinGetPathW(aPath))) then
        Exit(0)
      else
      begin
        {$IFDEF FS_UNIFIED_ERRORS}
        Exit(__MapWinErrToUnified(GetLastError()));
        {$ELSE}
        Exit(-Integer(GetLastError()));
        {$ENDIF}
      end;
    end;
  end;

  // 普通文件/链接（非目录）：使用 DeleteFileW
  W := PWideChar(WinGetPathW(aPath));
  if DeleteFileW(W) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_rename(const aOldPath, aNewPath: string): Integer;
begin
  if MoveFileW(PWideChar(WinGetPathW(aOldPath)), PWideChar(WinGetPathW(aNewPath))) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_replace(const aSrc, aDst: string): Integer;
var
  WS, WD: WideString;
begin
  WS := WinGetPathW(aSrc);
  WD := WinGetPathW(aDst);
  if MoveFileExW(PWideChar(WS), PWideChar(WD), MOVEFILE_REPLACE_EXISTING or MOVEFILE_COPY_ALLOWED) then
    Exit(0);

  {$IFDEF FS_UNIFIED_ERRORS}
  Result := __MapWinErrToUnified(GetLastError());
  {$ELSE}
  Result := -Integer(GetLastError());
  {$ENDIF}
end;

function fs_mkdir(const aPath: string; aMode: Integer): Integer;
var
  __unused_mode: Integer;
begin
  // 标记未使用参数，避免提示（不改变行为）
  __unused_mode := aMode; if False and (__unused_mode = 0) then ;
  if CreateDirectoryW(PWideChar(WinGetPathW(aPath)), nil) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_rmdir(const aPath: string): Integer;
begin
  if RemoveDirectoryW(PWideChar(WinGetPathW(aPath))) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

// 内部辅助：仅判断是否为符号链接（通过重解析点标签）
function __WinIsSymlink(const aPath: string): Boolean;
var
  LHandle: THandle;
  LReparseData: array[0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE-1] of Byte;
  LBytesReturned: DWORD;
  LReparseBuffer: PREPARSE_DATA_BUFFER;
begin
  Result := False;
  LHandle := CreateFileW(PWideChar(WinGetPathW(aPath)),
                         0,
                         FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
                         nil,
                         OPEN_EXISTING,
                         FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT,
                         0);
  if LHandle = INVALID_HANDLE_VALUE then Exit;
  try
    FillChar(LReparseData, SizeOf(LReparseData), 0);
    LBytesReturned := 0;
    if not DeviceIoControl(LHandle,
                           FSCTL_GET_REPARSE_POINT,
                           nil, 0,
                           @LReparseData, SizeOf(LReparseData),
                           LBytesReturned, nil) then
      Exit;
    LReparseBuffer := PREPARSE_DATA_BUFFER(@LReparseData);
    Result := (LReparseBuffer^.ReparseTag = IO_REPARSE_TAG_SYMLINK);
  finally
    CloseHandle(LHandle);
  end;
end;

function fs_stat(const aPath: string; out aStat: TfsStat): Integer;
var
  LWin32Data: TWin32FileAttributeData;
begin
  FillChar(aStat, SizeOf(aStat), 0);
  if GetFileAttributesExW(PWideChar(WinGetPathW(aPath)), GetFileExInfoStandard, @LWin32Data) then
  begin
    Win32AttrsToFsStat(LWin32Data, aStat);
    Result := 0;
  end
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_lstat(const aPath: string; out aStat: TfsStat): Integer;
var
  LWin32Data: TWin32FileAttributeData;
begin
  FillChar(aStat, SizeOf(aStat), 0);
  if GetFileAttributesExW(PWideChar(WinGetPathW(aPath)), GetFileExInfoStandard, @LWin32Data) then
  begin
    Win32AttrsToFsStat(LWin32Data, aStat);
    if (LWin32Data.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0 then
    begin
      // 仅在确认为符号链接时标记 S_IFLNK，避免把挂载点等也当作 symlink
      if __WinIsSymlink(aPath) then
        aStat.Mode := S_IFLNK;
    end;
    Result := 0;
  end
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_fstat(aFile: TfsFile; out aStat: TfsStat): Integer;
var
  LFileInfo: TByHandleFileInformation;
begin
  FillChar(LFileInfo, SizeOf(LFileInfo), 0);
  if GetFileInformationByHandle(aFile, LFileInfo) then
  begin
    FillChar(aStat, SizeOf(TfsStat), 0);
    aStat.Size := (Int64(LFileInfo.nFileSizeHigh) shl 32) or LFileInfo.nFileSizeLow;
    if (LFileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
      aStat.Mode := S_IFDIR
    else
      aStat.Mode := S_IFREG;
    FileTimeToTimeSpec(LFileInfo.ftLastAccessTime, aStat.ATime);
    FileTimeToTimeSpec(LFileInfo.ftLastWriteTime, aStat.MTime);
    FileTimeToTimeSpec(LFileInfo.ftCreationTime, aStat.CTime);
    FileTimeToTimeSpec(LFileInfo.ftCreationTime, aStat.BTime);
    aStat.Ino := (Int64(LFileInfo.nFileIndexHigh) shl 32) or LFileInfo.nFileIndexLow;
    Result := 0;
  end
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_ftruncate(aFile: TfsFile; aOffset: Int64): Integer;
var
  LLow, LHigh: DWORD;
  LResult: DWORD;
begin
  // 正确处理64位文件偏移
  LLow := DWORD(aOffset and $FFFFFFFF);
  LHigh := DWORD(aOffset shr 32);

  LResult := SetFilePointer(aFile, LLow, @LHigh, FILE_BEGIN);
  if (LResult = INVALID_SET_FILE_POINTER) and (GetLastError() <> NO_ERROR) then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
    Exit;
  end;

  if not SetEndOfFile(aFile) then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end
  else
    Result := 0;
end;

function fs_scandir(const aPath: string; var aEntries: TStringList): Integer;
var
  LSearchHandle: THandle;
  LFindData: TWin32FindDataW;
  LSearchPath: WideString;
  LFileName: string;
  LErr: DWORD;
{$IFDEF DEBUG}
  // 初始化已在使用前 FillChar 归零
{$ENDIF}
begin
  // 性能优化：预分配容量，减少动态扩展开销
  aEntries.Clear;
  aEntries.Capacity := 256;


  // 使用Windows API直接搜索，优先 FindFirstFileExW + LargeFetch（Vista+/NTFS 下更高效），失败回退
  LSearchPath := WinGetPathW(IncludeTrailingPathDelimiter(aPath) + '*');
  FillChar(LFindData, SizeOf(LFindData), 0);

  // Try FindFirstFileExW with Basic info + NameMatch + LargeFetch
  LSearchHandle := FindFirstFileExW(PWideChar(LSearchPath), 1 {FindExInfoBasic}, @LFindData, 0 {FindExSearchNameMatch}, nil, FIND_FIRST_EX_LARGE_FETCH);
  if LSearchHandle = INVALID_HANDLE_VALUE then
  begin
    LErr := GetLastError();
    // Retry without LargeFetch if not supported
    if (LErr = ERROR_INVALID_PARAMETER) or (LErr = ERROR_INVALID_FUNCTION) then
      LSearchHandle := FindFirstFileExW(PWideChar(LSearchPath), 1 {FindExInfoBasic}, @LFindData, 0 {FindExSearchNameMatch}, nil, 0);

    if LSearchHandle = INVALID_HANDLE_VALUE then
    begin
      // Fallback to legacy API
      FillChar(LFindData, SizeOf(LFindData), 0);
      LSearchHandle := FindFirstFileW(PWideChar(LSearchPath), LFindData);
      if LSearchHandle = INVALID_HANDLE_VALUE then
      begin
        {$IFDEF FS_UNIFIED_ERRORS}
        Result := __MapWinErrToUnified(GetLastError());
        {$ELSE}
        Result := -Integer(GetLastError());
        {$ENDIF}
        Exit;
      end;
    end;
  end;

  try
    repeat
      // 性能优化：直接检查Unicode字符，避免不必要的字符串转换
      if (LFindData.cFileName[0] <> '.') or
         ((LFindData.cFileName[1] <> #0) and
          ((LFindData.cFileName[1] <> '.') or (LFindData.cFileName[2] <> #0))) then
      begin
        LFileName := UTF8Encode(WideString(LFindData.cFileName));
        aEntries.Add(LFileName);
      end;
      FillChar(LFindData, SizeOf(LFindData), 0);
    until not FindNextFileW(LSearchHandle, LFindData);

    Result := 0;
  finally
    Windows.FindClose(LSearchHandle);
  end;
end;

function fs_scandir_each(const aPath: string; aOnEntry: TfsScandirEachProc): Integer;
var
  LSearchHandle: THandle;
  LFindData: TWin32FindDataW;
  LSearchPath: WideString;
  LName: string;
  LType: TfsDirEntType;
  LErr: DWORD;
begin
  Result := 0;
  if not Assigned(aOnEntry) then Exit(0);

  LSearchPath := WinGetPathW(IncludeTrailingPathDelimiter(aPath) + '*');
  FillChar(LFindData, SizeOf(LFindData), 0);

  // 优先 FindFirstFileExW（Basic+LargeFetch），失败回退
  LSearchHandle := FindFirstFileExW(PWideChar(LSearchPath), 1 {FindExInfoBasic}, @LFindData, 0 {FindExSearchNameMatch}, nil, FIND_FIRST_EX_LARGE_FETCH);
  if LSearchHandle = INVALID_HANDLE_VALUE then
  begin
    LErr := GetLastError();
    if (LErr = ERROR_INVALID_PARAMETER) or (LErr = ERROR_INVALID_FUNCTION) then
      LSearchHandle := FindFirstFileExW(PWideChar(LSearchPath), 1 {FindExInfoBasic}, @LFindData, 0 {FindExSearchNameMatch}, nil, 0);

    if LSearchHandle = INVALID_HANDLE_VALUE then
    begin
      // 最后回退传统 API
      FillChar(LFindData, SizeOf(LFindData), 0);
      LSearchHandle := FindFirstFileW(PWideChar(LSearchPath), LFindData);
      if LSearchHandle = INVALID_HANDLE_VALUE then
      begin
        {$IFDEF FS_UNIFIED_ERRORS}
        Exit(__MapWinErrToUnified(GetLastError()));
        {$ELSE}
        Exit(-Integer(GetLastError()));
        {$ENDIF}
      end;
    end;
  end;

  try
    repeat
      // 跳过 . 和 ..
      if (LFindData.cFileName[0] = '.') and
         ((LFindData.cFileName[1] = #0) or ((LFindData.cFileName[1] = '.') and (LFindData.cFileName[2] = #0))) then
      begin
        FillChar(LFindData, SizeOf(LFindData), 0);
        Continue;
      end;

      if (LFindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
        LType := fsDETDir
      else
        LType := fsDETFile;

      LName := UTF8Encode(WideString(LFindData.cFileName));
      if not aOnEntry(LName, LType) then Exit(0);
      FillChar(LFindData, SizeOf(LFindData), 0);
    until not FindNextFileW(LSearchHandle, LFindData);
  finally
    Windows.FindClose(LSearchHandle);
  end;
end;


function fs_copyfile(const aPath, aNewPath: string; aFlags: Integer): Integer;
var
  LFailIfExists: BOOL;
  LCancel: BOOL;
  LCopyFlags: DWORD;
begin
  // 静默未用局部（不改变行为）
  LFailIfExists := FALSE; if False and LFailIfExists then ;
  LCancel := FALSE;
  if (aFlags and UV_FS_COPYFILE_EXCL) <> 0 then
  begin
    LFailIfExists := TRUE; if False and LFailIfExists then ;
    LCopyFlags := $00000001 {COPY_FILE_FAIL_IF_EXISTS};
  end
  else
  begin
    LFailIfExists := FALSE; if False and LFailIfExists then ;
    LCopyFlags := 0;
  end;

  // CopyFileExW 支持进度/取消回调，这里不需要，传 nil/0；用 COPY_FILE_FAIL_IF_EXISTS 实现 EXCL 语义
  if CopyFileExW(PWideChar(WinGetPathW(aPath)), PWideChar(WinGetPathW(aNewPath)), nil, nil, @LCancel, LCopyFlags) <> 0 then
    Exit(0)
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_chmod(const aPath: string; aMode: Integer): Integer;
var
  LAttrs: DWORD;
begin
  LAttrs := GetFileAttributesW(PWideChar(WinGetPathW(aPath)));
  if LAttrs = INVALID_FILE_ATTRIBUTES then
    Exit(-Integer(GetLastError()));

  if (aMode and S_IWUSR) = 0 then
    LAttrs := LAttrs or FILE_ATTRIBUTE_READONLY
  else
    LAttrs := LAttrs and not FILE_ATTRIBUTE_READONLY;

  if SetFileAttributesW(PWideChar(WinGetPathW(aPath)), LAttrs) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_fchmod(aFile: TfsFile; aMode: Integer): Integer;
var
  __unused_mode: Integer;
begin
  // 标记未使用参数（不改变行为）
  __unused_mode := aMode; if False and (__unused_mode = 0) then ;
  {$IFDEF FS_UNIFIED_ERRORS}
  Result := __MapWinErrToUnified(ERROR_NOT_SUPPORTED);
  {$ELSE}
  Result := -Integer(ERROR_NOT_SUPPORTED);
  {$ENDIF}
end;

function fs_utime(const aPath: string; aAtime, aMtime: Double): Integer;
var
  LFile: TfsFile;
  LAccess: DWORD;
  LShare: DWORD;
  LFlags: DWORD;
  LPath: WideString;
  LAttrs: DWORD;
  LClearedRO: Boolean;
  R: Integer;
begin
  // 以“写属性”权限打开，避免对只读文件请求 GENERIC_WRITE 导致拒绝；允许目录句柄（BACKUP_SEMANTICS）
  LAccess := FILE_WRITE_ATTRIBUTES;
  LShare := FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE;
  LFlags := FILE_ATTRIBUTE_NORMAL or FILE_FLAG_BACKUP_SEMANTICS;
  LPath := WinGetPathW(aPath);

  LFile := CreateFileW(PWideChar(LPath), LAccess, LShare, nil, OPEN_EXISTING, LFlags, 0);
  if LFile = INVALID_HANDLE_VALUE then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
    Exit;
  end;
  try
    R := fs_futime(LFile, aAtime, aMtime);
    if R <> 0 then
    begin
      // 回退：若文件带只读属性，临时清除再尝试一次，最后恢复属性
      LClearedRO := False;
      LAttrs := GetFileAttributesW(PWideChar(LPath));
      if (LAttrs <> INVALID_FILE_ATTRIBUTES) and ((LAttrs and FILE_ATTRIBUTE_READONLY) <> 0) then
      begin
        if SetFileAttributesW(PWideChar(LPath), LAttrs and not FILE_ATTRIBUTE_READONLY) then
        begin
          LClearedRO := True;
          R := fs_futime(LFile, aAtime, aMtime);
          // 恢复只读（忽略恢复失败）
          if LClearedRO then
            SetFileAttributesW(PWideChar(LPath), LAttrs);
        end;
      end;
    end;
    Result := R;
  finally
    CloseHandle(LFile);
  end;
end;

function fs_futime(aFile: TfsFile; aAtime, aMtime: Double): Integer;
var
  LAccessTime, LWriteTime: TFileTime;
  LUnixTime: Int64;
begin
  // 使用四舍五入保留子秒精度（Double → 100ns）
  LUnixTime := Round(aAtime * 10000000.0) + 116444736000000000;
  LAccessTime.dwLowDateTime := DWORD(LUnixTime);
  LAccessTime.dwHighDateTime := DWORD(LUnixTime shr 32);

  LUnixTime := Round(aMtime * 10000000.0) + 116444736000000000;
  LWriteTime.dwLowDateTime := DWORD(LUnixTime);
  LWriteTime.dwHighDateTime := DWORD(LUnixTime shr 32);

  if SetFileTime(aFile, nil, @LAccessTime, @LWriteTime) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;



function fs_fsync(aFile: TfsFile): Integer;
begin
  if FlushFileBuffers(aFile) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_access(const aPath: string; aMode: Integer): Integer;
var
  LAttrs: DWORD;
begin
  LAttrs := GetFileAttributesW(PWideChar(WinGetPathW(aPath)));
  if LAttrs = INVALID_FILE_ATTRIBUTES then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
    Exit;
  end;

  // Windows下简化的权限检查
  // F_OK: 仅需存在性，前面已通过 GetFileAttributesW 校验，无需额外处理

  if (aMode and R_OK) <> 0 then
  begin
    // Windows下假设文件可读（除非是系统文件）
    if (LAttrs and FILE_ATTRIBUTE_SYSTEM) <> 0 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(ERROR_ACCESS_DENIED);
      {$ELSE}
      Result := -Integer(ERROR_ACCESS_DENIED);
      {$ENDIF}
      Exit;
    end;
  end;

  if (aMode and W_OK) <> 0 then
  begin
    // 检查只读属性
    if (LAttrs and FILE_ATTRIBUTE_READONLY) <> 0 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(ERROR_ACCESS_DENIED);
      {$ELSE}
      Result := -Integer(ERROR_ACCESS_DENIED);
      {$ENDIF}
      Exit;
    end;
  end;

  if (aMode and X_OK) <> 0 then
  begin
    // Windows下检查文件扩展名或目录属性
    if (LAttrs and FILE_ATTRIBUTE_DIRECTORY) = 0 then
    begin
      // 简化的可执行文件检查
      // 实际应该检查文件扩展名或PE头
    end;
  end;

  Result := 0;
end;

function fs_link(const aPath, aNewPath: string): Integer;
begin
  // Windows下创建硬链接
  if CreateHardLinkW(PWideChar(WinGetPathW(aNewPath)), PWideChar(WinGetPathW(aPath)), nil) then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
  end;
end;

function fs_symlink(const aPath, aNewPath: string): Integer;
var
  FlagsBase: DWORD;
  FlagsDir, FlagsFile: DWORD;
  LStat: TfsStat;
  HasType: Boolean;
  IsDir: Boolean;
  Err: Integer;
  PathW, NewPathW: PWideChar;

  function TryCreate(Flags: DWORD): Integer;
  begin
    if CreateSymbolicLinkW(NewPathW, PathW, Flags) then
      Exit(0)
    else
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Exit(__MapWinErrToUnified(GetLastError()));
      {$ELSE}
      Exit(-Integer(GetLastError()));
      {$ENDIF}
    end;
  end;
begin
  // 基础标志：条件允许时尽量允许无特权创建（Windows 10 1703+ 且策略允许）
  FlagsBase := 0;
  {$IFDEF SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE}
  FlagsBase := FlagsBase or SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
  {$ENDIF}

  // 目录/文件两套标志
  FlagsDir := FlagsBase or SYMBOLIC_LINK_FLAG_DIRECTORY;
  FlagsFile := FlagsBase;

  // 先尝试判断目标是否存在以及是否为目录；不存在时允许悬挂链接（不做失败）
  HasType := False;
  IsDir := False;
  if fs_stat(aPath, LStat) = 0 then
  begin
    HasType := True;
    IsDir := (LStat.Mode and S_IFMT) = S_IFDIR;
  end;

  PathW := PWideChar(WinGetPathW(aPath));
  NewPathW := PWideChar(WinGetPathW(aNewPath));

  if HasType then
  begin
    if IsDir then
      Result := TryCreate(FlagsDir)
    else
      Result := TryCreate(FlagsFile);

    // 某些情况下目录/文件标志判断可能仍不匹配（如重解析点语义差异），失败时尝试另一种
    if Result < 0 then
    begin
      if IsDir then
        Result := TryCreate(FlagsFile)
      else
        Result := TryCreate(FlagsDir);
    end;
    Exit;
  end
  else
  begin
    // 目标不存在（dangling）：尝试文件→目录两个方向
    Result := TryCreate(FlagsFile);
    if Result < 0 then
      Result := TryCreate(FlagsDir);
    Exit;
  end;
end;

function fs_readlink(const aPath: string; aBuffer: PChar; aSize: SizeUInt): Integer;
var
  LHandle: THandle;
  LReparseData: array[0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE-1] of Byte;
  LBytesReturned: DWORD;
  LReparseBuffer: PREPARSE_DATA_BUFFER;
  LTargetPath: PWideChar;
  LTargetLength: Integer;
  LUtf8Target: string;
begin
  // 打开符号链接文件
  LHandle := CreateFileW(PWideChar(WinGetPathW(aPath)),
                        0,
                        FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
                        nil,
                        OPEN_EXISTING,
                        FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT,
                        0);

  if LHandle = INVALID_HANDLE_VALUE then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -Integer(GetLastError());
    {$ENDIF}
    Exit;
  end;

  try
    // 获取重解析点数据
    FillChar(LReparseData, SizeOf(LReparseData), 0);
    LBytesReturned := 0;
    if not DeviceIoControl(LHandle,
                          FSCTL_GET_REPARSE_POINT,
                          nil, 0,
                          @LReparseData, SizeOf(LReparseData),
                          LBytesReturned, nil) then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(GetLastError());
      {$ELSE}
      Result := -Integer(GetLastError());
      {$ENDIF}
      Exit;
    end;

    LReparseBuffer := PREPARSE_DATA_BUFFER(@LReparseData);

    // 检查是否为符号链接
    if LReparseBuffer^.ReparseTag <> IO_REPARSE_TAG_SYMLINK then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(ERROR_NOT_A_REPARSE_POINT);
      {$ELSE}
      Result := -Integer(ERROR_NOT_A_REPARSE_POINT);
      {$ENDIF}
      Exit;
    end;

    // 提取目标路径
    LTargetPath := PWideChar(@LReparseBuffer^.SymbolicLinkReparseBuffer.PathBuffer[
      LReparseBuffer^.SymbolicLinkReparseBuffer.PrintNameOffset div 2]);
    LTargetLength := LReparseBuffer^.SymbolicLinkReparseBuffer.PrintNameLength div 2;

    // 转换为UTF-8
    LUtf8Target := UTF8Encode(WideString(Copy(LTargetPath, 1, LTargetLength)));

    // 复制到输出缓冲区
    if Length(LUtf8Target) >= Integer(aSize) then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(ERROR_INSUFFICIENT_BUFFER);
      {$ELSE}
      Result := -Integer(ERROR_INSUFFICIENT_BUFFER);
      {$ENDIF}
      Exit;
    end;

    Move(PChar(LUtf8Target)^, aBuffer^, Length(LUtf8Target));
    aBuffer[Length(LUtf8Target)] := #0;
    Result := Length(LUtf8Target);

  finally
    CloseHandle(LHandle);
  end;
end;

function fs_flock(aFile: TfsFile; aOperation: Integer): Integer;
var
  LOverlapped: TOverlapped;
  LFlags: DWORD;
{$IFDEF DEBUG}
  // 初始化在后续 FillChar 完成
{$ENDIF}
begin
  FillChar(LOverlapped, SizeOf(LOverlapped), 0);

  // 转换锁定操作
  LFlags := 0;
  if (aOperation and LOCK_EX) <> 0 then
    LFlags := LFlags or LOCKFILE_EXCLUSIVE_LOCK;
  if (aOperation and LOCK_NB) <> 0 then
    LFlags := LFlags or LOCKFILE_FAIL_IMMEDIATELY;

  if (aOperation and LOCK_UN) <> 0 then
  begin
    // 解锁
    if UnlockFileEx(aFile, 0, $FFFFFFFF, $FFFFFFFF, @LOverlapped) then
      Result := 0
    else
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(GetLastError());
      {$ELSE}
      Result := -Integer(GetLastError());
      {$ENDIF}
    end;
  end
  else
  begin
    // 加锁
    if LockFileEx(aFile, LFlags, 0, $FFFFFFFF, $FFFFFFFF, @LOverlapped) then
      Result := 0
    else
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapWinErrToUnified(GetLastError());
      {$ELSE}
      Result := -Integer(GetLastError());
      {$ENDIF}
    end;
  end;
end;

function fs_realpath(const aPath: string; aResolvedPath: PChar; aSize: SizeUInt): Integer;
var
  h: THandle;
  Need, Got: DWORD;
  WBuf: PWideChar;
  WIn, WOut: WideString;
  Utf8Path: string;
  Attrs: DWORD;
  FilePart: PWideChar;
begin
  Result := 0;
  WBuf := nil;
  // Preferred: use GetFinalPathNameByHandleW for accurate canonical path
  WIn := WinGetPathW(aPath);
  h := CreateFileW(PWideChar(WIn), 0, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
  if h <> INVALID_HANDLE_VALUE then
  begin
    try
      Need := GetFinalPathNameByHandleW(h, nil, 0, FILE_NAME_NORMALIZED or VOLUME_NAME_DOS);
      if Need = 0 then
      begin
        {$IFDEF FS_UNIFIED_ERRORS}
        Exit(__MapWinErrToUnified(GetLastError()));
        {$ELSE}
        Exit(-Integer(GetLastError()));
        {$ENDIF}
      end;
      GetMem(WBuf, SizeOf(WideChar) * Need);
      Got := GetFinalPathNameByHandleW(h, WBuf, Need, FILE_NAME_NORMALIZED or VOLUME_NAME_DOS);
      if (Got = 0) then
      begin
        {$IFDEF FS_UNIFIED_ERRORS}
        Exit(__MapWinErrToUnified(GetLastError()));
        {$ELSE}
        Exit(-Integer(GetLastError()));
        {$ENDIF}
      end;
      // Convert to WideString of length Got
      SetString(WOut, WBuf, Got);
      // Strip extended prefix for external presentation
      WOut := WinStripExtendedPrefix(WOut);
      Utf8Path := UTF8Encode(WOut);
      if Length(Utf8Path) >= Integer(aSize) then
      begin
        {$IFDEF FS_UNIFIED_ERRORS}
        Exit(__MapWinErrToUnified(ERROR_INSUFFICIENT_BUFFER));
        {$ELSE}
        Exit(-Integer(ERROR_INSUFFICIENT_BUFFER));
        {$ENDIF}
      end;
      Move(PChar(Utf8Path)^, aResolvedPath^, Length(Utf8Path));
      aResolvedPath[Length(Utf8Path)] := #0;
      Result := Length(Utf8Path);
      Exit;
    finally
      if Assigned(WBuf) then FreeMem(WBuf);
      CloseHandle(h);
    end;
  end;

  // Fallback: GetFullPathNameW + existence check (legacy behavior)
  FilePart := nil;
  Need := GetFullPathNameW(PWideChar(WIn), 0, nil, FilePart);
  if Need = 0 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Exit(__MapWinErrToUnified(GetLastError()));
    {$ELSE}
    Exit(-Integer(GetLastError()));
    {$ENDIF}
  end;
  GetMem(WBuf, SizeOf(WideChar) * Need);
  FilePart := nil;
  if GetFullPathNameW(PWideChar(WIn), Need, WBuf, FilePart) = 0 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    FreeMem(WBuf);
    Exit(__MapWinErrToUnified(GetLastError()));
    {$ELSE}
    FreeMem(WBuf);
    Exit(-Integer(GetLastError()));
    {$ENDIF}
  end;

  Attrs := GetFileAttributesW(WBuf);
  if Attrs = INVALID_FILE_ATTRIBUTES then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    FreeMem(WBuf);
    Exit(__MapWinErrToUnified(GetLastError()));
    {$ELSE}
    FreeMem(WBuf);
    Exit(-Integer(GetLastError()));
    {$ENDIF}
  end;

  Utf8Path := UTF8Encode(WideString(WBuf));
  if Length(Utf8Path) >= Integer(aSize) then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    FreeMem(WBuf);
    Exit(__MapWinErrToUnified(ERROR_INSUFFICIENT_BUFFER));
    {$ELSE}
    FreeMem(WBuf);
    Exit(-Integer(ERROR_INSUFFICIENT_BUFFER));
    {$ENDIF}
  end;

  Move(PChar(Utf8Path)^, aResolvedPath^, Length(Utf8Path));
  aResolvedPath[Length(Utf8Path)] := #0;
  Result := Length(Utf8Path);
  FreeMem(WBuf);
end;

function fs_mkdtemp(const aTemplate: string): string;
var
  LTempPath: WideString;
  LDirNameW: WideString;
  LG: TGUID;
  i: Integer;
  LNeeded, LWritten: DWORD;
begin
  Result := '';
  LTempPath := '';

  // 获取临时目录路径（动态缓冲）
  LNeeded := GetTempPathW(0, nil);
  if LNeeded = 0 then Exit;
  SetLength(LTempPath, LNeeded-1);
  LWritten := GetTempPathW(LNeeded, PWideChar(LTempPath));
  if LWritten = 0 then Exit;

  // 尝试多次生成唯一目录
  for i := 1 to 10 do
  begin
    if CreateGUID(LG) <> S_OK then Exit;
    LDirNameW := LTempPath + WideString(StringReplace(GUIDToString(LG), '{', '', []));
    LDirNameW := WideString(StringReplace(string(LDirNameW), '}', '', []));
    LDirNameW := WideString(StringReplace(string(LDirNameW), '-', '', [rfReplaceAll]));

    if CreateDirectoryW(PWideChar(WinGetPathW(UTF8Encode(LDirNameW))), nil) then
    begin
      Result := UTF8Encode(LDirNameW);
      Exit;
    end
    else if GetLastError() = ERROR_ALREADY_EXISTS then
      Continue
    else
      Exit; // 其他错误，返回空
  end;
end;

function fs_mkstemp(const aTemplate: string): TfsFile;
var
  LTempPath: WideString;
  LFileW: WideString;
  LG: TGUID;
  i: Integer;
  LNeeded, LWritten: DWORD;
begin
  Result := INVALID_HANDLE_VALUE;
  LTempPath := '';

  // 获取临时目录路径（动态缓冲）
  LNeeded := GetTempPathW(0, nil);
  if LNeeded = 0 then Exit;
  SetLength(LTempPath, LNeeded-1);
  LWritten := GetTempPathW(LNeeded, PWideChar(LTempPath));
  if LWritten = 0 then Exit;

  // 多次尝试唯一文件名（CREATE_NEW 保证不存在时创建）
  for i := 1 to 10 do
  begin
    if CreateGUID(LG) <> S_OK then Exit;
    LFileW := LTempPath + WideString(StringReplace(GUIDToString(LG), '{', '', []));
    LFileW := WideString(StringReplace(string(LFileW), '}', '', []));
    LFileW := WideString(StringReplace(string(LFileW), '-', '', [rfReplaceAll]));

    Result := CreateFileW(PWideChar(WinGetPathW(UTF8Encode(LFileW))),
                          GENERIC_READ or GENERIC_WRITE,
                          0,
                          nil,
                          CREATE_NEW,
                          FILE_ATTRIBUTE_TEMPORARY,
                          0);
    if Result <> INVALID_HANDLE_VALUE then Exit
    else if GetLastError() = ERROR_FILE_EXISTS then Continue
    else Exit; // 其他错误
  end;
end;

function fs_mkstemp_ex(const aTemplate: string; out aPath: string): TfsFile;
var
  LTempPath: WideString;
  LFileW: WideString;
  LG: TGUID;
  i: Integer;
  LNeeded, LWritten: DWORD;
  LUtf8: UTF8String;
begin
  aPath := '';
  Result := INVALID_HANDLE_VALUE;
  LTempPath := '';

  // 获取临时目录路径（动态缓冲）
  LNeeded := GetTempPathW(0, nil);
  if LNeeded = 0 then Exit;
  SetLength(LTempPath, LNeeded-1);
  LWritten := GetTempPathW(LNeeded, PWideChar(LTempPath));
  if LWritten = 0 then Exit;

  // 多次尝试唯一文件名（CREATE_NEW 保证不存在时创建）
  for i := 1 to 10 do
  begin
    if CreateGUID(LG) <> S_OK then Exit;
    LFileW := LTempPath + WideString(StringReplace(GUIDToString(LG), '{', '', []));
    LFileW := WideString(StringReplace(string(LFileW), '}', '', []));
    LFileW := WideString(StringReplace(string(LFileW), '-', '', [rfReplaceAll]));

    Result := CreateFileW(PWideChar(WinGetPathW(UTF8Encode(LFileW))),
                          GENERIC_READ or GENERIC_WRITE,
                          0,
                          nil,
                          CREATE_NEW,
                          FILE_ATTRIBUTE_TEMPORARY,
                          0);
    if Result <> INVALID_HANDLE_VALUE then
    begin
      LUtf8 := UTF8Encode(LFileW);
      aPath := string(LUtf8);
      Exit;
    end
    else if GetLastError() = ERROR_FILE_EXISTS then Continue
    else Exit; // 其他错误
  end;
end;

// 获取保存的文件系统错误代码
function GetSavedFsErrorCode: DWORD;
begin
  Result := LastFsErrorCode;
end;

// 跨平台：返回最后一次 fs_open 的错误码（线程局部）
function fs_errno: Integer;
begin
  {$IFDEF FS_UNIFIED_ERRORS}
  Result := __MapWinErrToUnified(LastFsErrorCode);
  {$ELSE}
  Result := -Integer(LastFsErrorCode);
  {$ENDIF}
end;


function fs_seek(aFile: TfsFile; aOffset: Int64; aWhence: Integer): Int64;
var
  LDistanceToMove: LARGE_INTEGER;
  LNewFilePointer: LARGE_INTEGER;
  LMoveMethod: DWORD;
begin
  case aWhence of
    SEEK_SET: LMoveMethod := FILE_BEGIN;
    SEEK_CUR: LMoveMethod := FILE_CURRENT;
    SEEK_END: LMoveMethod := FILE_END;
  else
    Result := -ERROR_INVALID_PARAMETER;
    Exit;
  end;

  LDistanceToMove.QuadPart := aOffset;

  if SetFilePointerEx(aFile, LDistanceToMove, @LNewFilePointer, LMoveMethod) then
    Result := LNewFilePointer.QuadPart
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -GetLastError();
    {$ENDIF}
  end;
end;

function fs_tell(aFile: TfsFile): Int64;
var
  LDistanceToMove: LARGE_INTEGER;
  LNewFilePointer: LARGE_INTEGER;
begin
  LDistanceToMove.QuadPart := 0;

  if SetFilePointerEx(aFile, LDistanceToMove, @LNewFilePointer, FILE_CURRENT) then
    Result := LNewFilePointer.QuadPart
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapWinErrToUnified(GetLastError());
    {$ELSE}
    Result := -GetLastError();
    {$ENDIF}
  end;
end;