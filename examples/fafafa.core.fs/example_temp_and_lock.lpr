{$CODEPAGE UTF8}
program example_temp_and_lock;
{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.fs;

procedure DemoTempAndLock;
var
  tmpfile: string;
  fh: TfsFile;
  rc: Integer;
begin
  WriteLn('--- mkstemp/mkdtemp + flock demo ---');

  // mkstemp_ex: 得到句柄与最终路径
  fh := fs_mkstemp_ex('myapp_tmp_XXXXXX', tmpfile);
  if IsValidHandle(fh) then
  begin
    WriteLn('mkstemp_ex OK: ', tmpfile);
    // Windows: fs_flock 仅提供基本互斥/共享，语义与 POSIX 有差异
    rc := fs_flock(fh, LOCK_EX);
    if rc = 0 then
      WriteLn('locked (exclusive)')
    else
      WriteLn('lock failed: ', rc);
    fs_flock(fh, LOCK_UN);
    fs_close(fh);
    fs_unlink(tmpfile);
  end
  else
    WriteLn('mkstemp_ex failed');

  // mkdtemp: 返回目录路径
  tmpfile := fs_mkdtemp('myapp_dir_XXXXXX');
  if tmpfile <> '' then
  begin
    WriteLn('mkdtemp OK: ', tmpfile);
    fs_rmdir(tmpfile);
  end
  else
    WriteLn('mkdtemp failed');
end;

begin
  DemoTempAndLock;
end.

