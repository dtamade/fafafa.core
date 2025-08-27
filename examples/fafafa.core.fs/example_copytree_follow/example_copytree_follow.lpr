{$CODEPAGE UTF8}
program example_copytree_follow;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.fs, fafafa.core.fs.highlevel, fafafa.core.fs.path;

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
  AssignFile(F, P);
  ForceDirectories(ExtractFileDir(P));
  Rewrite(F);
  Write(F, S);
  Close(F);
end;

function EnvEnabled: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('FAFAFA_TEST_SYMLINK') = '1';
  {$ELSE}
  Result := GetEnvironmentVariable('FAFAFA_TEST_SYMLINK') <> '0';
  {$ENDIF}
end;

var
  R, A, B, LinkAtoB, DstFalse, DstTrue: string;
  Opts: TFsCopyTreeOptions;
begin
  if not EnvEnabled then
  begin
    Writeln('Symlink example skipped. Set FAFAFA_TEST_SYMLINK=1 on Windows (or !=0 on Unix) to run.');
    Halt(0);
  end;

  Randomize;
  R := 'ex_copytree_symlink_' + IntToStr(Random(1000000));
  A := IncludeTrailingPathDelimiter(R) + 'A';
  B := IncludeTrailingPathDelimiter(R) + 'B';
  DstFalse := R + '_dst_false';
  DstTrue := R + '_dst_true';
  EnsureClean(R); EnsureClean(DstFalse); EnsureClean(DstTrue);
  CreateDirectory(R, True);
  CreateDirectory(A, True);
  CreateDirectory(B, True);
  CreateText(IncludeTrailingPathDelimiter(B) + 'file.txt', 'hello');

  LinkAtoB := IncludeTrailingPathDelimiter(A) + 'to_B';
  {$IFDEF UNIX}
  fpSymlink(PChar('../B'), PChar(LinkAtoB));
  {$ELSE}
  if fs_symlink('../B', LinkAtoB) <> 0 then begin
    Writeln('Symlink creation not permitted on this system; exiting.');
    Halt(0);
  end;
  {$ENDIF}

  Opts.Overwrite := True;
  Opts.PreserveTimes := False;
  Opts.PreservePerms := False;

  // Follow=false: skip link and its target
  Opts.FollowSymlinks := False;
  FsCopyTreeEx(R, DstFalse, Opts);
  Writeln('FollowSymlinks=False => exists A/to_B? ', DirectoryExists(DstFalse + PathDelim + 'A' + PathDelim + 'to_B'));
  Writeln('FollowSymlinks=False => exists B/file.txt? ', FileExists(DstFalse + PathDelim + 'B' + PathDelim + 'file.txt'));

  // Follow=true: copy target content under A/to_B
  Opts.FollowSymlinks := True;
  FsCopyTreeEx(R, DstTrue, Opts);
  Writeln('FollowSymlinks=True => exists A/to_B/file.txt? ', FileExists(DstTrue + PathDelim + 'A' + PathDelim + 'to_B' + PathDelim + 'file.txt'));

  // cleanup best-effort
  EnsureClean(R); EnsureClean(DstFalse); EnsureClean(DstTrue);
end.

