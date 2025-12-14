program tests_io;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, consoletestrunner,
  // 被测模块
  fafafa.core.io,
  fafafa.core.io.base,
  fafafa.core.io.buffered,
  fafafa.core.io.combinators,
  fafafa.core.io.utils,
  fafafa.core.io.std,
  fafafa.core.io.streams,
  // 测试用例
  Test_IO;

var
  LApplication: TTestRunner;
begin
  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'tests_io';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
