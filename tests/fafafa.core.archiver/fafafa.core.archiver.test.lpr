{$CODEPAGE UTF8}
program tests_archiver;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
  fafafa.core.archiver, // 为调用 ArchiverShutdown
  fafafa.core.archiver.testcase,
  fafafa.core.archiver.test.exceptions,
  fafafa.core.archiver.test.pax,
  fafafa.core.archiver.test.noseek,
  fafafa.core.archiver.test.writer.safety,
  fafafa.core.archiver.test.gzip.flags;

begin
  with TTestRunner.Create(nil) do
  try
    Initialize;
    Run;
  finally
    Free;
  end;
  // 主动清理全局注册表，助力 heaptrc 0 block
  ArchiverShutdown;
  testregistry.GetTestRegistry.Free;
end.

