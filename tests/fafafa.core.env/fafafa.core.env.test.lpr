{$CODEPAGE UTF8}
program fafafa_core_env_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.env.testcase;

var
  i: Integer;
  isListMode: Boolean;
begin
  // FPCUnit 控制台运行器
  // NOTE: Do not manually free TestRegistry here; it can cause double-free/AV on exit.
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;

  // Avoid heaptrc call traces in --list mode.
  // Newer FPCUnit runners may already free the registry during normal runs,
  // so we only free it in list mode to avoid double-free / AV at program exit.
  isListMode := False;
  for i := 1 to ParamCount do
    if (ParamStr(i) = '--list') or (ParamStr(i) = '-l') then
      isListMode := True;

  if isListMode then
    testregistry.GetTestRegistry.Free;
end.

