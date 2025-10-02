unit fafafa.core.time.instant;

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
    function Between(const MinV, MaxV: TInstant): TInstant; inline;
    class function Min(const A, B: TInstant): TInstant; static; inline;
    class function Max(const A, B: TInstant): TInstant; static; inline;

    // 安全算术
    function CheckedAdd(const D: TDuration; out R: TInstant): Boolean; inline;
    function CheckedSub(const D: TDuration; out R: TInstant): Boolean; inline;

    // 运算符
    class operator =(const A, B: TInstant): Boolean; inline;
    class operator <>(const A, B: TInstant): Boolean; inline;
    class operator <(const A, B: TInstant): Boolean; inline;
    class operator >(const A, B: TInstant): Boolean; inline;
    class operator <=(const A, B: TInstant): Boolean; inline;
    class operator >=(const A, B: TInstant): Boolean; inline;

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
var val: Int64; base: UInt64; addv: Int64; tmp: UInt64;
begin
  base := FNsSinceEpoch;
  addv := D.AsNs;
  if addv = 0 then Exit(Self);
  if addv > 0 then
  begin
    // positive add with saturation at High(QWord)
    tmp := High(QWord) - base;
    if UInt64(addv) > tmp then
      Result.FNsSinceEpoch := High(QWord)
    else
      Result.FNsSinceEpoch := base + UInt64(addv);
  end
  else
  begin
    // negative add => subtract with floor at 0
    val := -addv; // positive magnitude
    if UInt64(val) > base then
      Result.FNsSinceEpoch := 0
    else
      Result.FNsSinceEpoch := base - UInt64(val);
  end;
end;

function TInstant.Sub(const D: TDuration): TInstant;
var v: Int64;
begin
  // subtract D == add (-D)
  v := -D.AsNs;
  Result := Add(TDuration.FromNs(v));
end;

function TInstant.Diff(const Older: TInstant): TDuration;
var a,b: UInt64; diff: UInt64; neg: Boolean; outNs: Int64;
begin
  a := FNsSinceEpoch; b := Older.FNsSinceEpoch;
  if a >= b then
  begin
    diff := a - b;
    if diff > UInt64(High(Int64)) then outNs := High(Int64) else outNs := Int64(diff);
  end
  else
  begin
    diff := b - a; neg := True;
    if diff > UInt64(High(Int64)) then outNs := Low(Int64) else outNs := -Int64(diff);
  end;
  Result := TDuration.FromNs(outNs);
end;

function TInstant.Since(const Older: TInstant): TDuration;
begin
  Result := Diff(Older);
end;

// 非负差值（若 Older 更大则返回 0）
function TInstant.NonNegativeDiff(const Older: TInstant): TDuration;
var d: TDuration;
begin
  d := Diff(Older);
  if d.IsNegative then
    Result := TDuration.Zero
  else
    Result := d;
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

function TInstant.Between(const MinV, MaxV: TInstant): TInstant;
begin
  // Alias of Clamp for semantic readability in tests
  Result := Clamp(MinV, MaxV);
end;

class function TInstant.Min(const A, B: TInstant): TInstant;
begin
  if A.LessThan(B) then Result := A else Result := B;
end;

class function TInstant.Max(const A, B: TInstant): TInstant;
begin
  if A.GreaterThan(B) then Result := A else Result := B;
end;

class operator TInstant.=(const A, B: TInstant): Boolean;
begin
  Result := A.Equal(B);
end;

class operator TInstant.<>(const A, B: TInstant): Boolean;
begin
  Result := not A.Equal(B);
end;

class operator TInstant.<(const A, B: TInstant): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TInstant.>(const A, B: TInstant): Boolean;
begin
  Result := A.GreaterThan(B);
end;

class operator TInstant.<=(const A, B: TInstant): Boolean;
begin
  Result := not A.GreaterThan(B);
end;

class operator TInstant.>=(const A, B: TInstant): Boolean;
begin
  Result := not A.LessThan(B);
end;

function TInstant.CheckedAdd(const D: TDuration; out R: TInstant): Boolean;
var base: UInt64; addv: Int64; tmp: UInt64;
begin
  base := FNsSinceEpoch;
  addv := D.AsNs;
  if addv >= 0 then
  begin
    tmp := High(QWord) - base;
    if UInt64(addv) > tmp then Exit(False);
    R.FNsSinceEpoch := base + UInt64(addv);
    Exit(True);
  end
  else
  begin
    if UInt64(-addv) > base then Exit(False);
    R.FNsSinceEpoch := base - UInt64(-addv);
    Exit(True);
  end;
end;

function TInstant.CheckedSub(const D: TDuration; out R: TInstant): Boolean;
begin
  Result := CheckedAdd(TDuration.FromNs(-D.AsNs), R);
end;

function TInstant.ToString: string;
begin
  Result := Format('Instant(%d ns)', [FNsSinceEpoch]);
end;

end.
