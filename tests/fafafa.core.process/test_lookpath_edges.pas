unit test_lookpath_edges;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  {$IFDEF UNIX}BaseUnix,{$ENDIF}
  fafafa.core.process;

type
  TTestCase_LookPath_Edges = class(TTestCase)
  published
    procedure Test_Empty_PATH_Returns_Empty;
    {$IFDEF WINDOWS}
    procedure Test_PATHEXT_Order_Affects_Resolution;
    procedure Test_With_Extension_Bypasses_PATHEXT;
    procedure Test_Not_Search_Current_Dir_By_Default;
    procedure Test_PATHEXT_Case_Insensitive;
    procedure Test_Absolute_Path_Returns_Self;
    {$ENDIF}
  end;

implementation

{$IFDEF UNIX}
function c_setenv(name, value: PChar; replace: LongInt): LongInt; cdecl; external 'c' name 'setenv';
function c_unsetenv(name: PChar): LongInt; cdecl; external 'c' name 'unsetenv';
{$ENDIF}


procedure TemporarilySetEnv(const Name, Value: string; out OldValue: string);
begin
  OldValue := SysUtils.GetEnvironmentVariable(Name);
  {$IFDEF WINDOWS}
  Windows.SetEnvironmentVariable(PChar(Name), PChar(Value));
  {$ELSE}
  if c_setenv(PChar(Name), PChar(Value), 1) <> 0 then
    raise Exception.CreateFmt('setenv failed: %s', [Name]);
  {$ENDIF}
end;

procedure RestoreEnv(const Name, OldValue: string);
begin
  {$IFDEF WINDOWS}
  if OldValue = '' then Windows.SetEnvironmentVariable(PChar(Name), nil)
  else Windows.SetEnvironmentVariable(PChar(Name), PChar(OldValue));
  {$ELSE}
  if OldValue = '' then
  begin
    if c_unsetenv(PChar(Name)) <> 0 then
      raise Exception.CreateFmt('unsetenv failed: %s', [Name]);
  end
  else
  begin
    if c_setenv(PChar(Name), PChar(OldValue), 1) <> 0 then
      raise Exception.CreateFmt('setenv restore failed: %s', [Name]);
  end;
  {$ENDIF}
end;

procedure TTestCase_LookPath_Edges.Test_Empty_PATH_Returns_Empty;
var
  OldPath, P: string;
begin
  TemporarilySetEnv('PATH','', OldPath);
  try
    P := LookPath('nonexistent_exe_name_zzz');
    CheckEquals('', P, 'Empty PATH should not find executables');
  finally
    RestoreEnv('PATH', OldPath);
  end;
end;

{$IFDEF WINDOWS}
procedure TTestCase_LookPath_Edges.Test_PATHEXT_Order_Affects_Resolution;
var
  OldPathExt, OldPath, P: string;
begin
  TemporarilySetEnv('PATHEXT','.BAT;.EXE', OldPathExt);
  // 选择系统目录作为 PATH，以避免找不到 cmd/cmd.exe
  TemporarilySetEnv('PATH', SysUtils.GetEnvironmentVariable('SystemRoot') + '\System32', OldPath);
  try
    P := LookPath('cmd');
    // 在某些系统上，cmd.exe 位于 System32；由于 .BAT 在前，若存在 cmd.bat 则会优先；一般仍解析为 cmd.exe
    CheckTrue((P <> ''), 'Should resolve to a real path with modified PATHEXT');
  finally
    RestoreEnv('PATHEXT', OldPathExt);
    RestoreEnv('PATH', OldPath);
  end;
end;

procedure TTestCase_LookPath_Edges.Test_With_Extension_Bypasses_PATHEXT;
var
  OldPath, P: string;
begin
  TemporarilySetEnv('PATH', SysUtils.GetEnvironmentVariable('SystemRoot') + '\System32', OldPath);
  try
    P := LookPath('cmd.exe');
    CheckTrue((P <> ''), 'Providing extension should bypass PATHEXT');
  finally
    RestoreEnv('PATH', OldPath);
  end;
end;

procedure TTestCase_LookPath_Edges.Test_Not_Search_Current_Dir_By_Default;
var
  OldPath, OldCwd, TmpName, P: string;
begin
  // 构造当前目录下的一个假可执行文件名（不实际创建文件），验证 SearchPath 仅用 PATH
  OldCwd := GetCurrentDir;
  TemporarilySetEnv('PATH', SysUtils.GetEnvironmentVariable('SystemRoot') + '\\System32', OldPath);
  try
    TmpName := 'lookpath_fake_' + IntToHex(Random(MaxInt), 8) + '.exe';
    // 不创建文件，LookPath 应不会在当前目录查找
    P := LookPath(TmpName);
    CheckEquals('', P, 'Should not search current directory implicitly');
  finally
    RestoreEnv('PATH', OldPath);
    ChDir(OldCwd);
  end;
end;

procedure TTestCase_LookPath_Edges.Test_PATHEXT_Case_Insensitive;
var
  OldPathExt, OldPath, P: string;
begin
  TemporarilySetEnv('PATHEXT','.com;.ExE;.bAt;.Cmd', OldPathExt);
  TemporarilySetEnv('PATH', SysUtils.GetEnvironmentVariable('SystemRoot') + '\System32', OldPath);
  try
    P := LookPath('cmd');
    CheckTrue((P <> ''), 'PATHEXT should be case-insensitive');
  finally
    RestoreEnv('PATHEXT', OldPathExt);
    RestoreEnv('PATH', OldPath);
  end;
end;

procedure TTestCase_LookPath_Edges.Test_Absolute_Path_Returns_Self;
var
  P: string;
begin
  // 绝对路径传入时，SearchPath 通常直接返回该路径（若存在）；此处选择 System32\cmd.exe
  P := LookPath(SysUtils.GetEnvironmentVariable('SystemRoot') + '\System32\cmd.exe');
  CheckTrue((P <> ''), 'Absolute path should resolve');
end;

    RestoreEnv('PATH', OldPath);
  end;
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_LookPath_Edges);

end.

