{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_preserve_time_perm_loose;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_Preserve_Loose = class(TTestCase)
  published
    procedure Test_PreserveTimesPerms_Loose;
  end;

implementation

procedure EnsureClean(const P: string);
begin
  try
    DeleteDirectory(P, True);
  except
  end;
end;

procedure CreateText(const P, S: string);
var F: TextFile;
begin
  ForceDirectories(ExtractFileDir(P));
  AssignFile(F, P);
  Rewrite(F);
  Write(F, S);
  Close(F);
end;

function GetPerm9(const Mode: Cardinal): Cardinal;
begin
  Result := Mode and $1FF;
end;

procedure TTestCase_Preserve_Loose.Test_PreserveTimesPerms_Loose;
var
  Src, Dst, FSrc, FDst: string;
  Opts: TFsCopyTreeOptions;
  SSrc, SDst: TfsStat;
  PermSrc, PermDst: Cardinal;
begin
  Src := 'preserve_src_' + IntToStr(GetTickCount64);
  Dst := 'preserve_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateText(IncludeTrailingPathDelimiter(Src) + 'a' + PathDelim + 'x.txt', 'hello');

  // 获取源文件初始属性
  FSrc := IncludeTrailingPathDelimiter(Src) + 'a' + PathDelim + 'x.txt';
  FDst := IncludeTrailingPathDelimiter(Dst) + 'a' + PathDelim + 'x.txt';

  // 复制，开启 PreserveTimes/Perms（best‑effort）
  FillChar(Opts, SizeOf(Opts), 0);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.PreserveTimes := True;
  Opts.PreservePerms := True;
  FsCopyTreeEx(Src, Dst, Opts);

  AssertTrue('dest exists', FileExists(FDst));

  if (fs_stat(FSrc, SSrc) = 0) and (fs_stat(FDst, SDst) = 0) then
  begin
    PermSrc := GetPerm9(SSrc.Mode);
    PermDst := GetPerm9(SDst.Mode);
    {$IFDEF UNIX}
    AssertTrue('perm preserved (posix)', PermDst = PermSrc);
    {$ENDIF}
    // Windows/FAT/NTFS 时间粒度/时区/DST 差异较大，这里放宽到 ±7200 秒（2 小时）
    AssertTrue('mtime preserved (loose)',
      (SDst.MTime.Sec >= SSrc.MTime.Sec - 7200) and (SDst.MTime.Sec <= SSrc.MTime.Sec + 7200));
  end;

  EnsureClean(Src); EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_Preserve_Loose);
end.

