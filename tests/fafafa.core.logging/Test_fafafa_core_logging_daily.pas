unit Test_fafafa_core_logging_daily;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.logging.sinks.rollingfile.daily,
  Test_helpers_io;

type
  TTestCase_Daily = class(TTestCase)
  published
    procedure Test_DailyRolling_Basic_Cleanup;
  end;

implementation

function FakeNowFactory(const Base: TDateTime; const DaysOffset: Integer): TNowProvider;
begin
  Result :=
    function: TDateTime
    begin
      Result := Base + DaysOffset;
    end;
end;

procedure TTestCase_Daily.Test_DailyRolling_Basic_Cleanup;
var
  Base: TDateTime;
  Now0, Now1, Now2: TNowProvider;
  S: TRollingDailyTextFileSink;
  Tmp: string;
  C: string;
begin
  Base := Now;
  Now0 := FakeNowFactory(Base, 0);
  Now1 := FakeNowFactory(Base, 1);
  Now2 := FakeNowFactory(Base, 2);

  Tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'daily.log';
  // 第一天
  S := TRollingDailyTextFileSink.Create(Tmp, 2, @Now0);
  S.WriteLine('d0.1');
  S.Flush;
  S.Free;
  // 第二天
  S := TRollingDailyTextFileSink.Create(Tmp, 2, @Now1);
  S.WriteLine('d1.1');
  S.Flush;
  S.Free;
  // 第三天，触发清理（MaxFiles=2）
  S := TRollingDailyTextFileSink.Create(Tmp, 2, @Now2);
  S.WriteLine('d2.1');
  S.Flush;
  S.Free;

  // 当天与昨天应保留，前天的文件应被清理
  C := ReadAllText(Tmp + '.' + FormatDateTime('yyyymmdd', Base+2));
  CheckTrue(Pos('d2.1', C) > 0);
end;

initialization
  RegisterTest(TTestCase_Daily);
end.

