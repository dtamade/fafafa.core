unit fafafa.core.fs.copyaccel;

{$mode objfpc}{$H+}

{!
  内核加速复制/移动（CopyAccel）
  - 不改变对外 API；供内部调用选择更优路径（如 CopyFile2/copy_file_range）

  Issue #6: 实现 Linux copy_file_range 支持
  - Linux >= 4.5: 使用 copy_file_range(2) 系统调用
  - 回退: 使用 sendfile(2) (Linux >= 2.2)
  - 都不可用时返回 -999 让调用方回退到常规复制

  控制：
    * 编译期：定义 FAFAFA_CORE_FS_DISABLE_COPYACCEL 则始终禁用
    * 运行时：环境变量 FAFAFA_FS_COPYACCEL=0 禁用，=1 启用（默认启用）
}

interface

uses
  SysUtils
  {$IFDEF WINDOWS}
  , Windows, fafafa.core.fs.errors
  {$ENDIF}
  {$IFDEF LINUX}
  , BaseUnix, Unix
  {$ENDIF};

// 运行时是否启用 CopyAccel（受编译宏与环境变量控制）
function FsCopyAccelIsEnabled: Boolean;

// 试图使用内核加速路径复制单个文件；
// 返回：0 成功；<0 FsErrorCode 负码；若未采用加速路径，aUsedAccel=False 且可由调用方回退
function FsCopyAccelTryCopyFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;

// 简化版本（不返回是否使用加速）
function FsCopyAccelTryCopyFile(const aSrc, aDst: string): Integer;

// 试图使用内核加速路径移动单个文件；其余语义与 FsCopyAccelTryCopyFile 相同
function FsCopyAccelTryMoveFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;

// 简化版本（不返回是否使用加速）
function FsCopyAccelTryMoveFile(const aSrc, aDst: string): Integer;

implementation

{$IFDEF LINUX}
uses
  fafafa.core.fs.errors, Syscall;

const
  // copy_file_range 系统调用号 (x86_64)
  SYS_copy_file_range = 326;
  // sendfile 系统调用号 (x86_64)
  SYS_sendfile = 40;

// copy_file_range(2) wrapper
// Linux >= 4.5: 零拷贝内核复制
function copy_file_range(fd_in: cint; off_in: PInt64; fd_out: cint; off_out: PInt64;
  len: size_t; flags: cuint): Int64;
begin
  Result := do_SysCall(SYS_copy_file_range, TSysParam(fd_in), TSysParam(off_in),
    TSysParam(fd_out), TSysParam(off_out), TSysParam(len), TSysParam(flags));
end;

// sendfile(2) wrapper
// Linux >= 2.2: 也支持文件到文件复制
function linux_sendfile(out_fd: cint; in_fd: cint; offset: PInt64; count: size_t): Int64;
begin
  Result := do_SysCall(SYS_sendfile, TSysParam(out_fd), TSysParam(in_fd),
    TSysParam(offset), TSysParam(count));
end;

// ✅ Issue #6: Linux 加速复制实现
function LinuxCopyFileAccel(const aSrc, aDst: string; aOverwrite: Boolean): Integer;
var
  fd_in, fd_out: cint;
  stat_buf: TStat;
  copied, len: Int64;
  flags: cint;
  in_offset, out_offset: Int64;
begin
  Result := -999;
  stat_buf := Default(TStat);

  // 打开源文件
  fd_in := fpOpen(aSrc, O_RDONLY);
  if fd_in < 0 then
    Exit(Integer(SystemErrorToFsError(fpGetErrno)));

  try
    // 获取源文件大小
    if fpFStat(fd_in, stat_buf) < 0 then
      Exit(Integer(SystemErrorToFsError(fpGetErrno)));

    // 打开/创建目标文件
    flags := O_WRONLY or O_CREAT or O_TRUNC;
    if not aOverwrite then
      flags := flags or O_EXCL;

    fd_out := fpOpen(aDst, flags, &644);
    if fd_out < 0 then
      Exit(Integer(SystemErrorToFsError(fpGetErrno)));

    try
      len := stat_buf.st_size;
      if len = 0 then
      begin
        // 空文件，直接成功
        Exit(0);
      end;

      // 尝试 copy_file_range (Linux >= 4.5)
      in_offset := 0;
      out_offset := 0;
      copied := copy_file_range(fd_in, @in_offset, fd_out, @out_offset, len, 0);

      if copied >= 0 then
      begin
        // copy_file_range 可能需要多次调用
        while copied < len do
        begin
          copied := copied + copy_file_range(fd_in, @in_offset, fd_out, @out_offset, len - copied, 0);
          if copied < 0 then Break;
        end;

        if copied >= len then
          Exit(0);
      end;

      // copy_file_range 失败，尝试 sendfile
      if (copied < 0) and (fpGetErrno = ESysENOSYS) or (fpGetErrno = ESysEXDEV) then
      begin
        // 重新定位到文件开头
        fpLSeek(fd_in, 0, SEEK_SET);
        fpLSeek(fd_out, 0, SEEK_SET);

        // sendfile 循环复制
        copied := 0;
        while copied < len do
        begin
          in_offset := copied;
          Result := linux_sendfile(fd_out, fd_in, @in_offset, len - copied);
          if Result <= 0 then
          begin
            if Result < 0 then
              Result := Integer(SystemErrorToFsError(fpGetErrno))
            else
              Result := -999; // 无法继续
            Exit;
          end;
          copied := copied + Result;
        end;
        Exit(0);
      end;

      // 两种方法都失败
      if copied < 0 then
        Result := Integer(SystemErrorToFsError(fpGetErrno))
      else
        Result := -999; // 回退到常规复制

    finally
      fpClose(fd_out);
    end;
  finally
    fpClose(fd_in);
  end;
end;

{$ENDIF}

function EnvEnabled: Boolean;
var
  V: String;
begin
  V := GetEnvironmentVariable('FAFAFA_FS_COPYACCEL');
  if V = '' then Exit(True);
  Result := not ((V = '0') or (LowerCase(V) = 'false'));
end;

function FsCopyAccelIsEnabled: Boolean;
begin
  {$IFDEF FAFAFA_CORE_FS_DISABLE_COPYACCEL}
  Exit(False);
  {$ENDIF}
  Result := EnvEnabled;
end;

function FsCopyAccelTryCopyFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;
begin
  aUsedAccel := False;

  if not FsCopyAccelIsEnabled then
  begin
    Result := -999;
    Exit;
  end;

  {$IFDEF WINDOWS}
  aUsedAccel := True;
  if aOverwrite then
    Windows.DeleteFileW(PWideChar(UTF8Decode(aDst)));
  if CopyFileExW(PWideChar(UTF8Decode(aSrc)), PWideChar(UTF8Decode(aDst)), nil, nil, nil, 0) then
    Exit(0);
  Result := Integer(SystemErrorToFsError(GetLastError()));
  {$ELSE}
  {$IFDEF LINUX}
  // ✅ Issue #6: Linux copy_file_range/sendfile 加速
  Result := LinuxCopyFileAccel(aSrc, aDst, aOverwrite);
  if Result = 0 then
    aUsedAccel := True;
  {$ELSE}
  // macOS/其他平台暂未实现加速
  if (aSrc = '') and (aDst = '') and (aOverwrite = aOverwrite) then
    aUsedAccel := False;
  Result := -999;
  {$ENDIF}
  {$ENDIF}
end;

function FsCopyAccelTryCopyFile(const aSrc, aDst: string): Integer;
var
  Dummy: Boolean;
begin
  Result := FsCopyAccelTryCopyFile(aSrc, aDst, True, Dummy);
end;

function FsCopyAccelTryMoveFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;
{$IFDEF WINDOWS}
var
  Flags: DWORD;
{$ENDIF}
{$IFDEF LINUX}
var
  R: cint;
{$ENDIF}
begin
  aUsedAccel := False;

  if not FsCopyAccelIsEnabled then
  begin
    Result := -999;
    Exit;
  end;

  {$IFDEF WINDOWS}
  aUsedAccel := True;
  Flags := MOVEFILE_COPY_ALLOWED;
  if aOverwrite then
    Flags := Flags or MOVEFILE_REPLACE_EXISTING;
  if MoveFileExW(
       PWideChar(UTF8Decode(aSrc)),
       PWideChar(UTF8Decode(aDst)),
       Flags
     ) then
    Exit(0);
  Result := Integer(SystemErrorToFsError(GetLastError()));
  {$ELSE}
  {$IFDEF LINUX}
  // ✅ Issue #6: Linux 使用 rename(2) 加速移动
  // 先删除目标（如果允许覆盖）
  if aOverwrite then
    fpUnlink(aDst);

  R := fpRename(aSrc, aDst);
  if R = 0 then
  begin
    aUsedAccel := True;
    Exit(0);
  end;

  // rename 失败（可能跨文件系统），尝试 copy + unlink
  if fpGetErrno = ESysEXDEV then
  begin
    Result := LinuxCopyFileAccel(aSrc, aDst, aOverwrite);
    if Result = 0 then
    begin
      fpUnlink(aSrc);
      aUsedAccel := True;
    end;
    Exit;
  end;

  Result := Integer(SystemErrorToFsError(fpGetErrno));
  {$ELSE}
  // macOS/其他平台暂未实现加速
  if (aSrc = '') and (aDst = '') and (aOverwrite = aOverwrite) then
    aUsedAccel := False;
  Result := -999;
  {$ENDIF}
  {$ENDIF}
end;

function FsCopyAccelTryMoveFile(const aSrc, aDst: string): Integer;
var
  Dummy: Boolean;
begin
  Result := FsCopyAccelTryMoveFile(aSrc, aDst, True, Dummy);
end;

end.

