program example_mapped_runner;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils, Classes, consoletestrunner,
  // mapped_* 示例单元
  Test_mapped_ring_buffer,
  Test_mapped_slab_pool;

var
  LApplication: TTestRunner;
begin
  DefaultFormat := fPlain;
  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Title := 'fafafa.core.mem mapped_* 示例 Runner';
    LApplication.Initialize;
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
