threadvar
  UnixFsLastError: LongInt; // 线程本地：保存最近一次 fs_open 的错误码（统一负码或负系统码）

function fs_errno: Integer;
begin
  Result := UnixFsLastError;
end;

{$IFDEF FS_UNIFIED_ERRORS}
function __MapUnixErrToUnified(aErr: LongInt): Integer; inline;
begin
  case aErr of
    0: Exit(0);
    ESysENOENT: Exit(-2);
    ESysEACCES: Exit(-3);
    ESysEPERM: Exit(-10);
    ESysENOSPC: Exit(-4);
    ESysEINVAL: Exit(-8);
    ESysEEXIST: Exit(-6);
    ESysENOTEMPTY: Exit(-7);
    ESysENAMETOOLONG: Exit(-5);
    ESysEXDEV: Exit(-8); // 近似归为 invalid/unsupported 类
    ESysENOTDIR: Exit(-8);
    ESysEISDIR: Exit(-8);
    ESysEBUSY: Exit(-3); // 归入权限/占用类
    ESysETIMEDOUT: Exit(-8);
    {$if declared(ESysENOTSUP)}
      {$if ESysENOTSUP <> ESysEOPNOTSUPP}
      ESysENOTSUP: Exit(-8);
      {$endif}
    {$endif}
    ESysEOPNOTSUPP: Exit(-8);
    ESysEIO: Exit(-9);
  else
    Exit(-999);
  end;
end;
{$ENDIF}

{$if not declared(DT_DIR)}
const
  // Linux dirent.d_type values (avoid relying on DT_* availability in RTL)
  DT_DIR = 4;
  DT_REG = 8;
  DT_LNK = 10;
{$endif}

const
  // ✅ 安全修复：定义合理的默认文件权限
  // 0644 = rw-r--r-- (用户读写，组和其他只读)
  // 比 S_IRWXU (0700) 更安全，因为不包含执行权限
  FS_DEFAULT_FILE_MODE = S_IRUSR or S_IWUSR or S_IRGRP or S_IROTH;

// libc wrappers missing from BaseUnix on some RTL/FPC versions
function c_fchmod(fd: cint; mode: mode_t): cint; cdecl; external 'c' name 'fchmod';
function c_utimes(filename: PChar; times: Pointer): cint; cdecl; external 'c' name 'utimes';
function c_futimes(fd: cint; times: Pointer): cint; cdecl; external 'c' name 'futimes';
function c_mkdtemp(template: PChar): PChar; cdecl; external 'c' name 'mkdtemp';
function c_mkstemp(template: PChar): cint; cdecl; external 'c' name 'mkstemp';
function c_realpath(path: PChar; resolved_path: PChar): PChar; cdecl; external 'c' name 'realpath';  // ✅ 真正的 realpath

function fs_open(const aPath: string; aFlags, aMode: Integer): TfsFile;
var
  LFlags: Integer;
begin
  // Unix: ignore Windows share flags; they are not valid for fpopen/open(2)
  LFlags := aFlags and (not O_SHARE_MASK);

  Result := fpopen(aPath, LFlags, aMode);
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    UnixFsLastError := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    UnixFsLastError := -fpgeterrno;
    {$ENDIF}
    Exit(INVALID_HANDLE_VALUE);
  end
  else
  begin
    UnixFsLastError := 0;
  end;
end;

function fs_close(aFile: TfsFile): Integer;
begin
  if fpclose(aFile) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_read(aFile: TfsFile; const aBuffer: Pointer; aLength: SizeUInt; aOffset: Int64): Integer;
begin
  {$IFDEF FS_USE_PREAD}
  if aOffset <> -1 then
  begin
    Result := fppread(aFile, aBuffer^, aLength, aOffset);
    if Result = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapUnixErrToUnified(fpgeterrno);
      {$ELSE}
      Result := -fpgeterrno;
      {$ENDIF}
    end;
    Exit;
  end;
  {$ELSE}
  if aOffset <> -1 then
  begin
    if fplseek(aFile, aOffset, SEEK_SET) = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapUnixErrToUnified(fpgeterrno);
      {$ELSE}
      Result := -fpgeterrno;
      {$ENDIF}
      Exit;
    end;
  end;
  {$ENDIF}
  Result := fpread(aFile, aBuffer^, aLength);
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_write(aFile: TfsFile; const aBuffer: Pointer; aLength: SizeUInt; aOffset: Int64): Integer;
begin
  {$IFDEF FS_USE_PREAD}
  if aOffset <> -1 then
  begin
    Result := fppwrite(aFile, aBuffer^, aLength, aOffset);
    if Result = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapUnixErrToUnified(fpgeterrno);
      {$ELSE}
      Result := -fpgeterrno;
      {$ENDIF}
    end;
    Exit;
  end;
  {$ELSE}
  if aOffset <> -1 then
  begin
    if fplseek(aFile, aOffset, SEEK_SET) = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapUnixErrToUnified(fpgeterrno);
      {$ELSE}
      Result := -fpgeterrno;
      {$ENDIF}
      Exit;
    end;
  end;
  {$ENDIF}
  Result := fpwrite(aFile, aBuffer^, aLength);
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_unlink(const aPath: string): Integer;
begin
  if fpunlink(aPath) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_rename(const aOldPath, aNewPath: string): Integer;
begin
  if fprename(aOldPath, aNewPath) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_mkdir(const aPath: string; aMode: Integer): Integer;
begin
  if fpmkdir(aPath, aMode) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_rmdir(const aPath: string): Integer;
begin
  if fprmdir(aPath) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

procedure UnixStatToFsStat(const aUnixStat: TStat; out aFsStat: TfsStat);
begin
  aFsStat := Default(TfsStat);
  aFsStat.Dev := aUnixStat.st_dev;
  aFsStat.Mode := aUnixStat.st_mode;
  aFsStat.NLink := aUnixStat.st_nlink;
  aFsStat.UID := aUnixStat.st_uid;
  aFsStat.GID := aUnixStat.st_gid;
  aFsStat.RDev := aUnixStat.st_rdev;
  aFsStat.Ino := aUnixStat.st_ino;
  aFsStat.Size := aUnixStat.st_size;
  aFsStat.BlkSize := aUnixStat.st_blksize;
  aFsStat.Blocks := aUnixStat.st_blocks;

  // 设置时间字段（秒部分）
  aFsStat.ATime.Sec := aUnixStat.st_atime;
  aFsStat.MTime.Sec := aUnixStat.st_mtime;
  aFsStat.CTime.Sec := aUnixStat.st_ctime;

  // 纳秒部分在标准 TStat 中不可用，设置为 0
  aFsStat.ATime.Nsec := 0;
  aFsStat.MTime.Nsec := 0;
  aFsStat.CTime.Nsec := 0;
end;

function fs_replace(const aSrc, aDst: string): Integer;
var
  Res: cint;
  Err: cint;
  Tmp: string;
begin
  // 先试 rename（原子），若跨卷失败（EXDEV），回退 copy -> rename 替换
  Res := fprename(aSrc, aDst);
  if Res = 0 then Exit(0);

  Err := fpgeterrno;
  if Err = ESysEXDEV then
  begin
    // 使用临时路径：aDst + '.tmp-replace-' + pid
    Tmp := aDst + '.tmp-replace-' + IntToStr(fpgetpid);

    // 尝试复制
    Res := fs_copyfile(aSrc, Tmp, 0);
    if Res < 0 then Exit(Res);

    // rename 覆盖
    Res := fprename(Tmp, aDst);
    if Res = 0 then Exit(0);

    Err := fpgeterrno;
    // 清理临时（不要再读取 fpgeterrno，以免覆盖 Err）
    fpunlink(Tmp);
  end;

  {$IFDEF FS_UNIFIED_ERRORS}
  Result := __MapUnixErrToUnified(Err);
  {$ELSE}
  Result := -Err;
  {$ENDIF}
end;

function fs_stat(const aPath: string; out aStat: TfsStat): Integer;
var
  LStat: TStat;
begin
  LStat := Default(TStat);
  if fpstat(aPath, LStat) = 0 then
  begin
    UnixStatToFsStat(LStat, aStat);
    Result := 0;
  end
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_lstat(const aPath: string; out aStat: TfsStat): Integer;
var
  LStat: TStat;
begin
  LStat := Default(TStat);
  if fplstat(aPath, LStat) = 0 then
  begin
    UnixStatToFsStat(LStat, aStat);
    Result := 0;
  end
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_fstat(aFile: TfsFile; out aStat: TfsStat): Integer;
var
  LStat: TStat;
begin
  LStat := Default(TStat);
  if fpfstat(aFile, LStat) = 0 then
  begin
    UnixStatToFsStat(LStat, aStat);
    Result := 0;
  end
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_ftruncate(aFile: TfsFile; aOffset: Int64): Integer;
begin
  if fpftruncate(aFile, aOffset) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_scandir(const aPath: string; var aEntries: TStringList): Integer;
var
  LDir: PDir;
  LEntry: PDirent;
begin
  aEntries.Clear;
  LDir := fpopendir(aPath);
  if LDir = nil then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
    Exit;
  end;

  try
    LEntry := fpreaddir(LDir^);
    while LEntry <> nil do
    begin
      if (LEntry^.d_name <> '.') and (LEntry^.d_name <> '..') then
      begin
        aEntries.Add(LEntry^.d_name);
      end;
      LEntry := fpreaddir(LDir^);
    end;
    Result := 0;
  finally
    fpclosedir(LDir^);
  end;
end;

function fs_scandir_each(const aPath: string; aOnEntry: TfsScandirEachProc): Integer;
var
  LDir: PDir;
  LEntry: PDirent;
  LType: TfsDirEntType;
begin
  Result := 0;
  if not Assigned(aOnEntry) then Exit(0);

  LDir := fpopendir(aPath);
  if LDir = nil then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Exit(__MapUnixErrToUnified(fpgeterrno));
    {$ELSE}
    Exit(-fpgeterrno);
    {$ENDIF}
  end;
  try
    LEntry := fpreaddir(LDir^);
    while LEntry <> nil do
    begin
      if (LEntry^.d_name <> '.') and (LEntry^.d_name <> '..') then
      begin
        // 基本类型（注意 d_type 在部分文件系统可能为 DT_UNKNOWN，此时标 Unknown）
        case LEntry^.d_type of
          DT_DIR:  LType := fsDETDir;
          DT_LNK:  LType := fsDETSymlink;
          DT_REG:  LType := fsDETFile;
        else
          LType := fsDETUnknown;
        end;
        if not aOnEntry(LEntry^.d_name, LType) then Exit(0);
      end;
      LEntry := fpreaddir(LDir^);
    end;
  finally
    fpclosedir(LDir^);
  end;
end;


function fs_copyfile(const aPath, aNewPath: string; aFlags: Integer): Integer;
{$IFDEF HAS_COPY_FILE_RANGE}
var
  InFd, OutFd: cint;
  OffIn, OffOut: off_t;
  N: ssize_t;
begin
  InFd := fpopen(aPath, O_RDONLY);
  if InFd = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS} Exit(__MapUnixErrToUnified(fpgeterrno)); {$ELSE} Exit(-fpgeterrno); {$ENDIF}
  end;
  try
    if (aFlags and UV_FS_COPYFILE_EXCL) <> 0 then
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_EXCL, FS_DEFAULT_FILE_MODE)
    else
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_TRUNC, FS_DEFAULT_FILE_MODE);
    if OutFd = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS} Result := __MapUnixErrToUnified(fpgeterrno); {$ELSE} Result := -fpgeterrno; {$ENDIF}
      Exit;
    end;
    try
      OffIn := 0; OffOut := 0;
      repeat
        N := copy_file_range(InFd, @OffIn, OutFd, @OffOut, 1 shl 20, 0);
        if N = 0 then Break; // EOF
        if N = -1 then
        begin
          {$IFDEF FS_UNIFIED_ERRORS} Result := __MapUnixErrToUnified(fpgeterrno); {$ELSE} Result := -fpgeterrno; {$ENDIF}
          Exit;
        end;
      until False;
      Result := 0;
    finally
      fpclose(OutFd);
    end;
  finally
    fpclose(InFd);
  end;
{$ELSEIF DEFINED(HAS_SENDFILE)}
var
  InFd, OutFd: cint;
  Off: off_t;
  N: ssize_t;
begin
  InFd := fpopen(aPath, O_RDONLY);
  if InFd = -1 then begin {$IFDEF FS_UNIFIED_ERRORS} Exit(__MapUnixErrToUnified(fpgeterrno)); {$ELSE} Exit(-fpgeterrno); {$ENDIF} end;
  try
    if (aFlags and UV_FS_COPYFILE_EXCL) <> 0 then
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_EXCL, FS_DEFAULT_FILE_MODE)
    else
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_TRUNC, FS_DEFAULT_FILE_MODE);
    if OutFd = -1 then begin {$IFDEF FS_UNIFIED_ERRORS} Result := __MapUnixErrToUnified(fpgeterrno); {$ELSE} Result := -fpgeterrno; {$ENDIF} Exit; end;
    try
      Off := 0;
      repeat
        N := sendfile(OutFd, InFd, @Off, 1 shl 20);
        if N = 0 then Break; // EOF (某些实现返回0表示完成)
        if N = -1 then begin {$IFDEF FS_UNIFIED_ERRORS} Result := __MapUnixErrToUnified(fpgeterrno); {$ELSE} Result := -fpgeterrno; {$ENDIF} Exit; end;
      until False;
      Result := 0;
    finally
      fpclose(OutFd);
    end;
  finally
    fpclose(InFd);
  end;
{$ELSE}
var
  LInFile, LOutFile: TfsFile;
  LBuffer: array[0..65535] of byte;
  LBytesRead, LBytesWritten: Integer;
begin
  LInFile := fs_open(aPath, O_RDONLY, 0);
  if LInFile < 0 then Exit(LInFile);
  try
    if (aFlags and UV_FS_COPYFILE_EXCL) <> 0 then
      LOutFile := fs_open(aNewPath, O_WRONLY or O_CREAT or O_EXCL, FS_DEFAULT_FILE_MODE)
    else
      LOutFile := fs_open(aNewPath, O_WRONLY or O_CREAT or O_TRUNC, FS_DEFAULT_FILE_MODE);
    if LOutFile < 0 then begin Result := LOutFile; Exit; end;
    try
      repeat
        LBytesRead := fs_read(LInFile, @LBuffer[0], SizeOf(LBuffer), -1);
        if LBytesRead < 0 then begin Result := LBytesRead; Exit; end;
        if LBytesRead = 0 then Break;
        LBytesWritten := fs_write(LOutFile, @LBuffer[0], LBytesRead, -1);
        if LBytesWritten < LBytesRead then
        begin
          if LBytesWritten < 0 then Result := LBytesWritten else Result := -28;
          Exit;
        end;
      until False;
      Result := 0;
    finally
      fs_close(LOutFile);
    end;
  finally
    fs_close(LInFile);
  end;
{$ENDIF}
end;

function fs_chmod(const aPath: string; aMode: Integer): Integer;
begin
  if fpchmod(aPath, aMode) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_fchmod(aFile: TfsFile; aMode: Integer): Integer;
begin
  if c_fchmod(cint(aFile), mode_t(aMode)) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_utime(const aPath: string; aAtime, aMtime: Double): Integer;
{$IFDEF HAS_UTIMENS}
var
  TS: array[0..1] of timespec;
begin
  TS[0].tv_sec := Trunc(aAtime);
  TS[0].tv_nsec := Trunc(Frac(aAtime) * 1000000000);
  TS[1].tv_sec := Trunc(aMtime);
  TS[1].tv_nsec := Trunc(Frac(aMtime) * 1000000000);
  if futimensat(AT_FDCWD, PChar(aPath), @TS, 0) = 0 then
    Exit(0)
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Exit(__MapUnixErrToUnified(fpgeterrno));
    {$ELSE}
    Exit(-fpgeterrno);
    {$ENDIF}
  end;
{$ELSE}
var
  LTimes: array[0..1] of TTimeVal;
begin
  LTimes[0].tv_sec := Trunc(aAtime);
  LTimes[0].tv_usec := Trunc(Frac(aAtime) * 1000000);
  LTimes[1].tv_sec := Trunc(aMtime);
  LTimes[1].tv_usec := Trunc(Frac(aMtime) * 1000000);
  if c_utimes(PChar(aPath), @LTimes[0]) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
{$ENDIF}
end;

function fs_futime(aFile: TfsFile; aAtime, aMtime: Double): Integer;
{$IFDEF HAS_FUTIMENS}
var
  TS: array[0..1] of timespec;
begin
  TS[0].tv_sec := Trunc(aAtime);
  TS[0].tv_nsec := Trunc(Frac(aAtime) * 1000000000);
  TS[1].tv_sec := Trunc(aMtime);
  TS[1].tv_nsec := Trunc(Frac(aMtime) * 1000000000);
  if futimens(aFile, @TS) = 0 then
    Exit(0)
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Exit(__MapUnixErrToUnified(fpgeterrno));
    {$ELSE}
    Exit(-fpgeterrno);
    {$ENDIF}
  end;
{$ELSE}
var
  LTimes: array[0..1] of TTimeVal;
begin
  LTimes[0].tv_sec := Trunc(aAtime);
  LTimes[0].tv_usec := Trunc(Frac(aAtime) * 1000000);
  LTimes[1].tv_sec := Trunc(aMtime);
  LTimes[1].tv_usec := Trunc(Frac(aMtime) * 1000000);
  if c_futimes(cint(aFile), @LTimes[0]) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
{$ENDIF}
end;

function fs_seek(aFile: TfsFile; aOffset: Int64; aWhence: Integer): Int64;
begin
  Result := fplseek(aFile, aOffset, aWhence);
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_fsync(aFile: TfsFile): Integer;
begin
  if fpfsync(aFile) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_access(const aPath: string; aMode: Integer): Integer;
begin
  if fpaccess(PChar(aPath), aMode) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_link(const aPath, aNewPath: string): Integer;
begin
  if fplink(PChar(aPath), PChar(aNewPath)) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_symlink(const aPath, aNewPath: string): Integer;
begin
  if fpsymlink(PChar(aPath), PChar(aNewPath)) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_readlink(const aPath: string; aBuffer: PChar; aSize: SizeUInt): Integer;
begin
  Result := fpreadlink(PChar(aPath), aBuffer, aSize);
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_flock(aFile: TfsFile; aOperation: Integer): Integer;
begin
  if fpflock(aFile, aOperation) = 0 then
    Result := 0
  else
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_realpath(const aPath: string; aResolvedPath: PChar; aSize: SizeUInt): Integer;
var
  LBuf: array[0..4095] of Char;
  LResult: PChar;
  LLen: SizeUInt;
begin
  // ✅ 使用真正的 libc realpath 来解析符号链接
  LResult := c_realpath(PChar(aPath), @LBuf[0]);
  if LResult = nil then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
    Exit;
  end;

  LLen := StrLen(LResult);

  if (aSize = 0) or (LLen >= aSize) then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(ESysENAMETOOLONG);
    {$ELSE}
    Result := -ESysENAMETOOLONG;
    {$ENDIF}
    Exit;
  end;

  Move(LResult^, aResolvedPath^, LLen);
  aResolvedPath[LLen] := #0;
  Result := LLen;
end;

function fs_mkdtemp(const aTemplate: string): string;
var
  LTemplate: string;
  Buf: PChar;
  R: PChar;
  LLen: SizeInt;
begin
  Result := '';

  // Unix 语义：模板必须以 6 个 X 结尾，否则失败
  if not aTemplate.EndsWith('XXXXXX') then Exit('');

  LTemplate := aTemplate;
  // 若是相对模板，则放到系统临时目录
  if Pos(PathDelim, LTemplate) = 0 then
    LTemplate := IncludeTrailingPathDelimiter(GetTempDir) + LTemplate;

  LLen := Length(LTemplate);
  GetMem(Buf, LLen + 1);
  try
    Move(PChar(LTemplate)^, Buf^, LLen);
    Buf[LLen] := #0;
    R := c_mkdtemp(Buf);
    if R <> nil then
      Result := string(R);
  finally
    FreeMem(Buf);
  end;
end;

function fs_mkstemp(const aTemplate: string): TfsFile;
var
  LTemplate: string;
  Buf: PChar;
  LLen: SizeInt;
  Fd: cint;
begin
  // Unix 语义：模板必须以 6 个 X 结尾
  if not aTemplate.EndsWith('XXXXXX') then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    UnixFsLastError := __MapUnixErrToUnified(ESysEINVAL);
    {$ELSE}
    UnixFsLastError := -ESysEINVAL;
    {$ENDIF}
    Exit(INVALID_HANDLE_VALUE);
  end;

  LTemplate := aTemplate;
  if Pos(PathDelim, LTemplate) = 0 then
    LTemplate := IncludeTrailingPathDelimiter(GetTempDir) + LTemplate;

  LLen := Length(LTemplate);
  GetMem(Buf, LLen + 1);
  try
    Move(PChar(LTemplate)^, Buf^, LLen);
    Buf[LLen] := #0;

    Fd := c_mkstemp(Buf);
    if Fd = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      UnixFsLastError := __MapUnixErrToUnified(fpgeterrno);
      {$ELSE}
      UnixFsLastError := -fpgeterrno;
      {$ENDIF}
      Result := INVALID_HANDLE_VALUE;
    end
    else
    begin
      UnixFsLastError := 0;
      Result := Fd;
    end;
  finally
    FreeMem(Buf);
  end;
end;

function fs_mkstemp_ex(const aTemplate: string; out aPath: string): TfsFile;
var
  LTemplate: string;
  Buf: PChar;
  LLen: SizeInt;
  Fd: cint;
begin
  aPath := '';

  if not aTemplate.EndsWith('XXXXXX') then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    UnixFsLastError := __MapUnixErrToUnified(ESysEINVAL);
    {$ELSE}
    UnixFsLastError := -ESysEINVAL;
    {$ENDIF}
    Exit(INVALID_HANDLE_VALUE);
  end;

  LTemplate := aTemplate;
  if Pos(PathDelim, LTemplate) = 0 then
    LTemplate := IncludeTrailingPathDelimiter(GetTempDir) + LTemplate;

  LLen := Length(LTemplate);
  GetMem(Buf, LLen + 1);
  try
    Move(PChar(LTemplate)^, Buf^, LLen);
    Buf[LLen] := #0;

    Fd := c_mkstemp(Buf);
    if Fd = -1 then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      UnixFsLastError := __MapUnixErrToUnified(fpgeterrno);
      {$ELSE}
      UnixFsLastError := -fpgeterrno;
      {$ENDIF}
      Result := INVALID_HANDLE_VALUE;
      Exit;
    end;

    UnixFsLastError := 0;
    aPath := string(Buf);
    Result := Fd;
  finally
    FreeMem(Buf);
  end;
end;



function fs_tell(aFile: TfsFile): Int64;
begin
  Result := fplseek(aFile, 0, SEEK_CUR);
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;