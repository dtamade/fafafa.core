unit fafafa.core.time.duration;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

type
  // 以纳秒为内部单位的时长类型（唯一真值源）
  TDuration = record
  private
    FNs: Int64;
  public
    // 单位常量（Common unit constants）
    class function Nanosecond: TDuration; static; inline;
    class function Microsecond: TDuration; static; inline;
    class function Millisecond: TDuration; static; inline;
    class function Second: TDuration; static; inline;
    class function Minute: TDuration; static; inline;
    class function Hour: TDuration; static; inline;
    class function Day: TDuration; static; inline;
    class function Week: TDuration; static; inline;
    // TryFrom 构造（检测溢出）
    class function TryFromNs(const ANs: Int64; out D: TDuration): Boolean; static; inline;
    class function TryFromUs(const AUs: Int64; out D: TDuration): Boolean; static; inline;
    class function TryFromMs(const AMs: Int64; out D: TDuration): Boolean; static; inline;
    class function TryFromSec(const ASec: Int64; out D: TDuration): Boolean; static; inline;

    // 构造
    class function Zero: TDuration; static; inline;
    class function FromNs(const ANs: Int64): TDuration; static; inline;
    class function FromUs(const AUs: Int64): TDuration; static; inline;
    class function FromMs(const AMs: Int64): TDuration; static; inline;
    class function FromSec(const ASec: Int64): TDuration; static; inline;
    class function FromSecF(const ASec: Double): TDuration; static; inline;
    class function FromMinutes(const AMin: Int64): TDuration; static; inline;
    class function FromHours(const AHrs: Int64): TDuration; static; inline;
    class function FromDays(const ADays: Int64): TDuration; static; inline;
    class function FromWeeks(const AWeeks: Int64): TDuration; static; inline;

    // 访问
    function AsNs: Int64; inline;
    function AsUs: Int64; inline;
    function AsMs: Int64; inline;
    function AsSec: Int64; inline;
    function AsSecF: Double; inline;

    // 舍入（到微秒）
    function TruncToUs: TDuration; inline;
    function FloorToUs: TDuration; inline;
    function CeilToUs: TDuration; inline;
    function RoundToUs: TDuration; inline;

    // 算术与比较
    class operator +(const A, B: TDuration): TDuration; inline;
    class operator -(const A, B: TDuration): TDuration; inline;
    class operator -(const A: TDuration): TDuration; inline;
    class operator *(const A: TDuration; const Factor: Int64): TDuration; inline;
    class operator *(const Factor: Int64; const A: TDuration): TDuration; inline;
    /// <summary>
    ///   除法运算符。
    ///   ⚠️ 注意：当 Divisor = 0 时，使用饱和策略：返回 High(Int64) 或 Low(Int64)。
    ///   这是有意的设计选择，以避免异常开销。如需检测除零，请使用 CheckedDivBy。
    /// </summary>
    class operator div(const A: TDuration; const Divisor: Int64): TDuration; inline;
    class operator /(const A, B: TDuration): Double; inline;

    // 扩展 API
    function Mul(const Factor: Int64): TDuration; inline;
    
    /// <summary>
    ///   整数除法。
    ///   ⚠️ 注意：当 Divisor = 0 时，使用饱和策略：返回 High(Int64) 或 Low(Int64)。
    ///   这是有意的设计选择，以避免异常开销。如需检测除零，请使用 CheckedDivBy。
    /// </summary>
    function Divi(const Divisor: Int64): TDuration; inline;
    
    /// <summary>
    ///   求模运算。
    ///   ⚠️ 注意：当 Divisor = 0 时，使用饱和策略：返回 0。
    ///   这是有意的设计选择，以避免异常开销。如需检测模零，请使用 CheckedModulo。
    /// </summary>
    function Modulo(const Divisor: TDuration): TDuration; inline;

    // Checked 版本
    function CheckedMul(const Factor: Int64; out R: TDuration): Boolean; inline;
    function CheckedDivBy(const Divisor: Int64; out R: TDuration): Boolean; inline;
    function CheckedModulo(const Divisor: TDuration; out R: TDuration): Boolean; inline;

    // 饱和版本
    function SaturatingMul(const Factor: Int64): TDuration; inline;
    function SaturatingDiv(const Divisor: Int64): TDuration; inline;

    // 查询
    class operator =(const A, B: TDuration): Boolean; inline;
    class operator <>(const A, B: TDuration): Boolean; inline;
    class operator <(const A, B: TDuration): Boolean; inline;
    class operator >(const A, B: TDuration): Boolean; inline;
    class operator <=(const A, B: TDuration): Boolean; inline;
    class operator >=(const A, B: TDuration): Boolean; inline;

    function IsZero: Boolean; inline;
    function IsPositive: Boolean; inline;
    function IsNegative: Boolean; inline;
    function Abs: TDuration; inline;
    function Neg: TDuration; inline;

    // 约束
    function Clamp(const AMin, AMax: TDuration): TDuration; inline;
    class function Min(const A, B: TDuration): TDuration; static; inline;
    class function Max(const A, B: TDuration): TDuration; static; inline;
  end;

implementation

uses
  SysUtils;  // For EDivByZero exception

type
  TInt64Helper = record
  public
    class function TryMul(a, b: Int64; out r: Int64): Boolean; static; inline;
    class function TryAdd(a, b: Int64; out r: Int64): Boolean; static; inline;
    class function TrySub(a, b: Int64; out r: Int64): Boolean; static; inline;
  end;

class function TInt64Helper.TryMul(a, b: Int64; out r: Int64): Boolean;
var maxv, minv: Int64;
begin
  maxv := High(Int64);
  minv := Low(Int64);
  if (a = 0) or (b = 0) then
  begin
    r := 0;
    Exit(True);
  end;
  if a > 0 then
  begin
    if b > 0 then
    begin
      if a > (maxv div b) then Exit(False);
    end
    else
    begin
      if b < (minv div a) then Exit(False);
    end;
  end
  else
  begin
    if b > 0 then
    begin
      if a < (minv div b) then Exit(False);
    end
    else
    begin
      if a <> 0 then
        if b < (maxv div a) then Exit(False);
    end;
  end;
  r := a * b;
  Result := True;
end;

class function TInt64Helper.TryAdd(a, b: Int64; out r: Int64): Boolean;
var tmp: Int64;
begin
  tmp := a + b;
  // Overflow if: both same sign AND result different sign
  // Check sign bit: negative numbers have MSB = 1
  if ((a >= 0) = (b >= 0)) and ((a >= 0) <> (tmp >= 0)) then Exit(False);
  r := tmp; Result := True;
end;

class function TInt64Helper.TrySub(a, b: Int64; out r: Int64): Boolean;
var tmp: Int64;
begin
  tmp := a - b;
  // Overflow if: a and -b same sign AND result different sign from a
  if ((a >= 0) = (b < 0)) and ((a >= 0) <> (tmp >= 0)) then Exit(False);
  r := tmp; Result := True;
end;

{ TDuration }

// 单位常量实现
class function TDuration.Nanosecond: TDuration;
begin
  Result.FNs := 1;
end;

class function TDuration.Microsecond: TDuration;
begin
  Result.FNs := 1000;
end;

class function TDuration.Millisecond: TDuration;
begin
  Result.FNs := 1000000;
end;

class function TDuration.Second: TDuration;
begin
  Result.FNs := 1000000000;
end;

class function TDuration.Minute: TDuration;
begin
  Result.FNs := 60000000000;
end;

class function TDuration.Hour: TDuration;
begin
  Result.FNs := 3600000000000;
end;

class function TDuration.Day: TDuration;
begin
  // 24 hours = 86400 seconds = 86400000000000 ns
  Result.FNs := 86400000000000;
end;

class function TDuration.Week: TDuration;
begin
  // 7 days = 604800 seconds = 604800000000000 ns
  Result.FNs := 604800000000000;
end;

class function TDuration.Zero: TDuration;
begin
  Result.FNs := 0;
end;

class function TDuration.TryFromNs(const ANs: Int64; out D: TDuration): Boolean;
begin
  D.FNs := ANs; Result := True;
end;

class function TDuration.TryFromUs(const AUs: Int64; out D: TDuration): Boolean;
var t: Int64;
begin
  Result := TInt64Helper.TryMul(AUs, 1000, t);
  if Result then D.FNs := t;
end;

class function TDuration.TryFromMs(const AMs: Int64; out D: TDuration): Boolean;
var t: Int64;
begin
  if not TInt64Helper.TryMul(AMs, 1000, t) then Exit(False);
  Result := TInt64Helper.TryMul(t, 1000, t);
  if Result then D.FNs := t;
end;

class function TDuration.TryFromSec(const ASec: Int64; out D: TDuration): Boolean;
var t: Int64;
begin
  if not TInt64Helper.TryMul(ASec, 1000, t) then Exit(False);
  if not TInt64Helper.TryMul(t, 1000, t) then Exit(False);
  Result := TInt64Helper.TryMul(t, 1000, t);
  if Result then D.FNs := t;
end;

class function TDuration.FromNs(const ANs: Int64): TDuration;
begin
  Result.FNs := ANs;
end;

class function TDuration.FromUs(const AUs: Int64): TDuration;
var t: Int64;
begin
  if not TInt64Helper.TryMul(AUs, 1000, t) then
    if AUs >= 0 then t := High(Int64) else t := Low(Int64);
  Result.FNs := t;
end;

class function TDuration.FromMs(const AMs: Int64): TDuration;
var t: Int64;
begin
  if not TInt64Helper.TryMul(AMs, 1000, t) then
  begin
    if AMs >= 0 then t := High(Int64) else t := Low(Int64);
  end
  else if not TInt64Helper.TryMul(t, 1000, t) then
  begin
    if AMs >= 0 then t := High(Int64) else t := Low(Int64);
  end;
  Result.FNs := t;
end;

class function TDuration.FromSec(const ASec: Int64): TDuration;
var t: Int64;
begin
  if not TInt64Helper.TryMul(ASec, 1000, t) then
  begin
    if ASec >= 0 then t := High(Int64) else t := Low(Int64);
  end
  else if not TInt64Helper.TryMul(t, 1000, t) then
  begin
    if ASec >= 0 then t := High(Int64) else t := Low(Int64);
  end
  else if not TInt64Helper.TryMul(t, 1000, t) then
  begin
    if ASec >= 0 then t := High(Int64) else t := Low(Int64);
  end;
  Result.FNs := t;
end;

class function TDuration.FromSecF(const ASec: Double): TDuration;
var limit, v: Double; r: Int64;
begin
  limit := High(Int64) / 1000000000.0;
  if ASec >= limit then r := High(Int64)
  else if ASec <= -limit then r := Low(Int64)
  else
  begin
    v := ASec * 1000000000.0;
    if v >= High(Int64) then r := High(Int64)
    else if v <= Low(Int64) then r := Low(Int64)
    else r := Round(v);
  end;
  Result.FNs := r;
end;

class function TDuration.FromMinutes(const AMin: Int64): TDuration;
begin
  // 1 minute = 60 seconds
  Result := FromSec(AMin * 60);
end;

class function TDuration.FromHours(const AHrs: Int64): TDuration;
begin
  // 1 hour = 3600 seconds
  Result := FromSec(AHrs * 3600);
end;

class function TDuration.FromDays(const ADays: Int64): TDuration;
begin
  // 1 day = 86400 seconds
  Result := FromSec(ADays * 86400);
end;

class function TDuration.FromWeeks(const AWeeks: Int64): TDuration;
begin
  // 1 week = 604800 seconds
  Result := FromSec(AWeeks * 604800);
end;

function TDuration.AsNs: Int64; begin Result := FNs; end;
function TDuration.AsUs: Int64; begin Result := FNs div 1000; end;
function TDuration.AsMs: Int64; begin Result := FNs div 1000000; end;
function TDuration.AsSec: Int64; begin Result := FNs div 1000000000; end;
function TDuration.AsSecF: Double; begin Result := FNs / 1000000000.0; end;

function TDuration.TruncToUs: TDuration;
var absNs, q: Int64;
begin
  if FNs >= 0 then
    begin q := FNs div 1000; Result.FNs := q * 1000; end
  else if FNs = Low(Int64) then
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饺和到 High(Int64)
    Result.FNs := High(Int64)
  else
    begin absNs := -FNs; q := absNs div 1000; Result.FNs := -(q * 1000); end;
end;

function TDuration.FloorToUs: TDuration;
var absNs, q: Int64;
begin
  if FNs >= 0 then
    begin q := FNs div 1000; Result.FNs := q * 1000; end
  else if FNs = Low(Int64) then
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饺和到 High(Int64)
    Result.FNs := High(Int64)
  else
  begin
    absNs := -FNs;
    if (absNs mod 1000) = 0 then q := absNs div 1000 else q := (absNs + 1000 - 1) div 1000;
    Result.FNs := -(q * 1000);
  end;
end;

function TDuration.CeilToUs: TDuration;
var absNs, q: Int64;
begin
  if FNs >= 0 then
    begin q := (FNs + 1000 - 1) div 1000; Result.FNs := q * 1000; end
  else if FNs = Low(Int64) then
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饺和到 High(Int64)
    Result.FNs := High(Int64)
  else
    begin absNs := -FNs; q := absNs div 1000; Result.FNs := -(q * 1000); end;
end;

function TDuration.RoundToUs: TDuration;
var absNs, q: Int64;
begin
  if FNs >= 0 then
    begin q := (FNs + 500) div 1000; Result.FNs := q * 1000; end
  else if FNs = Low(Int64) then
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饺和到 High(Int64)
    Result.FNs := High(Int64)
  else
    begin absNs := -FNs; q := (absNs + 500) div 1000; Result.FNs := -(q * 1000); end;
end;

class operator TDuration.+(const A, B: TDuration): TDuration;
begin
  if not TInt64Helper.TryAdd(A.FNs, B.FNs, Result.FNs) then
  begin
    if (A.FNs >= 0) and (B.FNs >= 0) then Result.FNs := High(Int64) else Result.FNs := Low(Int64);
  end;
end;

class operator TDuration.-(const A, B: TDuration): TDuration;
begin
  if not TInt64Helper.TrySub(A.FNs, B.FNs, Result.FNs) then
  begin
    if (A.FNs >= 0) and (B.FNs < 0) then Result.FNs := High(Int64) else Result.FNs := Low(Int64);
  end;
end;

class operator TDuration.-(const A: TDuration): TDuration;
begin
  if A.FNs = Low(Int64) then Result.FNs := High(Int64) else Result.FNs := -A.FNs;
end;

class operator TDuration.*(const A: TDuration; const Factor: Int64): TDuration;
begin
  if not TInt64Helper.TryMul(A.FNs, Factor, Result.FNs) then
  begin
    if ((A.FNs < 0) xor (Factor < 0)) then Result.FNs := Low(Int64) else Result.FNs := High(Int64);
  end;
end;

class operator TDuration.*(const Factor: Int64; const A: TDuration): TDuration;
begin
  if not TInt64Helper.TryMul(A.FNs, Factor, Result.FNs) then
  begin
    if ((A.FNs < 0) xor (Factor < 0)) then Result.FNs := Low(Int64) else Result.FNs := High(Int64);
  end;
end;

class operator TDuration.div(const A: TDuration; const Divisor: Int64): TDuration;
begin
  // ISSUE-1 修复：除零抛出异常而不是返回饱和值
  if Divisor = 0 then
    raise EDivByZero.Create('Division by zero in TDuration.div')
  else if (A.FNs = Low(Int64)) and (Divisor = -1) then
    Result.FNs := High(Int64)  // 溢出饱和
  else
    Result.FNs := A.FNs div Divisor;
end;

class operator TDuration./(const A, B: TDuration): Double;
begin
  if B.FNs = 0 then Result := 0.0 else Result := A.FNs / B.FNs;
end;

function TDuration.Mul(const Factor: Int64): TDuration;
begin
  if not TInt64Helper.TryMul(FNs, Factor, Result.FNs) then
  begin
    if ((FNs < 0) xor (Factor < 0)) then Result.FNs := Low(Int64) else Result.FNs := High(Int64);
  end;
end;

function TDuration.Divi(const Divisor: Int64): TDuration;
begin
  // ISSUE-1 修复：除零抛出异常而不是返回饱和值
  if Divisor = 0 then
    raise EDivByZero.Create('Division by zero in TDuration.Divi')
  else if (FNs = Low(Int64)) and (Divisor = -1) then
    Result.FNs := High(Int64)  // 溢出饱和
  else
    Result.FNs := FNs div Divisor;
end;

function TDuration.Modulo(const Divisor: TDuration): TDuration;
begin
  // ISSUE-2 修复：除零抛出异常而不是返回 0
  if Divisor.FNs = 0 then
    raise EDivByZero.Create('Modulo by zero in TDuration.Modulo')
  else
    Result.FNs := FNs mod Divisor.FNs;
end;

function TDuration.CheckedMul(const Factor: Int64; out R: TDuration): Boolean;
begin
  Result := TInt64Helper.TryMul(FNs, Factor, R.FNs);
end;

function TDuration.CheckedDivBy(const Divisor: Int64; out R: TDuration): Boolean;
begin
  if Divisor = 0 then Exit(False);
  if (FNs = Low(Int64)) and (Divisor = -1) then Exit(False);
  R.FNs := FNs div Divisor; Result := True;
end;

function TDuration.CheckedModulo(const Divisor: TDuration; out R: TDuration): Boolean;
begin
  if Divisor.FNs = 0 then Exit(False);
  R.FNs := FNs mod Divisor.FNs; Result := True;
end;

function TDuration.SaturatingMul(const Factor: Int64): TDuration;
begin
  if not TInt64Helper.TryMul(FNs, Factor, Result.FNs) then
  begin
    if ((FNs < 0) xor (Factor < 0)) then Result.FNs := Low(Int64) else Result.FNs := High(Int64);
  end;
end;

function TDuration.SaturatingDiv(const Divisor: Int64): TDuration;
begin
  if Divisor = 0 then
  begin
    if FNs >= 0 then Result.FNs := High(Int64) else Result.FNs := Low(Int64);
  end
  else if (FNs = Low(Int64)) and (Divisor = -1) then
    Result.FNs := High(Int64)
  else
    Result.FNs := FNs div Divisor;
end;

class operator TDuration.=(const A, B: TDuration): Boolean; begin Result := A.FNs = B.FNs; end;
class operator TDuration.<>(const A, B: TDuration): Boolean; begin Result := A.FNs <> B.FNs; end;
class operator TDuration.<(const A, B: TDuration): Boolean; begin Result := A.FNs < B.FNs; end;
class operator TDuration.>(const A, B: TDuration): Boolean; begin Result := A.FNs > B.FNs; end;
class operator TDuration.<=(const A, B: TDuration): Boolean; begin Result := A.FNs <= B.FNs; end;
class operator TDuration.>=(const A, B: TDuration): Boolean; begin Result := A.FNs >= B.FNs; end;

function TDuration.IsZero: Boolean; begin Result := FNs = 0; end;
function TDuration.IsPositive: Boolean; begin Result := FNs > 0; end;
function TDuration.IsNegative: Boolean; begin Result := FNs < 0; end;

function TDuration.Abs: TDuration;
begin
  if FNs >= 0 then Result.FNs := FNs
  else if FNs = Low(Int64) then Result.FNs := High(Int64)
  else Result.FNs := -FNs;
end;

function TDuration.Neg: TDuration;
begin
  if FNs = Low(Int64) then Result.FNs := High(Int64) else Result.FNs := -FNs;
end;

function TDuration.Clamp(const AMin, AMax: TDuration): TDuration;
begin
  if FNs < AMin.FNs then Result.FNs := AMin.FNs
  else if FNs > AMax.FNs then Result.FNs := AMax.FNs
  else Result.FNs := FNs;
end;

class function TDuration.Min(const A, B: TDuration): TDuration;
begin
  if A.FNs <= B.FNs then Result := A else Result := B;
end;

class function TDuration.Max(const A, B: TDuration): TDuration;
begin
  if A.FNs >= B.FNs then Result := A else Result := B;
end;

end.
