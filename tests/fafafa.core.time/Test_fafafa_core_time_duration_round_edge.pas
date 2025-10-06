unit Test_fafafa_core_time_duration_round_edge;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_DurationRoundEdge = class(TTestCase)
  published
    procedure Test_TruncToUs_LowInt64;
    procedure Test_FloorToUs_LowInt64;
    procedure Test_CeilToUs_LowInt64;
    procedure Test_RoundToUs_LowInt64;
    procedure Test_AllRound_NearLowInt64;
  end;

implementation

procedure TTestCase_DurationRoundEdge.Test_TruncToUs_LowInt64;
var
  d, r: TDuration;
begin
  // ✅ Low(Int64) 边界情况：-FNs 会溢出，应该饱和到 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  r := d.TruncToUs;
  CheckEquals(High(Int64), r.AsNs, 'TruncToUs(Low(Int64)) 应该饱和到 High(Int64)');
end;

procedure TTestCase_DurationRoundEdge.Test_FloorToUs_LowInt64;
var
  d, r: TDuration;
begin
  // ✅ Low(Int64) 边界情况：-FNs 会溢出，应该饱和到 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  r := d.FloorToUs;
  CheckEquals(High(Int64), r.AsNs, 'FloorToUs(Low(Int64)) 应该饱和到 High(Int64)');
end;

procedure TTestCase_DurationRoundEdge.Test_CeilToUs_LowInt64;
var
  d, r: TDuration;
begin
  // ✅ Low(Int64) 边界情况：-FNs 会溢出，应该饱和到 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  r := d.CeilToUs;
  CheckEquals(High(Int64), r.AsNs, 'CeilToUs(Low(Int64)) 应该饱和到 High(Int64)');
end;

procedure TTestCase_DurationRoundEdge.Test_RoundToUs_LowInt64;
var
  d, r: TDuration;
begin
  // ✅ Low(Int64) 边界情况：-FNs 会溢出，应该饱和到 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  r := d.RoundToUs;
  CheckEquals(High(Int64), r.AsNs, 'RoundToUs(Low(Int64)) 应该饱和到 High(Int64)');
end;

procedure TTestCase_DurationRoundEdge.Test_AllRound_NearLowInt64;
var
  d, r: TDuration;
begin
  // ✅ 接近 Low(Int64) 但不等于的值应该正常工作
  d := TDuration.FromNs(Low(Int64) + 1000);  // -9223372036854775807
  
  // 这些应该正常舍入，不会溢出
  r := d.TruncToUs;
  CheckTrue(r.AsNs < 0, 'TruncToUs(Low(Int64)+1000) 应该是负数');
  
  r := d.FloorToUs;
  CheckTrue(r.AsNs < 0, 'FloorToUs(Low(Int64)+1000) 应该是负数');
  
  r := d.CeilToUs;
  CheckTrue(r.AsNs < 0, 'CeilToUs(Low(Int64)+1000) 应该是负数');
  
  r := d.RoundToUs;
  CheckTrue(r.AsNs < 0, 'RoundToUs(Low(Int64)+1000) 应该是负数');
end;

initialization
  RegisterTest(TTestCase_DurationRoundEdge);
end.
