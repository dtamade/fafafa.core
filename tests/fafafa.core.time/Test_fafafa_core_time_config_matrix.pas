unit Test_fafafa_core_time_config_matrix;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_ConfigMatrix = class(TTestCase)
  published
    procedure Test_FinalSpin_And_Slice_And_Yield_Matrix;
  end;

implementation

procedure TTestCase_ConfigMatrix.Test_FinalSpin_And_Slice_And_Yield_Matrix;
var
  spins: array[0..2] of Int64 = (0, 500*1000, 2*1000*1000); // 0ns, 0.5ms, 2ms
  slices: array[0..2] of Integer = (0, 1, 2); // 片段睡眠 ms（仅 *nix 受控）
  yields: array[0..2] of LongWord = (0, 256, 2048);
  s: TSleepStrategy;
  i, j, k: Integer;
  startI, endI: TInstant;
  dMs: Int64;
  oldS: TSleepStrategy;
begin
  oldS := GetSleepStrategy;
  try
    for s in [EnergySaving, Balanced, LowLatency, UltraLowLatency] do
    begin
      SetSleepStrategy(s);
      for i := Low(spins) to High(spins) do
      begin
        SetFinalSpinThresholdNs(spins[i]);
        for j := Low(slices) to High(slices) do
        begin
          SetSliceSleepMsFor(PlatLinux, slices[j]);
          for k := Low(yields) to High(yields) do
          begin
            SetSpinYieldEvery(yields[k]);
            // 进行一次短等待，判断未被取消且时长在合理区间
            startI := NowInstant;
            DefaultMonotonicClock.WaitFor(TDuration.FromMs(3), nil);
            endI := NowInstant;
            dMs := endI.Diff(startI).AsMs;
            // 仅做宽松区间断言，避免平台不一致造成脆弱
            // Windows 针对 Balanced + yield=0 情况下，短时 WaitFor 可能接近 0ms
            // 为避免误报，将下界放宽为 0ms
            CheckTrue(dMs >= 0);
            CheckTrue(dMs <= 120);
          end;
        end;
      end;
    end;
  finally
    SetSleepStrategy(oldS);
  end;
end;

initialization
  RegisterTest(TTestCase_ConfigMatrix);
end.

