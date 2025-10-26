unit fafafa.core.time.instant;

{$modeswitch advancedrecords}
{$mode objfpc}
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
    class function FromUnixMs(const AUnixMs: Int64): TInstant; static; inline;
    class function FromUnixSec(const AUnixSec: Int64): TInstant; static; inline;
    class function Zero: TInstant; static; inline;

    // 访问
    function AsNsSinceEpoch: UInt64; inline;
    function AsUnixMs: Int64; inline;
    function AsUnixSec: Int64; inline;

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

class function TInstant.FromUnixMs(const AUnixMs: Int64): TInstant;
begin
  // Unix epoch: 1970-01-01 00:00:00 UTC
  // Convert milliseconds to nanoseconds
  if AUnixMs >= 0 then
    Result.FNsSinceEpoch := UInt64(AUnixMs) * 1000000
  else
    Result.FNsSinceEpoch := 0; // Saturate to zero for negative timestamps
end;

class function TInstant.FromUnixSec(const AUnixSec: Int64): TInstant;
begin
  // Unix epoch: 1970-01-01 00:00:00 UTC
  // Convert seconds to nanoseconds
  if AUnixSec >= 0 then
    Result.FNsSinceEpoch := UInt64(AUnixSec) * 1000000000
  else
    Result.FNsSinceEpoch := 0; // Saturate to zero for negative timestamps
end;

class function TInstant.Zero: TInstant;
begin
  Result.FNsSinceEpoch := 0;
end;

function TInstant.AsNsSinceEpoch: UInt64;
begin
  Result := FNsSinceEpoch;
end;

function TInstant.AsUnixMs: Int64;
const
  MaxNsForMs = 9223372036854775807;  // High(Int64)
begin
  // Convert nanoseconds to milliseconds
  // Check if result would overflow Int64
  if FNsSinceEpoch div 1000000 <= UInt64(High(Int64)) then
    Result := Int64(FNsSinceEpoch div 1000000)
  else
    Result := High(Int64); // Saturate on overflow
end;

function TInstant.AsUnixSec: Int64;
begin
  // Convert nanoseconds to seconds
  // Check if result would overflow Int64
  if FNsSinceEpoch div 1000000000 <= UInt64(High(Int64)) then
    Result := Int64(FNsSinceEpoch div 1000000000)
  else
    Result := High(Int64); // Saturate on overflow
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
var
  base: UInt64;
  subv: Int64;
begin
  // ISSUE-6 修复：避免对 Low(Int64) 取反导致溢出
  // 直接根据 D 的符号执行加法或减法
  base := FNsSinceEpoch;
  subv := D.AsNs;
  
  if subv = 0 then
    Exit(Self);
  
  if subv < 0 then
  begin
    // D 是负数，Sub(负数) = Add(正数)
    // 特殊处理 Low(Int64) 避免溢出
    if subv = Low(Int64) then
    begin
      // Low(Int64) 的绝对值无法表示为 Int64
      // 直接饱和到 High(UInt64)
      Result.FNsSinceEpoch := High(UInt64);
    end
    else
    begin
      // 正常情况：加上绝对值
      Result := Add(TDuration.FromNs(-subv));
    end;
  end
  else
  begin
    // D 是正数，正常减法，饱和到 0
    if UInt64(subv) > base then
      Result.FNsSinceEpoch := 0
    else
      Result.FNsSinceEpoch := base - UInt64(subv);
  end;
end;

function TInstant.Diff(const Older: TInstant): TDuration;
var a,b: UInt64; delta: UInt64; outNs: Int64;
begin
  a := FNsSinceEpoch; b := Older.FNsSinceEpoch;
  if a >= b then
  begin
    delta := a - b;
    if delta > UInt64(High(Int64)) then outNs := High(Int64) else outNs := Int64(delta);
  end
  else
  begin
    delta := b - a;
    if delta > UInt64(High(Int64)) then outNs := Low(Int64) else outNs := -Int64(delta);
  end;
  Result := TDuration.FromNs(outNs);
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
  Result := FNsSinceEpoch < B.FNsSinceEpoch; // ✅ 直接比较，避免函数调用开销 (ISSUE-7)
end;

function TInstant.GreaterThan(const B: TInstant): Boolean;
begin
  Result := FNsSinceEpoch > B.FNsSinceEpoch; // ✅ 直接比较，避免函数调用开销 (ISSUE-7)
end;

function TInstant.Equal(const B: TInstant): Boolean;
begin
  Result := FNsSinceEpoch = B.FNsSinceEpoch; // ✅ 直接比较，避免函数调用开销 (ISSUE-7)
end;

function TInstant.HasPassed(const NowI: TInstant): Boolean;
begin
  Result := FNsSinceEpoch >= NowI.FNsSinceEpoch; // ✅ 直接比较 (ISSUE-7)
end;

function TInstant.IsBefore(const Other: TInstant): Boolean;
begin
  Result := FNsSinceEpoch < Other.FNsSinceEpoch; // ✅ 直接比较 (ISSUE-7)
end;

function TInstant.IsAfter(const Other: TInstant): Boolean;
begin
  Result := FNsSinceEpoch > Other.FNsSinceEpoch; // ✅ 直接比较 (ISSUE-7)
end;

function TInstant.Clamp(const MinV, MaxV: TInstant): TInstant;
begin
  if FNsSinceEpoch < MinV.FNsSinceEpoch then Exit(MinV); // ✅ 直接比较 (ISSUE-7)
  if FNsSinceEpoch > MaxV.FNsSinceEpoch then Exit(MaxV); // ✅ 直接比较 (ISSUE-7)
  Result := Self;
end;

class function TInstant.Min(const A, B: TInstant): TInstant;
begin
  if A.FNsSinceEpoch < B.FNsSinceEpoch then Result := A else Result := B; // ✅ 直接比较 (ISSUE-7)
end;

class function TInstant.Max(const A, B: TInstant): TInstant;
begin
  if A.FNsSinceEpoch > B.FNsSinceEpoch then Result := A else Result := B; // ✅ 直接比较 (ISSUE-7)
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
