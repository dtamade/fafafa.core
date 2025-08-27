program tests_deque;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  Test_deque;

var
  LApplication: TTestRunner;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.collections.deque 单元测试');
  WriteLn('========================================');
  WriteLn;

  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'Deque Tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
