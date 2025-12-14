program tests_treeset;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  consoletestrunner,
  Test_treeset;

var
  LApplication: TTestRunner;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.collections.treeset 单元测试');
  WriteLn('========================================');
  WriteLn;

  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'TreeSet Tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.

