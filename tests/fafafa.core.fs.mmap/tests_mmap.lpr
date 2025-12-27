program tests_mmap;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry, consoletestrunner,
  // 被测单元
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.mmap,
  // 测试用例
  fafafa.core.fs.mmap.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.fs.mmap Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
