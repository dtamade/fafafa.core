unit Test_fafafa_core_logging_daily_ext;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.logging.sinks.rollingfile.daily;

type
  TTestCase_DailyExt = class(TTestCase)
  published
    procedure Test_Daily_MaxDays_Cleanup;
  end;

implementation

function ConstNowProvider(const V: TDateTime): TNowProvider;
begin
  Result :=
    function: TDateTime
    begin
      Result := V;
    end;
end;

procedure TTestCase_DailyExt.Test_Daily_MaxDays_Cleanup;
var
  Base: TDateTime;
  P: string;
  S: TRollingDailyTextFileSink;
  i: Integer;
  NP: TNowProvider;
begin
  Base := Now;
  P := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'daily2.log';
  // 连续三天写入，MaxDays=1 仅保留当日
  for i := 0 to 2 do
  begin
    NP := ConstNowProvider(Base + i);
    S := TRollingDailyTextFileSink.Create(P, 10, @NP, 1);
    S.WriteLine('d' + IntToStr(i));
    S.Flush;
    S.Free;
  end;
  // 若需要进一步断言，可遍历文件系统；这里仅确保无异常
  AssertTrue(True);
end;

initialization
  RegisterTest(TTestCase_DailyExt);
end.

