{$mode objfpc}
{$I fafafa.core.settings.inc}

unit Test_fafafa_core_time_duration_constants;

interface

uses
  fpcunit, testregistry,
  fafafa.core.time.duration;

type
  TTestDurationConstants = class(TTestCase)
  published
    procedure TestNanosecondConstant;
    procedure TestMicrosecondConstant;
    procedure TestMillisecondConstant;
    procedure TestSecondConstant;
    procedure TestMinuteConstant;
    procedure TestHourConstant;
    procedure TestConstantsRelationships;
    procedure TestConstantsArithmetic;
    procedure TestConstantsComparison;
    procedure TestConstantsWithMultipliers;
  end;

implementation

{ TTestDurationConstants }

procedure TTestDurationConstants.TestNanosecondConstant;
var
  d: TDuration;
begin
  d := TDuration.Nanosecond;
  CheckEquals(1, d.AsNs, 'Nanosecond should be 1 nanosecond');
  CheckEquals(0, d.AsUs, 'Nanosecond should be 0 microseconds (truncated)');
end;

procedure TTestDurationConstants.TestMicrosecondConstant;
var
  d: TDuration;
begin
  d := TDuration.Microsecond;
  CheckEquals(1000, d.AsNs, 'Microsecond should be 1000 nanoseconds');
  CheckEquals(1, d.AsUs, 'Microsecond should be 1 microsecond');
  CheckEquals(0, d.AsMs, 'Microsecond should be 0 milliseconds (truncated)');
end;

procedure TTestDurationConstants.TestMillisecondConstant;
var
  d: TDuration;
begin
  d := TDuration.Millisecond;
  CheckEquals(1000000, d.AsNs, 'Millisecond should be 1,000,000 nanoseconds');
  CheckEquals(1000, d.AsUs, 'Millisecond should be 1000 microseconds');
  CheckEquals(1, d.AsMs, 'Millisecond should be 1 millisecond');
  CheckEquals(0, d.AsSec, 'Millisecond should be 0 seconds (truncated)');
end;

procedure TTestDurationConstants.TestSecondConstant;
var
  d: TDuration;
begin
  d := TDuration.Second;
  CheckEquals(1000000000, d.AsNs, 'Second should be 1,000,000,000 nanoseconds');
  CheckEquals(1000000, d.AsUs, 'Second should be 1,000,000 microseconds');
  CheckEquals(1000, d.AsMs, 'Second should be 1000 milliseconds');
  CheckEquals(1, d.AsSec, 'Second should be 1 second');
  CheckTrue(Abs(d.AsSecF - 1.0) < 0.0001, 'Second should be 1.0 seconds (float)');
end;

procedure TTestDurationConstants.TestMinuteConstant;
var
  d: TDuration;
begin
  d := TDuration.Minute;
  CheckEquals(60000000000, d.AsNs, 'Minute should be 60,000,000,000 nanoseconds');
  CheckEquals(60000000, d.AsUs, 'Minute should be 60,000,000 microseconds');
  CheckEquals(60000, d.AsMs, 'Minute should be 60000 milliseconds');
  CheckEquals(60, d.AsSec, 'Minute should be 60 seconds');
  CheckTrue(Abs(d.AsSecF - 60.0) < 0.0001, 'Minute should be 60.0 seconds (float)');
end;

procedure TTestDurationConstants.TestHourConstant;
var
  d: TDuration;
begin
  d := TDuration.Hour;
  CheckEquals(3600000000000, d.AsNs, 'Hour should be 3,600,000,000,000 nanoseconds');
  CheckEquals(3600000000, d.AsUs, 'Hour should be 3,600,000,000 microseconds');
  CheckEquals(3600000, d.AsMs, 'Hour should be 3,600,000 milliseconds');
  CheckEquals(3600, d.AsSec, 'Hour should be 3600 seconds');
  CheckTrue(Abs(d.AsSecF - 3600.0) < 0.0001, 'Hour should be 3600.0 seconds (float)');
end;

procedure TTestDurationConstants.TestConstantsRelationships;
begin
  // Test relationships between constants
  CheckTrue(TDuration.Microsecond = TDuration.Nanosecond * 1000, 
    '1 Microsecond = 1000 Nanoseconds');
  CheckTrue(TDuration.Millisecond = TDuration.Microsecond * 1000, 
    '1 Millisecond = 1000 Microseconds');
  CheckTrue(TDuration.Second = TDuration.Millisecond * 1000, 
    '1 Second = 1000 Milliseconds');
  CheckTrue(TDuration.Minute = TDuration.Second * 60, 
    '1 Minute = 60 Seconds');
  CheckTrue(TDuration.Hour = TDuration.Minute * 60, 
    '1 Hour = 60 Minutes');
  CheckTrue(TDuration.Hour = TDuration.Second * 3600, 
    '1 Hour = 3600 Seconds');
end;

procedure TTestDurationConstants.TestConstantsArithmetic;
var
  d: TDuration;
begin
  // Test arithmetic with constants
  d := TDuration.Second + TDuration.Millisecond;
  CheckEquals(1001, d.AsMs, '1 Second + 1 Millisecond = 1001 milliseconds');
  
  d := TDuration.Minute - TDuration.Second;
  CheckEquals(59, d.AsSec, '1 Minute - 1 Second = 59 seconds');
  
  d := TDuration.Hour + TDuration.Minute + TDuration.Second;
  CheckEquals(3661, d.AsSec, '1 Hour + 1 Minute + 1 Second = 3661 seconds');
end;

procedure TTestDurationConstants.TestConstantsComparison;
begin
  // Test comparisons
  CheckTrue(TDuration.Nanosecond < TDuration.Microsecond, 
    'Nanosecond < Microsecond');
  CheckTrue(TDuration.Microsecond < TDuration.Millisecond, 
    'Microsecond < Millisecond');
  CheckTrue(TDuration.Millisecond < TDuration.Second, 
    'Millisecond < Second');
  CheckTrue(TDuration.Second < TDuration.Minute, 
    'Second < Minute');
  CheckTrue(TDuration.Minute < TDuration.Hour, 
    'Minute < Hour');
  
  CheckTrue(TDuration.Hour > TDuration.Zero, 
    'Hour > Zero');
  CheckTrue(TDuration.Nanosecond > TDuration.Zero, 
    'Nanosecond > Zero');
end;

procedure TTestDurationConstants.TestConstantsWithMultipliers;
var
  d: TDuration;
begin
  // Test using constants as building blocks
  d := TDuration.Second * 5;
  CheckEquals(5, d.AsSec, '5 seconds using constant');
  
  d := TDuration.Millisecond * 500;
  CheckEquals(500, d.AsMs, '500 milliseconds using constant');
  
  d := TDuration.Minute * 2 + TDuration.Second * 30;
  CheckEquals(150, d.AsSec, '2.5 minutes = 150 seconds');
  
  d := TDuration.Hour * 24;
  CheckEquals(86400, d.AsSec, '24 hours = 86400 seconds (1 day)');
end;

initialization
  RegisterTest(TTestDurationConstants);

end.
