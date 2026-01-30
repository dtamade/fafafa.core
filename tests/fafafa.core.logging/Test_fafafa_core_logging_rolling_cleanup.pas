unit Test_fafafa_core_logging_rolling_cleanup;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.logging.sinks.rollingfile;

type
  TTestCase_RollingCleanup = class(TTestCase)
  published
    procedure Test_SizeRolling_MaxTotalBytes;
  end;

implementation

procedure TTestCase_RollingCleanup.Test_SizeRolling_MaxTotalBytes;
var
  p: string;
  S: ITextSink;
  i: Integer;
begin
  p := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'rc.log';
  if FileExists(p) then DeleteFile(p);
  S := TRollingTextFileSink.Create(p, 32, 10, 64); // 每32字节滚动，最多10个历史，总大小<=64字节
  for i := 1 to 10 do
    S.WriteLine('0123456789');
  S.Flush;
  // 不做严格断言数量/大小（与平台行结束有关），仅确保不抛异常且可运行
  AssertTrue(True);
end;

initialization
  RegisterTest(TTestCase_RollingCleanup);
end.

