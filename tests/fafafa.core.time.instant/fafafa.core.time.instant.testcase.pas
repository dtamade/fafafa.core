unit fafafa.core.time.instant.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.instant, fafafa.core.time.duration;

type
  TTestCase_Instant = class(TTestCase)
  published
    procedure Test_Diff_Since;
    procedure Test_CheckedAdd_Sub;
  end;

implementation

procedure TTestCase_Instant.Test_Diff_Since;
var a,b: TInstant; d: TDuration;
begin
  a := TInstant.FromNsSinceEpoch(100);
  b := TInstant.FromNsSinceEpoch(40);
  d := a.Diff(b);
  CheckEquals(60, d.AsNs);
  d := a.Since(b);
  CheckEquals(60, d.AsNs);
end;

procedure TTestCase_Instant.Test_CheckedAdd_Sub;
var a,b: TInstant; ok: Boolean; d: TDuration;
begin
  a := TInstant.FromNsSinceEpoch(100);
  ok := a.CheckedAdd(TDuration.FromNs(23), b);
  CheckTrue(ok);
  CheckEquals(123, b.AsNsSinceEpoch);
  ok := b.CheckedSub(TDuration.FromNs(23), a);
  CheckTrue(ok);
  CheckEquals(100, a.AsNsSinceEpoch);
end;

initialization
  RegisterTest(TTestCase_Instant);
end.

