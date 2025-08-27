program tests_collections;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, consoletestrunner,
  // 被测门面
  fafafa.core.collections,
  Test_fafafa_core_collections;

var
  LApplication: TTestRunner;
begin
  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'tests_collections';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.

