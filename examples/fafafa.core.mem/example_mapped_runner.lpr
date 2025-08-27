{$CODEPAGE UTF8}
program example_mapped_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, consoletestrunner,
  // mapped_* 示例单元
  Test_mapped_ring_buffer,
  Test_mapped_slab_pool;

var
  Application: TTestRunner;
begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Title := 'fafafa.core.mem mapped_* 示例 Runner';
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
end.

