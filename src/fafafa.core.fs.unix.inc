threadvar
  UnixFsLastError: LongInt; // 线程本地：保存最近一次 fs_open 的错误码（统一负码或负系统码）

function fs_errno: Integer;
begin
  Result := UnixFsLastError;
end;

function fs_open(const aPath: string; aFlags, aMode: Integer): TfsFile;
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
    ESysENOTSUP, ESysEOPNOTSUPP: Exit(-8);
    ESysEIO: Exit(-9);
  else
    Exit(-999);
  end;
end;
{$ENDIF}

begin
  Result := fpopen(aPath, aFlags, aMode);
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
  FillChar(aFsStat, SizeOf(TfsStat), 0);
  aFsStat.Dev := aUnixStat.st_dev;
  aFsStat.Mode := aUnixStat.st_mode;
  aFsStat.NLink := aUnixStat.st_nlink;
  aFsStat.UID := aUnixStat.st_uid;
  aFsStat.GID := aUnixStat.st_gid;
  aFsStat.RDev := aUnixStat.st_rdev;
  aFsStat.Ino := aUnixStat.st_ino;
  aFsStat.Size := aUnixStat.st_size;
  aFsStat.BlkSize := aUnixStat.st_blksize;

function fs_replace(const aSrc, aDst: string): Integer;
var
  Res: cint;
begin
  // 先试 rename（原子），若跨卷失败（EXDEV），回退 copy -> rename 替换
  Res := fprename(aSrc, aDst);
  if Res = 0 then Exit(0);
  if fpgeterrno = EXDEV then
  begin
    // 目标若存在，先移除（atomic replace 语义）
    // 使用临时路径：aDst + '.tmp-replace-' + pid
    var Tmp := aDst + '.tmp-replace-' + IntToStr(fpgetpid);
    // 尝试复制
    Res := fs_copyfile(aSrc, Tmp, 0);
    if Res < 0 then Exit(Res);
    // rename 覆盖
    Res := fprename(Tmp, aDst);
    if Res = 0 then Exit(0);
    // 清理临时
    fpunlink(Tmp);
  end;
  {$IFDEF FS_UNIFIED_ERRORS}
  Result := __MapUnixErrToUnified(fpgeterrno);
  {$ELSE}
  Result := -fpgeterrno;
  {$ENDIF}
end;

  aFsStat.Blocks := aUnixStat.st_blocks;

  // 设置时间字段（秒部分）
  aFsStat.ATime.Sec := aUnixStat.st_atime;
  aFsStat.MTime.Sec := aUnixStat.st_mtime;
  aFsStat.CTime.Sec := aUnixStat.st_ctime;

  // 纳秒部分在标准TStat中不可用，设置为0
  aFsStat.ATime.Nsec := 0;
  aFsStat.MTime.Nsec := 0;
  aFsStat.CTime.Nsec := 0;

  // Unix系统不支持的字段设置为0（已通过FillChar初始化）
  // aFsStat.Flags := 0;
  // aFsStat.Gen := 0;
  // aFsStat.BTime := 0; // Birth time不被大多数Unix系统支持
end;

function fs_stat(const aPath: string; out aStat: TfsStat): Integer;
var
  LStat: TStat;
begin
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
  if fptruncate(aFile, aOffset) = 0 then
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
    LEntry := fpreaddir(LDir);
    while LEntry <> nil do
    begin
      if (LEntry^.d_name <> '.') and (LEntry^.d_name <> '..') then
      begin
        aEntries.Add(LEntry^.d_name);
      end;
      LEntry := fpreaddir(LDir);
    end;
    Result := 0;
  finally
    fpclosedir(LDir);
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
    LEntry := fpreaddir(LDir);
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
      LEntry := fpreaddir(LDir);
    end;
  finally
    fpclosedir(LDir);
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
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_EXCL, S_IRWXU)
    else
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
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
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_EXCL, S_IRWXU)
    else
      OutFd := fpopen(aNewPath, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
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
      LOutFile := fs_open(aNewPath, O_WRONLY or O_CREAT or O_EXCL, S_IRWXU)
    else
      LOutFile := fs_open(aNewPath, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
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
  if fpfchmod(aFile, aMode) = 0 then
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
  if fputimes(aPath, @LTimes) = 0 then
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
  if fpfutimes(aFile, @LTimes) = 0 then
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
  LRealPath: PChar;
begin
  LRealPath := fprealpath(PChar(aPath), nil);
  if LRealPath = nil then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
    Exit;
  end;

  try
    if StrLen(LRealPath) >= aSize then
    begin
      {$IFDEF FS_UNIFIED_ERRORS}
      Result := __MapUnixErrToUnified(ESysENAMETOOLONG);
      {$ELSE}
      Result := -ESysENAMETOOLONG;
      {$ENDIF}
      Exit;
    end;

    StrCopy(aResolvedPath, LRealPath);
    Result := StrLen(LRealPath);
  finally
    fpfree(LRealPath);
  end;
end;

function fs_mkdtemp(const aTemplate: string): string;
var
  LTemplate: string;
  LResult: PChar;
begin
  Result := '';
  LTemplate := aTemplate;

  // 确保模板以6个X结尾
  if not LTemplate.EndsWith('XXXXXX') then
    LTemplate := LTemplate + 'XXXXXX';

  LResult := fpmkdtemp(PChar(LTemplate));
  if LResult <> nil then
    Result := string(LResult);
end;

function fs_mkstemp(const aTemplate: string): TfsFile;
var
  LTemplate: string;
begin
  LTemplate := aTemplate;

  // 确保模板以6个X结尾
  if not LTemplate.EndsWith('XXXXXX') then
    LTemplate := LTemplate + 'XXXXXX';

  Result := fpmkstemp(PChar(LTemplate));
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
  end;
end;

function fs_mkstemp_ex(const aTemplate: string; out aPath: string): TfsFile;
var
  LTemplate: string;
  Buf: array[0..4095] of Char;
  R: Integer;
begin
  aPath := '';
  LTemplate := aTemplate;
  if not LTemplate.EndsWith('XXXXXX') then
    LTemplate := LTemplate + 'XXXXXX';

  Result := fpmkstemp(PChar(LTemplate));
  if Result = -1 then
  begin
    {$IFDEF FS_UNIFIED_ERRORS}
    Result := __MapUnixErrToUnified(fpgeterrno);
    {$ELSE}
    Result := -fpgeterrno;
    {$ENDIF}
    Exit;
  end;

  // 获取真实路径
  R := fs_realpath(LTemplate, @Buf[0], Length(Buf));
  if R >= 0 then
    SetString(aPath, PChar(@Buf[0]), R)
  else
    aPath := LTemplate;
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