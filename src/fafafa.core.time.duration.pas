unit fafafa.core.time.duration;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

type
  {**
   * TDuration - 时间距离/时长类型
   *
   * @desc
   *   以纳秒 (Int64) 为内部存储单位的不可变时长类型。
   *   表示时间间隔，范围约 ±292 年。
   *
   * @value_range
   *   - 最小值：-9,223,372,036,854,775,808 ns (约 -292 年)
   *   - 最大值：+9,223,372,036,854,775,807 ns (约 +292 年)
   *
   * @precision
   *   纳秒级 (1 ns = 10⁻⁹ 秒)
   *
   * @thread_safety
   *   不可变类型，线程安全。
   *
   * @example
   * <code>
   *   var
   *     d1, d2: TDuration;
   *   begin
   *     d1 := TDuration.FromMs(1500);      // 1.5 秒
   *     d2 := TDuration.FromSec(2);        // 2 秒
   *     WriteLn((d1 + d2).AsMs);           // 3500
   *     WriteLn(d1.AsSecF:0:3);            // 1.500
   *   end;
   * </code>
   *}
  TDuration = record
  private
    FNs: Int64;
  public
    // ===== 单位常量 (Unit Constants) =====
    {** 返回 1 纳秒时长 *}
    class function Nanosecond: TDuration; static; inline;
    {** 返回 1 微秒时长 (1000 ns) *}
    class function Microsecond: TDuration; static; inline;
    {** 返回 1 毫秒时长 (1,000,000 ns) *}
    class function Millisecond: TDuration; static; inline;
    {** 返回 1 秒时长 (10⁹ ns) *}
    class function Second: TDuration; static; inline;
    {** 返回 1 分钟时长 (60 秒) *}
    class function Minute: TDuration; static; inline;
    {** 返回 1 小时时长 (3600 秒) *}
    class function Hour: TDuration; static; inline;
    {** 返回 1 天时长 (86400 秒) *}
    class function Day: TDuration; static; inline;
    {** 返回 1 周时长 (7 天) *}
    class function Week: TDuration; static; inline;
    
    // ===== TryFrom 构造器 (安全，检测溢出) =====
    {** 从纳秒创建，始终成功 *}
    class function TryFromNs(const ANs: Int64; out D: TDuration): Boolean; static; inline;
    {** 从微秒创建，溢出时返回 False *}
    class function TryFromUs(const AUs: Int64; out D: TDuration): Boolean; static; inline;
    {** 从毫秒创建，溢出时返回 False *}
    class function TryFromMs(const AMs: Int64; out D: TDuration): Boolean; static; inline;
    {** 从秒创建，溢出时返回 False *}
    class function TryFromSec(const ASec: Int64; out D: TDuration): Boolean; static; inline;


    // ===== From* 工厂方法 (可能溢出饱和) =====
    {** 返回零时长 *}
    class function Zero: TDuration; static; inline;
    {** 从纳秒创建 *}
    class function FromNs(const ANs: Int64): TDuration; static; inline;
    {** 从微秒创建，溢出时饱和到极值 *}
    class function FromUs(const AUs: Int64): TDuration; static; inline;
    {** 从毫秒创建，溢出时饱和到极值 *}
    class function FromMs(const AMs: Int64): TDuration; static; inline;
    {** 从秒创建，溢出时饱和到极值 *}
    class function FromSec(const ASec: Int64): TDuration; static; inline;
    {**
     * 从浮点秒创建
     * @warning Double 精度约 15 位，大值时可能丢失纳秒精度
     *}
    class function FromSecF(const ASec: Double): TDuration; static; inline;
    {** 从分钟创建 *}
    class function FromMinutes(const AMin: Int64): TDuration; static; inline;
    {** 从小时创建 *}
    class function FromHours(const AHrs: Int64): TDuration; static; inline;
    {** 从天创建 *}
    class function FromDays(const ADays: Int64): TDuration; static; inline;
    {** 从周创建 *}
    class function FromWeeks(const AWeeks: Int64): TDuration; static; inline;

    // ===== As* 单位转换 =====
    {** 返回纳秒数（无精度损失） *}
    function AsNs: Int64; inline;
    {** 返回微秒数（截断小数部分） *}
    function AsUs: Int64; inline;
    {** 返回毫秒数（截断小数部分） *}
    function AsMs: Int64; inline;
    {** 返回秒数（截断小数部分） *}
    function AsSec: Int64; inline;
    {** 返回浮点秒数（可能丢失精度） *}
    function AsSecF: Double; inline;
    
    // ===== Whole* 分解方法 (v1.2.0) =====
    {** 返回完整天数（截断向零） *}
    function WholeDays: Int64; inline;
    {** 返回完整小时数（截断向零） *}
    function WholeHours: Int64; inline;
    {** 返回完整分钟数（截断向零） *}
    function WholeMinutes: Int64; inline;
    {** 返回完整秒数（截断向零），等同 AsSec *}
    function WholeSeconds: Int64; inline;
    
    // ===== Subsec* 亚秒分解方法 (v1.2.0) =====
    {** 返回亚秒纳秒部分 (0-999999999) *}
    function SubsecNanos: Integer; inline;
    {** 返回亚秒微秒部分 (0-999999) *}
    function SubsecMicros: Integer; inline;
    {** 返回亚秒毫秒部分 (0-999) *}
    function SubsecMillis: Integer; inline;

    // ===== 舍入方法 (到微秒精度) =====
    {** 截断到微秒（丢弃纳秒部分） *}
    function TruncToUs: TDuration; inline;
    {** 向下舍入到微秒 *}
    function FloorToUs: TDuration; inline;
    {** 向上舍入到微秒 *}
    function CeilToUs: TDuration; inline;
    {** 四舍五入到微秒 *}
    function RoundToUs: TDuration; inline;

    // ===== 算术运算符 =====
    {** 时长加法 *}
    class operator +(const A, B: TDuration): TDuration; inline;
    {** 时长减法 *}
    class operator -(const A, B: TDuration): TDuration; inline;
    {** 取负 *}
    class operator -(const A: TDuration): TDuration; inline;
    {** 时长乘以整数 *}
    class operator *(const A: TDuration; const Factor: Int64): TDuration; inline;
    {** 整数乘以时长 *}
    class operator *(const Factor: Int64; const A: TDuration): TDuration; inline;
    /// <summary>
    ///   除法运算符。
    ///   ⚠️ 注意：当 Divisor = 0 时，使用饱和策略：返回 High(Int64) 或 Low(Int64)。
    ///   这是有意的设计选择，以避免异常开销。如需检测除零，请使用 CheckedDivBy。
    /// </summary>
    class operator div(const A: TDuration; const Divisor: Int64): TDuration; inline;
    {** 时长比例（返回倍数） *}
    class operator /(const A, B: TDuration): Double; inline;

    // ===== 扩展算术方法 =====
    {** 乘法（同 * 运算符） *}
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

    // ===== Checked 版本 (溢出检测) =====
    {** 加法，溢出时返回 False (v1.3.0) *}
    function CheckedAdd(const B: TDuration; out R: TDuration): Boolean; inline;
    {** 减法，下溢时返回 False (v1.3.0) *}
    function CheckedSub(const B: TDuration; out R: TDuration): Boolean; inline;
    {** 乘法，溢出时返回 False *}
    function CheckedMul(const Factor: Int64; out R: TDuration): Boolean; inline;
    {** 除法，除零时返回 False（统一命名 CheckedDiv，保留 CheckedDivBy 作为兼容别名） *}
    function CheckedDiv(const Divisor: Int64; out R: TDuration): Boolean; inline;
    function CheckedDivBy(const Divisor: Int64; out R: TDuration): Boolean; inline; deprecated 'Use CheckedDiv instead';
    {** 求模，除零时返回 False *}
    function CheckedModulo(const Divisor: TDuration; out R: TDuration): Boolean; inline;

    // ===== 饱和版本 (溢出时饱和到极值) =====
    {** 饱和乘法 *}
    function SaturatingMul(const Factor: Int64): TDuration; inline;
    {** 饱和除法 *}
    function SaturatingDiv(const Divisor: Int64): TDuration; inline;

    // ===== 比较运算符 =====
    {** 相等 *}
    class operator =(const A, B: TDuration): Boolean; inline;
    {** 不等 *}
    class operator <>(const A, B: TDuration): Boolean; inline;
    {** 小于 *}
    class operator <(const A, B: TDuration): Boolean; inline;
    {** 大于 *}
    class operator >(const A, B: TDuration): Boolean; inline;
    {** 小于等于 *}
    class operator <=(const A, B: TDuration): Boolean; inline;
    {** 大于等于 *}
    class operator >=(const A, B: TDuration): Boolean; inline;

    // ===== 查询方法 =====
    {** 是否为零 *}
    function IsZero: Boolean; inline;
    {** 是否为正数 *}
    function IsPositive: Boolean; inline;
    {** 是否为负数 *}
    function IsNegative: Boolean; inline;
    {** 返回绝对值 *}
    function Abs: TDuration; inline;
    {** 返回取负值 *}
    function Neg: TDuration; inline;

    // ===== 约束方法 =====
    {** 将值限制在 [AMin, AMax] 范围内 *}
    function Clamp(const AMin, AMax: TDuration): TDuration; inline;
    {** 返回较小值 *}
    class function Min(const A, B: TDuration): TDuration; static; inline;
    {** 返回较大值 *}
    class function Max(const A, B: TDuration): TDuration; static; inline;
    
    // ===== ISO 8601 序列化 =====
    {**
     * 转换为 ISO 8601 Duration 格式
     * @returns 格式: P[n]DT[n]H[n]M[n]S 或 -P... (负值)
     * @example PT1H30M (1小时30分钟), P1DT12H (1天12小时)
     * @remarks 不支持年/月（因为它们是可变长度的）
     *}
    function ToISO8601: string;
    
    {**
     * 从 ISO 8601 Duration 格式解析
     * @param AStr 输入字符串，格式: P[n]W|P[n]DT[n]H[n]M[n]S 或 -P...
     * @param ADuration 输出时长
     * @returns 解析成功返回 True
     * @remarks 不支持 P[n]Y[n]M 格式（年/月是可变长度的）
     *}
    class function TryParseISO8601(const AStr: string; out ADuration: TDuration): Boolean; static;
  end;

implementation

uses
  SysUtils,  // For EDivByZero exception
  fafafa.core.math;

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

// ===== Whole* 分解方法实现 (v1.2.0) =====
const
  NS_PER_SECOND = Int64(1000000000);
  NS_PER_MINUTE = Int64(60000000000);
  NS_PER_HOUR   = Int64(3600000000000);
  NS_PER_DAY    = Int64(86400000000000);

function TDuration.WholeDays: Int64;
begin
  Result := FNs div NS_PER_DAY;
end;

function TDuration.WholeHours: Int64;
begin
  Result := FNs div NS_PER_HOUR;
end;

function TDuration.WholeMinutes: Int64;
begin
  Result := FNs div NS_PER_MINUTE;
end;

function TDuration.WholeSeconds: Int64;
begin
  Result := FNs div NS_PER_SECOND;
end;

// ===== Subsec* 亚秒分解方法实现 (v1.2.0) =====

function TDuration.SubsecNanos: Integer;
var
  LAbsNs: Int64;
begin
  // 取模绝对值，亚秒部分始终为正数
  if FNs >= 0 then
    Result := Integer(FNs mod NS_PER_SECOND)
  else if FNs = Low(Int64) then
    // 边界情况：Low(Int64) 无法取负
    Result := Integer(Int64(High(Int64)) mod NS_PER_SECOND)
  else
  begin
    LAbsNs := -FNs;
    Result := Integer(LAbsNs mod NS_PER_SECOND);
  end;
end;

function TDuration.SubsecMicros: Integer;
begin
  // 纳秒 -> 微秒
  Result := SubsecNanos div 1000;
end;

function TDuration.SubsecMillis: Integer;
begin
  // 纳秒 -> 毫秒
  Result := SubsecNanos div 1000000;
end;

function TDuration.TruncToUs: TDuration;
var absNs, q: Int64;
begin
  if FNs >= 0 then
    begin q := FNs div 1000; Result.FNs := q * 1000; end
  else if FNs = Low(Int64) then
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饱和到 High(Int64)
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
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饱和到 High(Int64)
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
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饱和到 High(Int64)
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
    // ✅ Low(Int64) 边界情况：-FNs 溢出，饱和到 High(Int64)
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
  // ISSUE-? 修复：除零抛出异常，与 div 运算符保持一致
  if B.FNs = 0 then
    raise EDivByZero.Create('Division by zero in TDuration./')
  else
    Result := A.FNs / B.FNs;
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

function TDuration.CheckedAdd(const B: TDuration; out R: TDuration): Boolean;
begin
  Result := TInt64Helper.TryAdd(FNs, B.FNs, R.FNs);
end;

function TDuration.CheckedSub(const B: TDuration; out R: TDuration): Boolean;
begin
  Result := TInt64Helper.TrySub(FNs, B.FNs, R.FNs);
end;

function TDuration.CheckedMul(const Factor: Int64; out R: TDuration): Boolean;
begin
  Result := TInt64Helper.TryMul(FNs, Factor, R.FNs);
end;

function TDuration.CheckedDiv(const Divisor: Int64; out R: TDuration): Boolean;
begin
  Result := CheckedDivBy(Divisor, R);
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

function TDuration.ToISO8601: string;
const
  NS_PER_SEC  = Int64(1000000000);
  NS_PER_MIN  = Int64(60) * NS_PER_SEC;
  NS_PER_HOUR = Int64(3600) * NS_PER_SEC;
  NS_PER_DAY  = Int64(86400) * NS_PER_SEC;
var
  Ns, AbsNs: Int64;
  Days, Hours, Minutes, Seconds: Int64;
  SubSecNs: Int64;
  DatePart, TimePart: string;
  Negative: Boolean;
begin
  Ns := FNs;
  Negative := Ns < 0;
  
  if Negative then
  begin
    if Ns = Low(Int64) then
      AbsNs := High(Int64)  // 避免溢出
    else
      AbsNs := -Ns;
  end
  else
    AbsNs := Ns;
  
  // 分解为天、小时、分钟、秒、亚秒
  Days := AbsNs div NS_PER_DAY;
  AbsNs := AbsNs mod NS_PER_DAY;
  
  Hours := AbsNs div NS_PER_HOUR;
  AbsNs := AbsNs mod NS_PER_HOUR;
  
  Minutes := AbsNs div NS_PER_MIN;
  AbsNs := AbsNs mod NS_PER_MIN;
  
  Seconds := AbsNs div NS_PER_SEC;
  SubSecNs := AbsNs mod NS_PER_SEC;
  
  // 构建日期部分 (P[n]D)
  DatePart := '';
  if Days > 0 then
    DatePart := IntToStr(Days) + 'D';
  
  // 构建时间部分 (T[n]H[n]M[n]S)
  TimePart := '';
  if Hours > 0 then
    TimePart := TimePart + IntToStr(Hours) + 'H';
  if Minutes > 0 then
    TimePart := TimePart + IntToStr(Minutes) + 'M';
  
  // 秒（含小数部分）
  if (Seconds > 0) or (SubSecNs > 0) then
  begin
    if SubSecNs = 0 then
      TimePart := TimePart + IntToStr(Seconds) + 'S'
    else
    begin
      // 格式化小数秒，去掉末尾的 0
      // 例如: 1.5S, 1.001S, 1.000001S
      TimePart := TimePart + IntToStr(Seconds) + '.';
      // 添加纳秒部分，最多 9 位
      TimePart := TimePart + Format('%.9d', [SubSecNs]);
      // 去掉末尾的 0
      while (Length(TimePart) > 0) and (TimePart[Length(TimePart)] = '0') do
        Delete(TimePart, Length(TimePart), 1);
      TimePart := TimePart + 'S';
    end;
  end
  else if (DatePart = '') and (TimePart = '') then
  begin
    // 零时长
    TimePart := '0S';
  end;
  
  // 组合结果
  if TimePart <> '' then
    Result := 'P' + DatePart + 'T' + TimePart
  else
    Result := 'P' + DatePart;
  
  if Negative then
    Result := '-' + Result;
end;

class function TDuration.TryParseISO8601(const AStr: string; out ADuration: TDuration): Boolean;
const
  NS_PER_SEC  = Int64(1000000000);
  NS_PER_MIN  = Int64(60) * NS_PER_SEC;
  NS_PER_HOUR = Int64(3600) * NS_PER_SEC;
  NS_PER_DAY  = Int64(86400) * NS_PER_SEC;
  NS_PER_WEEK = Int64(7) * NS_PER_DAY;
var
  S: string;
  I, Start: Integer;
  NumStr: string;
  Num: Int64;
  FracNum: Double;
  TotalNs: Int64;
  InTimePart: Boolean;
  Negative: Boolean;
  C: Char;
begin
  Result := False;
  TotalNs := 0;
  InTimePart := False;
  
  S := Trim(AStr);
  if Length(S) < 2 then Exit;
  
  // 检查负号
  Negative := False;
  I := 1;
  if S[I] = '-' then
  begin
    Negative := True;
    Inc(I);
  end;
  
  // 必须以 P 开头
  if (I > Length(S)) or (UpCase(S[I]) <> 'P') then Exit;
  Inc(I);
  
  if I > Length(S) then Exit;  // P 后面必须有内容
  
  Start := I;
  
  while I <= Length(S) do
  begin
    C := UpCase(S[I]);
    
    case C of
      'T':
        begin
          InTimePart := True;
          Start := I + 1;
        end;
      
      'W':  // 周
        begin
          NumStr := Copy(S, Start, I - Start);
          if not TryStrToInt64(NumStr, Num) then Exit;
          TotalNs := TotalNs + Num * NS_PER_WEEK;
          Start := I + 1;
        end;
      
      'D':  // 天（日期部分）
        begin
          if InTimePart then Exit;  // D 不应在 T 后面
          NumStr := Copy(S, Start, I - Start);
          if not TryStrToInt64(NumStr, Num) then Exit;
          TotalNs := TotalNs + Num * NS_PER_DAY;
          Start := I + 1;
        end;
      
      'H':  // 小时（时间部分）
        begin
          if not InTimePart then Exit;  // H 必须在 T 后面
          NumStr := Copy(S, Start, I - Start);
          if not TryStrToInt64(NumStr, Num) then Exit;
          TotalNs := TotalNs + Num * NS_PER_HOUR;
          Start := I + 1;
        end;
      
      'M':  // 月（日期部分）或 分钟（时间部分）
        begin
          NumStr := Copy(S, Start, I - Start);
          if InTimePart then
          begin
            // 分钟
            if not TryStrToInt64(NumStr, Num) then Exit;
            TotalNs := TotalNs + Num * NS_PER_MIN;
          end
          else
          begin
            // 月份 - 不支持！
            Exit;
          end;
          Start := I + 1;
        end;
      
      'Y':  // 年 - 不支持！
        Exit;
      
      'S':  // 秒（时间部分）
        begin
          if not InTimePart then Exit;  // S 必须在 T 后面
          NumStr := Copy(S, Start, I - Start);
          // 支持小数秒
          if Pos('.', NumStr) > 0 then
          begin
            if not TryStrToFloat(NumStr, FracNum) then Exit;
            TotalNs := TotalNs + Round(FracNum * NS_PER_SEC);
          end
          else
          begin
            if not TryStrToInt64(NumStr, Num) then Exit;
            TotalNs := TotalNs + Num * NS_PER_SEC;
          end;
          Start := I + 1;
        end;
      
      '0'..'9', '.', '-', '+':
        ; // 数字或符号，继续累积
      
      else
        Exit;  // 无效字符
    end;
    
    Inc(I);
  end;
  
  // 检查是否有未处理的内容
  if Start <= Length(S) then Exit;
  
  // 检查是否有效（至少包含一个数值）
  // PT 单独应该失败，因为 T 后面没有时间部分
  if (TotalNs = 0) and InTimePart and (Start = 3 + Ord(Negative)) then
  begin
    // 这种情况意味着输入仅为 "PT" 或 "-PT"，应该拒绝
    // 但是 P0D 或 PT0S 是有效的，他们会被解析并设置 TotalNs=0
    Exit;
  end;
  
  if Negative then
    TotalNs := -TotalNs;
  
  ADuration.FNs := TotalNs;
  Result := True;
end;

end.
