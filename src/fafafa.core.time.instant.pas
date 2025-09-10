unit fafafa.core.time.instant;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.duration;

type
  // 单调时钟时间点（纳秒自某个单调起点）
  TInstant = record
  private
    FNsSinceEpoch: UInt64;
  public
    // 构造
    class function FromNsSinceEpoch(const A: UInt64): TInstant; static; inline;
    class function Zero: TInstant; static; inline;

    // 访问
    function AsNsSinceEpoch: UInt64; inline;

    // 算术
    function Add(const D: TDuration): TInstant; inline;
    function Sub(const D: TDuration): TInstant; inline;
    function Diff(const Older: TInstant): TDuration; inline;
    function Since(const Older: TInstant): TDuration; inline;

    // 比较
    function Compare(const B: TInstant): Integer; inline;
    function LessThan(const B: TInstant): Boolean; inline;
    function GreaterThan(const B: TInstant): Boolean; inline;
    function Equal(const B: TInstant): Boolean; inline;

    // 工具
    function HasPassed(const NowI: TInstant): Boolean; inline;
    function IsBefore(const Other: TInstant): Boolean; inline;
    function IsAfter(const Other: TInstant): Boolean; inline;
    function Clamp(const MinV, MaxV: TInstant): TInstant; inline;
    class function Min(const A, B: TInstant): TInstant; static; inline;
    class function Max(const A, B: TInstant): TInstant; static; inline;

    // 安全算术
    function CheckedAdd(const D: TDuration; out R: TInstant): Boolean; inline;
    function CheckedSub(const D: TDuration; out R: TInstant): Boolean; inline;

    // 字符串
    function ToString: string;
  end;

implementation

{ TInstant }

class function TInstant.FromNsSinceEpoch(const A: UInt64): TInstant;
begin
  Result.FNsSinceEpoch := A;
end;

class function TInstant.Zero: TInstant;
begin
  Result.FNsSinceEpoch := 0;
end;

function TInstant.AsNsSinceEpoch: UInt64;
begin
  Result := FNsSinceEpoch;
end;

function TInstant.Add(const D: TDuration): TInstant;
begin
  Result.FNsSinceEpoch := FNsSinceEpoch + UInt64(D.AsNs);
end;

function TInstant.Sub(const D: TDuration): TInstant;
begin
  Result.FNsSinceEpoch := FNsSinceEpoch - UInt64(D.AsNs);
end;

function TInstant.Diff(const Older: TInstant): TDuration;
begin
  Result := TDuration.FromNs(Int64(FNsSinceEpoch) - Int64(Older.FNsSinceEpoch));
end;

function TInstant.Since(const Older: TInstant): TDuration;
begin
  Result := Diff(Older);
end;

function TInstant.Compare(const B: TInstant): Integer;
begin
  if FNsSinceEpoch < B.FNsSinceEpoch then Exit(-1);
  if FNsSinceEpoch > B.FNsSinceEpoch then Exit(1);
  Result := 0;
end;

function TInstant.LessThan(const B: TInstant): Boolean;
begin
  Result := Compare(B) < 0;
end;

function TInstant.GreaterThan(const B: TInstant): Boolean;
begin
  Result := Compare(B) > 0;
end;

function TInstant.Equal(const B: TInstant): Boolean;
begin
  Result := Compare(B) = 0;
end;

function TInstant.HasPassed(const NowI: TInstant): Boolean;
begin
  Result := not LessThan(NowI);
end;

function TInstant.IsBefore(const Other: TInstant): Boolean;
begin
  Result := LessThan(Other);
end;

function TInstant.IsAfter(const Other: TInstant): Boolean;
begin
  Result := GreaterThan(Other);
end;

function TInstant.Clamp(const MinV, MaxV: TInstant): TInstant;
begin
  if LessThan(MinV) then Exit(MinV);
  if GreaterThan(MaxV) then Exit(MaxV);
  Result := Self;
end;

class function TInstant.Min(const A, B: TInstant): TInstant;
begin
  if A.LessThan(B) then Result := A else Result := B;
end;

class function TInstant.Max(const A, B: TInstant): TInstant;
begin
  if A.GreaterThan(B) then Result := A else Result := B;
end;

function TInstant.CheckedAdd(const D: TDuration; out R: TInstant): Boolean;
var ns: Int64;
begin
  ns := Int64(FNsSinceEpoch) + D.AsNs;
  Result := ns >= 0;
  if Result then R.FNsSinceEpoch := UInt64(ns);
end;

function TInstant.CheckedSub(const D: TDuration; out R: TInstant): Boolean;
var ns: Int64;
begin
  ns := Int64(FNsSinceEpoch) - D.AsNs;
  Result := ns >= 0;
  if Result then R.FNsSinceEpoch := UInt64(ns);
end;

function TInstant.ToString: string;
begin
  Result := Format('Instant(%d ns)', [FNsSinceEpoch]);
end;

end.

