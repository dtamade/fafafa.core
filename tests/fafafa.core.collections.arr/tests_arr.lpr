program tests_arr;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  consoletestrunner,
  Test_arr;

var
  LApplication: TTestRunner;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.collections.arr 单元测试');
  WriteLn('========================================');
  WriteLn;

  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'Array Tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
