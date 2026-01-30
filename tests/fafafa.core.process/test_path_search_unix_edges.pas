{$CODEPAGE UTF8}
unit test_path_search_unix_edges;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}BaseUnix, {$ENDIF}
  fafafa.core.process;

{$IFDEF UNIX}

type
  TTestCase_PathSearch_Unix_Edges = class(TTestCase)
  private
    function MakeTempDir: string;
    procedure WriteTextFile(const APath, AText: string);
    procedure Chmod(const APath: string; AMode: LongInt);
  published
    procedure Test_Path_With_Empty_Entry_Ignored;
    procedure Test_Path_With_Duplicate_Dirs;
    procedure Test_NonExecutable_File_Fails;
    procedure Test_Shebang_Invalid_Interpreter_Fails;
    procedure Test_Name_Refers_To_Directory_Fails;
  end;

{$ENDIF}

implementation

{$IFDEF UNIX}

function TTestCase_PathSearch_Unix_Edges.MakeTempDir: string;
var
  Base: string;
begin
  Base := GetTempDir(False);
  Result := IncludeTrailingPathDelimiter(Base) + 'fafafa_proc_ut_' + IntToStr(Random(1000000));
  if not CreateDir(Result) then
    raise Exception.Create('failed to create temp dir: ' + Result);
end;

procedure TTestCase_PathSearch_Unix_Edges.WriteTextFile(const APath, AText: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := AText;
    SL.SaveToFile(APath);
  finally
    SL.Free;
  end;
end;

procedure TTestCase_PathSearch_Unix_Edges.Chmod(const APath: string; AMode: LongInt);
begin
  if fpChmod(PChar(APath), AMode) <> 0 then
    raise Exception.Create('fpChmod failed: ' + APath);
end;

procedure TTestCase_PathSearch_Unix_Edges.Test_Path_With_Empty_Entry_Ignored;
var
  TD, ExePath: string;
  SI: IProcessStartInfo;
begin
  TD := MakeTempDir;
  try
    ExePath := IncludeTrailingPathDelimiter(TD) + 'uxempty';
    WriteTextFile(ExePath, '#!/bin/sh' + LineEnding + 'exit 0' + LineEnding);
    Chmod(ExePath, 493); // 0755

    // PATH 前缀包含空项（"::"），应忽略空项，不视为当前目录
    if fpSetEnv(PChar('PATH=:/bin:' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'uxempty';
    SI.SetUsePathSearch(True);
    SI.Validate; // 应通过，因为 TD 在 PATH 中；空项不影响
  finally
    try DeleteFile(ExePath); except end;
    try RemoveDir(TD); except end;
  end;
end;

procedure TTestCase_PathSearch_Unix_Edges.Test_Path_With_Duplicate_Dirs;
var
  TD, ExePath: string;
  SI: IProcessStartInfo;
begin
  TD := MakeTempDir;
  try
    ExePath := IncludeTrailingPathDelimiter(TD) + 'uxdup';
    WriteTextFile(ExePath, '#!/bin/sh' + LineEnding + 'exit 0' + LineEnding);
    Chmod(ExePath, 493); // 0755

    // 重复目录项应不影响最终可用性
    if fpSetEnv(PChar('PATH=' + TD + ':' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'uxdup';
    SI.SetUsePathSearch(True);
    SI.Validate;
  finally
    try DeleteFile(ExePath); except end;
    try RemoveDir(TD); except end;
  end;
end;

procedure TTestCase_PathSearch_Unix_Edges.Test_NonExecutable_File_Fails;
var
  TD, ExePath: string;
  SI: IProcessStartInfo;
begin
  TD := MakeTempDir;
  try
    ExePath := IncludeTrailingPathDelimiter(TD) + 'uxnoexec';
    WriteTextFile(ExePath, '#!/bin/sh' + LineEnding + 'exit 0' + LineEnding);
    Chmod(ExePath, 420); // 0644

    if fpSetEnv(PChar('PATH=' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'uxnoexec';
    SI.SetUsePathSearch(True);
    try
      SI.Validate;
      Fail('Validate should fail for non-executable file');
    except
      on E: EProcessStartError do CheckTrue(True);
    end;
  finally
    try DeleteFile(ExePath); except end;
    try RemoveDir(TD); except end;
  end;
end;

procedure TTestCase_PathSearch_Unix_Edges.Test_Shebang_Invalid_Interpreter_Fails;
var
  TD, ExePath: string;
  B: IProcessBuilder;
  C: IChild;
begin
  TD := MakeTempDir;
  try
    ExePath := IncludeTrailingPathDelimiter(TD) + 'uxbadsh';
    WriteTextFile(ExePath, '#!/nonexistent/interpreter' + LineEnding + 'exit 0' + LineEnding);
    Chmod(ExePath, 493); // 0755

    if fpSetEnv(PChar('PATH=' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    B := NewProcessBuilder.Command('uxbadsh').UsePathSearch(True);
    C := B.Start;
    // 启动应失败或返回非 0 退出码
    CheckTrue('Process should fail', not C.WaitForExit(3000) or (C.GetExitCode <> 0));
  finally
    try DeleteFile(ExePath); except end;
    try RemoveDir(TD); except end;
  end;
end;

procedure TTestCase_PathSearch_Unix_Edges.Test_Name_Refers_To_Directory_Fails;
var
  TD, DirName: string;
  SI: IProcessStartInfo;
begin
  TD := MakeTempDir;
  try
    DirName := IncludeTrailingPathDelimiter(TD) + 'uxdir';
    if not CreateDir(DirName) then raise Exception.Create('mkdir failed');

    if fpSetEnv(PChar('PATH=' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'uxdir';
    SI.SetUsePathSearch(True);
    try
      SI.Validate; Fail('Validate should fail when name refers to directory');
    except on E: EProcessStartError do CheckTrue(True); end;
  finally
    try RemoveDir(DirName); except end;
    try RemoveDir(TD); except end;
  end;
end;

{$ENDIF}

initialization
{$IFDEF UNIX}
  RegisterTest(TTestCase_PathSearch_Unix_Edges);
{$ENDIF}

end.

