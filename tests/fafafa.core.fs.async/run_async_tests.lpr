program run_async_tests;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
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
