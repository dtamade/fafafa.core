program run_async_tests;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testreport, testregistry,
  test_async_basic;

var
  LApplication: TTestRunner;

begin
  Writeln('=== fafafa.core.fs.async 测试套件 ===');
  Writeln('');
  
  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'fafafa.core.fs.async Tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
