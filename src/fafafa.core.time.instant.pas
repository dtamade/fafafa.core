unit fafafa.core.time.instant;

{$modeswitch advancedrecords}
{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.duration;

type
  /// <summary>
  /// Represents a point in time as nanoseconds since an epoch.
  /// </summary>
  /// <remarks>
  /// <para>TInstant is an immutable value type representing a monotonic timestamp.</para>
  /// <para>Internal representation uses UInt64 nanoseconds (0 to ~584 years).</para>
  /// <para>All arithmetic operations use saturation semantics at boundaries.</para>
  /// <para>Thread-safe: all operations are pure functions on immutable data.</para>
  /// </remarks>
  /// <example>
  /// var Now: TInstant := Clock.Now;
  /// var Later: TInstant := Now.Add(TDuration.FromSec(60));
  /// var Elapsed: TDuration := Later.Diff(Now);
  /// </example>
  TInstant = record
  private
    FNsSinceEpoch: UInt64;
  public
    // === Factory Methods ===
    
    /// <summary>Creates an instant from raw nanoseconds since epoch.</summary>
    /// <param name="A">Nanoseconds since epoch (UInt64).</param>
    /// <returns>A new TInstant representing the specified time point.</returns>
    class function FromNsSinceEpoch(const A: UInt64): TInstant; static; inline;
    
    /// <summary>Creates an instant from Unix timestamp in milliseconds.</summary>
    /// <param name="AUnixMs">Milliseconds since 1970-01-01 00:00:00 UTC.</param>
    /// <returns>A new TInstant. Negative values saturate to zero.</returns>
    class function FromUnixMs(const AUnixMs: Int64): TInstant; static; inline;
    
    /// <summary>Creates an instant from Unix timestamp in seconds.</summary>
    /// <param name="AUnixSec">Seconds since 1970-01-01 00:00:00 UTC.</param>
    /// <returns>A new TInstant. Negative values saturate to zero.</returns>
    class function FromUnixSec(const AUnixSec: Int64): TInstant; static; inline;
    
    /// <summary>Creates an instant from Unix timestamp in nanoseconds.</summary>
    /// <param name="AUnixNs">Nanoseconds since 1970-01-01 00:00:00 UTC.</param>
    /// <returns>A new TInstant. Negative values saturate to zero.</returns>
    class function FromUnixNs(const AUnixNs: Int64): TInstant; static; inline;
    
    /// <summary>Returns the zero instant (epoch).</summary>
    /// <returns>TInstant with FNsSinceEpoch = 0.</returns>
    class function Zero: TInstant; static; inline;
    
    /// <summary>Parses an ISO 8601 UTC timestamp string.</summary>
    /// <param name="AStr">ISO 8601 string (e.g. "2025-01-15T14:30:45.123456789Z").</param>
    /// <param name="AInstant">Output: result instant if successful.</param>
    /// <returns>True if parsing succeeded, False otherwise.</returns>
    class function TryParseISO8601(const AStr: string; out AInstant: TInstant): Boolean; static;

    // === Conversion Methods ===
    
    /// <summary>Returns the raw nanoseconds since epoch.</summary>
    /// <returns>UInt64 nanoseconds value.</returns>
    function AsNsSinceEpoch: UInt64; inline;
    
    /// <summary>Converts to Unix timestamp in milliseconds.</summary>
    /// <returns>Milliseconds since Unix epoch. Saturates to High(Int64) on overflow.</returns>
    function AsUnixMs: Int64; inline;
    
    /// <summary>Converts to Unix timestamp in seconds.</summary>
    /// <returns>Seconds since Unix epoch. Saturates to High(Int64) on overflow.</returns>
    function AsUnixSec: Int64; inline;

    // === Arithmetic Methods ===
    
    /// <summary>Adds a duration to this instant.</summary>
    /// <param name="D">Duration to add (can be negative).</param>
    /// <returns>New instant. Saturates to 0 or High(UInt64) at boundaries.</returns>
    function Add(const D: TDuration): TInstant; inline;
    
    /// <summary>Subtracts a duration from this instant.</summary>
    /// <param name="D">Duration to subtract (can be negative).</param>
    /// <returns>New instant. Saturates to 0 or High(UInt64) at boundaries.</returns>
    function Sub(const D: TDuration): TInstant; inline;
    
    /// <summary>Calculates the signed difference between two instants.</summary>
    /// <param name="Older">The reference instant to compare against.</param>
    /// <returns>Self - Older as TDuration. Saturates at Int64 bounds.</returns>
    function Diff(const Older: TInstant): TDuration; inline;
    
    /// <summary>Alias for Diff - calculates elapsed time since another instant.</summary>
    /// <param name="Older">The earlier instant.</param>
    /// <returns>Duration from Older to Self.</returns>
    function Since(const Older: TInstant): TDuration; inline;

    // === Comparison Methods ===
    
    /// <summary>Three-way comparison with another instant.</summary>
    /// <param name="B">Instant to compare against.</param>
    /// <returns>-1 if Self &lt; B, 0 if equal, +1 if Self &gt; B.</returns>
    function Compare(const B: TInstant): Integer; inline;
    
    /// <summary>Tests if this instant is before another.</summary>
    /// <param name="B">Instant to compare against.</param>
    /// <returns>True if Self &lt; B.</returns>
    /// <remarks>Deprecated: Use operator &lt; instead.</remarks>
    function LessThan(const B: TInstant): Boolean; inline; deprecated 'Use operator < instead';
    
    /// <summary>Tests if this instant is after another.</summary>
    /// <param name="B">Instant to compare against.</param>
    /// <returns>True if Self &gt; B.</returns>
    /// <remarks>Deprecated: Use operator &gt; instead.</remarks>
    function GreaterThan(const B: TInstant): Boolean; inline; deprecated 'Use operator > instead';
    
    /// <summary>Tests equality with another instant.</summary>
    /// <param name="B">Instant to compare against.</param>
    /// <returns>True if nanosecond values are equal.</returns>
    /// <remarks>Deprecated: Use operator = instead.</remarks>
    function Equal(const B: TInstant): Boolean; inline; deprecated 'Use operator = instead';

    // === Query Methods ===
    
    /// <summary>Tests if this instant has passed relative to now.</summary>
    /// <param name="NowI">The current instant to compare against.</param>
    /// <returns>True if Self &gt;= NowI.</returns>
    function HasPassed(const NowI: TInstant): Boolean; inline;
    
    /// <summary>Tests if this instant is strictly before another.</summary>
    /// <param name="Other">Instant to compare against.</param>
    /// <returns>True if Self &lt; Other.</returns>
    function IsBefore(const Other: TInstant): Boolean; inline;
    
    /// <summary>Tests if this instant is strictly after another.</summary>
    /// <param name="Other">Instant to compare against.</param>
    /// <returns>True if Self &gt; Other.</returns>
    function IsAfter(const Other: TInstant): Boolean; inline;
    
    /// <summary>Clamps this instant to the specified range.</summary>
    /// <param name="MinV">Minimum allowed instant.</param>
    /// <param name="MaxV">Maximum allowed instant.</param>
    /// <returns>MinV if Self &lt; MinV, MaxV if Self &gt; MaxV, else Self.</returns>
    function Clamp(const MinV, MaxV: TInstant): TInstant; inline;
    
    /// <summary>Returns the earlier of two instants.</summary>
    /// <param name="A">First instant.</param>
    /// <param name="B">Second instant.</param>
    /// <returns>The instant with smaller nanosecond value.</returns>
    class function Min(const A, B: TInstant): TInstant; static; inline;
    
    /// <summary>Returns the later of two instants.</summary>
    /// <param name="A">First instant.</param>
    /// <param name="B">Second instant.</param>
    /// <returns>The instant with larger nanosecond value.</returns>
    class function Max(const A, B: TInstant): TInstant; static; inline;

    // === Checked Arithmetic ===
    
    /// <summary>Adds a duration with overflow checking.</summary>
    /// <param name="D">Duration to add.</param>
    /// <param name="R">Output: result instant if successful.</param>
    /// <returns>True if no overflow occurred, False otherwise.</returns>
    function CheckedAdd(const D: TDuration; out R: TInstant): Boolean; inline;
    
    /// <summary>Subtracts a duration with underflow checking.</summary>
    /// <param name="D">Duration to subtract.</param>
    /// <param name="R">Output: result instant if successful.</param>
    /// <returns>True if no underflow occurred, False otherwise.</returns>
    function CheckedSub(const D: TDuration; out R: TInstant): Boolean; inline;

    // === Operators ===
    
    /// <summary>Equality operator.</summary>
    class operator =(const A, B: TInstant): Boolean; inline;
    /// <summary>Inequality operator.</summary>
    class operator <>(const A, B: TInstant): Boolean; inline;
    /// <summary>Less-than operator.</summary>
    class operator <(const A, B: TInstant): Boolean; inline;
    /// <summary>Greater-than operator.</summary>
    class operator >(const A, B: TInstant): Boolean; inline;
    /// <summary>Less-than-or-equal operator.</summary>
    class operator <=(const A, B: TInstant): Boolean; inline;
    /// <summary>Greater-than-or-equal operator.</summary>
    class operator >=(const A, B: TInstant): Boolean; inline;

    // === String Conversion ===
    
    /// <summary>Converts to human-readable string representation.</summary>
    /// <returns>Format: 'Instant(N ns)' where N is nanoseconds.</returns>
    function ToString: string;
    
    /// <summary>Converts to ISO 8601 UTC timestamp string.</summary>
    /// <returns>Format: 'YYYY-MM-DDTHH:MM:SS.nnnnnnnnnZ' (nanosecond precision).</returns>
    function ToISO8601: string;
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

class function TInstant.FromUnixNs(const AUnixNs: Int64): TInstant;
begin
  // Unix epoch: 1970-01-01 00:00:00 UTC
  if AUnixNs >= 0 then
    Result.FNsSinceEpoch := UInt64(AUnixNs)
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
  // 直接比较内部纳秒值，避免依赖已弃用的 Equal 方法
  Result := A.FNsSinceEpoch = B.FNsSinceEpoch;
end;

class operator TInstant.<>(const A, B: TInstant): Boolean;
begin
  Result := A.FNsSinceEpoch <> B.FNsSinceEpoch;
end;

class operator TInstant.<(const A, B: TInstant): Boolean;
begin
  // 直接比较，避免依赖已弃用的 LessThan 方法 (ISSUE-7 优化的同一风格)
  Result := A.FNsSinceEpoch < B.FNsSinceEpoch;
end;

class operator TInstant.>(const A, B: TInstant): Boolean;
begin
  Result := A.FNsSinceEpoch > B.FNsSinceEpoch;
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
var
  base: UInt64;
  subv: Int64;
begin
  // ISSUE-6 修复：避免对 Low(Int64) 取反导致溢出
  base := FNsSinceEpoch;
  subv := D.AsNs;
  
  if subv = 0 then
  begin
    R := Self;
    Exit(True);
  end;
  
  if subv < 0 then
  begin
    // D 是负数，Sub(负数) = Add(正数)
    // 特殊处理 Low(Int64) 避免溢出
    if subv = Low(Int64) then
    begin
      // Low(Int64) 的绝对值无法表示为 Int64，返回失败
      Exit(False);
    end;
    Result := CheckedAdd(TDuration.FromNs(-subv), R);
  end
  else
  begin
    // D 是正数，正常减法
    if UInt64(subv) > base then
      Exit(False);  // 下溢
    R.FNsSinceEpoch := base - UInt64(subv);
    Result := True;
  end;
end;

function TInstant.ToString: string;
begin
  Result := Format('Instant(%d ns)', [FNsSinceEpoch]);
end;

function TInstant.ToISO8601: string;
const
  NS_PER_SEC = UInt64(1000000000);
  NS_PER_MS  = UInt64(1000000);
  NS_PER_US  = UInt64(1000);
  SEC_PER_MIN = 60;
  SEC_PER_HOUR = 3600;
  SEC_PER_DAY = 86400;
var
  totalSec: UInt64;
  ns: UInt64;
  days: UInt64;
  secOfDay: UInt64;
  hour, minute, second: Integer;
  year, month, day: Integer;
  y, m, d, n: Integer;
  isLeap: Boolean;
  daysInMonth: array[1..12] of Integer;
  fracStr: string;
begin
  totalSec := FNsSinceEpoch div NS_PER_SEC;
  ns := FNsSinceEpoch mod NS_PER_SEC;
  
  days := totalSec div SEC_PER_DAY;
  secOfDay := totalSec mod SEC_PER_DAY;
  
  hour := Integer(secOfDay div SEC_PER_HOUR);
  secOfDay := secOfDay mod SEC_PER_HOUR;
  minute := Integer(secOfDay div SEC_PER_MIN);
  second := Integer(secOfDay mod SEC_PER_MIN);
  
  // Convert days since 1970-01-01 to year/month/day
  year := 1970;
  while True do
  begin
    isLeap := ((year mod 4 = 0) and (year mod 100 <> 0)) or (year mod 400 = 0);
    if isLeap then n := 366 else n := 365;
    if days < UInt64(n) then Break;
    days := days - UInt64(n);
    Inc(year);
  end;
  
  isLeap := ((year mod 4 = 0) and (year mod 100 <> 0)) or (year mod 400 = 0);
  daysInMonth[1] := 31;
  if isLeap then daysInMonth[2] := 29 else daysInMonth[2] := 28;
  daysInMonth[3] := 31; daysInMonth[4] := 30; daysInMonth[5] := 31; daysInMonth[6] := 30;
  daysInMonth[7] := 31; daysInMonth[8] := 31; daysInMonth[9] := 30; daysInMonth[10] := 31;
  daysInMonth[11] := 30; daysInMonth[12] := 31;
  
  month := 1;
  while (month <= 12) and (days >= UInt64(daysInMonth[month])) do
  begin
    days := days - UInt64(daysInMonth[month]);
    Inc(month);
  end;
  day := Integer(days) + 1;
  
  // Format fractional seconds
  if ns = 0 then
    fracStr := ''
  else if (ns mod NS_PER_MS) = 0 then
    fracStr := Format('.%.3d', [ns div NS_PER_MS])
  else if (ns mod NS_PER_US) = 0 then
    fracStr := Format('.%.6d', [ns div NS_PER_US])
  else
    fracStr := Format('.%.9d', [ns]);
  
  Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d%sZ',
    [year, month, day, hour, minute, second, fracStr]);
end;

class function TInstant.TryParseISO8601(const AStr: string; out AInstant: TInstant): Boolean;
const
  NS_PER_SEC = UInt64(1000000000);
  SEC_PER_MIN = 60;
  SEC_PER_HOUR = 3600;
  SEC_PER_DAY = 86400;
var
  s: string;
  p: SizeInt;
  yearStr, monthStr, dayStr, hourStr, minStr, secStr, fracStr: string;
  year, month, day, hour, minute, second, nanosecond: Integer;
  m, daysInYear: Integer;
  totalDays: UInt64;
  isLeap: Boolean;
  daysInMonth: array[1..12] of Integer;
  fracLen: Integer;
begin
  Result := False;
  AInstant := Zero;
  
  s := Trim(AStr);
  if s = '' then Exit;
  
  // Must end with Z (UTC)
  if (Length(s) < 20) or (s[Length(s)] <> 'Z') then Exit;
  s := Copy(s, 1, Length(s) - 1); // Remove Z
  
  // Parse YYYY-MM-DDTHH:MM:SS(.nnnnnnnnn)?
  // Minimum: YYYY-MM-DDTHH:MM:SS = 19 chars
  if Length(s) < 19 then Exit;
  
  yearStr := Copy(s, 1, 4);
  if s[5] <> '-' then Exit;
  monthStr := Copy(s, 6, 2);
  if s[8] <> '-' then Exit;
  dayStr := Copy(s, 9, 2);
  if s[11] <> 'T' then Exit;
  hourStr := Copy(s, 12, 2);
  if s[14] <> ':' then Exit;
  minStr := Copy(s, 15, 2);
  if s[17] <> ':' then Exit;
  secStr := Copy(s, 18, 2);
  
  if Length(s) > 19 then
  begin
    if s[20] <> '.' then Exit;
    fracStr := Copy(s, 21, MaxInt);
  end
  else
    fracStr := '';
  
  if not TryStrToInt(yearStr, year) then Exit;
  if not TryStrToInt(monthStr, month) then Exit;
  if not TryStrToInt(dayStr, day) then Exit;
  if not TryStrToInt(hourStr, hour) then Exit;
  if not TryStrToInt(minStr, minute) then Exit;
  if not TryStrToInt(secStr, second) then Exit;
  
  // Validate ranges
  if (year < 1970) or (month < 1) or (month > 12) or (day < 1) or (day > 31) then Exit;
  if (hour < 0) or (hour > 23) or (minute < 0) or (minute > 59) or (second < 0) or (second > 59) then Exit;
  
  // Parse fractional seconds
  if fracStr = '' then nanosecond := 0
  else
  begin
    fracLen := Length(fracStr);
    if (fracLen < 1) or (fracLen > 9) then Exit;
    if not TryStrToInt(fracStr, nanosecond) then Exit;
    while fracLen < 9 do
    begin
      nanosecond := nanosecond * 10;
      Inc(fracLen);
    end;
  end;
  
  // Calculate days since 1970-01-01
  totalDays := 0;
  for m := 1970 to year - 1 do
  begin
    isLeap := ((m mod 4 = 0) and (m mod 100 <> 0)) or (m mod 400 = 0);
    if isLeap then totalDays := totalDays + 366 else totalDays := totalDays + 365;
  end;
  
  isLeap := ((year mod 4 = 0) and (year mod 100 <> 0)) or (year mod 400 = 0);
  daysInMonth[1] := 31;
  if isLeap then daysInMonth[2] := 29 else daysInMonth[2] := 28;
  daysInMonth[3] := 31; daysInMonth[4] := 30; daysInMonth[5] := 31; daysInMonth[6] := 30;
  daysInMonth[7] := 31; daysInMonth[8] := 31; daysInMonth[9] := 30; daysInMonth[10] := 31;
  daysInMonth[11] := 30; daysInMonth[12] := 31;
  
  // Validate day in month
  if day > daysInMonth[month] then Exit;
  
  for m := 1 to month - 1 do
    totalDays := totalDays + UInt64(daysInMonth[m]);
  totalDays := totalDays + UInt64(day - 1);
  
  AInstant.FNsSinceEpoch := totalDays * SEC_PER_DAY * NS_PER_SEC +
                            UInt64(hour) * SEC_PER_HOUR * NS_PER_SEC +
                            UInt64(minute) * SEC_PER_MIN * NS_PER_SEC +
                            UInt64(second) * NS_PER_SEC +
                            UInt64(nanosecond);
  Result := True;
end;

end.
