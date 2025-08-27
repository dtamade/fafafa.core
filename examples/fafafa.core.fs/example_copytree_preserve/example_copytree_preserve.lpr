{$CODEPAGE UTF8}
program example_copytree_preserve;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.fs, fafafa.core.fs.path, fafafa.core.fs.highlevel;

procedure WriteLine(const S: string);
begin
  WriteLn(S);
end;

function MakeTmp(const Prefix: string): string;
var Base: string;
begin
  Base := IncludeTrailingPathDelimiter(GetTempDir(False));
  Result := Base + Prefix + IntToStr(GetTickCount64) + '_' + IntToStr(Random(100000));
  ForceDirectories(Result);
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

procedure DemoPreserve;
var
  SrcRoot, DstRoot, FSrc, FDst: string;
  Opts: TFsCopyTreeOptions;
  SSrc, SDst: TfsStat;
  PermSrc, PermDst: Cardinal;
begin
  Randomize;
  SrcRoot := MakeTmp('ex_copytree_preserve_src_');
  DstRoot := MakeTmp('ex_copytree_preserve_dst_');

  // 创建源目录结构
  CreateText(IncludeTrailingPathDelimiter(SrcRoot) + 'a' + PathDelim + 'x.txt', 'hello');

  // 获取源文件初始属性
  FSrc := IncludeTrailingPathDelimiter(SrcRoot) + 'a' + PathDelim + 'x.txt';
  FDst := IncludeTrailingPathDelimiter(DstRoot) + 'a' + PathDelim + 'x.txt';

  // 复制，开启 PreserveTimes/Perms（best‑effort）
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.PreserveTimes := True;
  Opts.PreservePerms := True;
  FsCopyTreeEx(SrcRoot, DstRoot, Opts);

  WriteLine('Copy done. Checking attributes (best‑effort)...');
  if (fs_stat(FSrc, SSrc) = 0) and (fs_stat(FDst, SDst) = 0) then
  begin
    // 权限对比（POSIX 有效；Windows 仅做占位打印）
    PermSrc := (SSrc.Mode and $1FF); // 低 9 位
    PermDst := (SDst.Mode and $1FF);
    WriteLine('perm(src,dst) = ' + IntToHex(PermSrc, 3) + ', ' + IntToHex(PermDst, 3));
    WriteLine('mtime(src,dst) = ' + IntToStr(SSrc.MTime.Sec) + ', ' + IntToStr(SDst.MTime.Sec));

    {$IFDEF WINDOWS}
    WriteLine('Note: Windows 权限模型与 POSIX 不同，权限保留仅作 best‑effort；建议使用 ACL 工具链管理权限');
    {$ENDIF}
  end
  else
    WriteLine('fs_stat failed (one of files missing?)');

  // 清理（best‑effort）
  try
    DeleteDirectory(SrcRoot, True);
  except end;
  try
    DeleteDirectory(DstRoot, True);
  except end;
end;

begin
  WriteLine('=== example_copytree_preserve ===');
  DemoPreserve;
end.

