unit fafafa.core.time.period;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.period - 日历周期类型

📖 概述：
  提供日历周期类型，表示年/月/日的相对时间段。
  对齐 Java java.time.Period 和 Rust chrono::RelativeDuration。
  
  与 TDuration 的区别：
  - TDuration: 精确纳秒，固定 24 小时/天，用于计时测量
  - TPeriod: 日历单位，DST 安全，用于日期算术

🔧 特性：
  • 年/月/日 三元组表示
  • 日历感知的日期算术
  • 标准化和规范化
  • 与 TDate 无缝交互
  • ISO 8601 P 格式支持

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.date;

type
  {**
   * TPeriod - 日历周期类型
   *
   * @desc
   *   表示年、月、日的日历周期。与 TDuration 不同，
   *   TPeriod 的 "1 天" 不一定是 24 小时（DST 边界时）。
   *
   * @design
   *   对齐 Java java.time.Period:
   *   - 年、月、日独立存储
   *   - 支持负值
   *   - Normalized() 将月份规范到 -11..11
   *   - Days 不参与规范化（因为天数与月份天数相关）
   *
   * @example
   *   var P: TPeriod;
   *   begin
   *     P := TPeriod.Create(1, 2, 3);  // 1年2月3天
   *     P := TPeriod.OfMonths(14);     // 14个月（不自动规范化）
   *     P := P.Normalized;             // 1年2月
   *     
   *     // 与日期交互
   *     D := P.AddTo(TDate.Create(2024, 1, 15));
   *   end;
   *
   * @thread_safety
   *   值类型，线程安全。
   *}
  TPeriod = record
  private
    FYears: Integer;
    FMonths: Integer;
    FDays: Integer;
  public
    // =========================================================================
    // 构造函数
    // =========================================================================
    
    /// <summary>创建指定年、月、日的周期</summary>
    /// <param name="AYears">年数，可以为负</param>
    /// <param name="AMonths">月数，可以为负，不自动规范化</param>
    /// <param name="ADays">天数，可以为负</param>
    class function Create(AYears, AMonths, ADays: Integer): TPeriod; static; inline;
    
    /// <summary>创建指定年数的周期</summary>
    class function OfYears(AYears: Integer): TPeriod; static; inline;
    
    /// <summary>创建指定月数的周期（不自动规范化到年）</summary>
    class function OfMonths(AMonths: Integer): TPeriod; static; inline;
    
    /// <summary>创建指定天数的周期</summary>
    class function OfDays(ADays: Integer): TPeriod; static; inline;
    
    /// <summary>创建指定周数的周期（转换为天数）</summary>
    class function OfWeeks(AWeeks: Integer): TPeriod; static; inline;
    
    /// <summary>返回零周期</summary>
    class function Zero: TPeriod; static; inline;
    
    /// <summary>计算两个日期之间的周期</summary>
    /// <param name="AStart">起始日期</param>
    /// <param name="AEnd">结束日期</param>
    /// <returns>从 AStart 到 AEnd 的周期（可能为负）</returns>
    class function Between(const AStart, AEnd: fafafa.core.time.date.TDate): TPeriod; static;
    
    // =========================================================================
    // 属性访问
    // =========================================================================
    
    /// <summary>获取年数部分</summary>
    function GetYears: Integer; inline;
    /// <summary>获取月数部分</summary>
    function GetMonths: Integer; inline;
    /// <summary>获取天数部分</summary>
    function GetDays: Integer; inline;
    
    property Years: Integer read GetYears;
    property Months: Integer read GetMonths;
    property Days: Integer read GetDays;
    
    /// <summary>获取总月数（Years * 12 + Months）</summary>
    function TotalMonths: Integer; inline;
    
    // =========================================================================
    // 算术运算
    // =========================================================================
    
    /// <summary>加上另一个周期</summary>
    function Plus(const AOther: TPeriod): TPeriod; inline;
    
    /// <summary>减去另一个周期</summary>
    function Minus(const AOther: TPeriod): TPeriod; inline;
    
    /// <summary>取负（所有分量取负）</summary>
    function Negated: TPeriod; inline;
    
    /// <summary>乘以标量</summary>
    function Multiplied(AFactor: Integer): TPeriod; inline;
    
    // =========================================================================
    // 标准化
    // =========================================================================
    
    /// <summary>
    ///   标准化周期，使月份在 0-11 范围内（绝对值）。
    ///   天数不参与标准化。
    /// </summary>
    /// <remarks>
    ///   1年14月3天 -> 2年2月3天
    ///   2年-3月0天 -> 1年9月0天
    /// </remarks>
    function Normalized: TPeriod;
    
    // =========================================================================
    // 查询方法
    // =========================================================================
    
    /// <summary>是否为零周期</summary>
    function IsZero: Boolean; inline;
    
    /// <summary>是否为负周期（总月数为负或天数为负）</summary>
    function IsNegative: Boolean;
    
    // =========================================================================
    // 与日期交互
    // =========================================================================
    
    /// <summary>将此周期加到日期上</summary>
    /// <param name="ADate">基准日期</param>
    /// <returns>加上周期后的新日期</returns>
    /// <remarks>
    ///   顺序：先加年，再加月，最后加天。
    ///   月末边界处理：如果结果日期不存在（如 1月31日+1月），
    ///   则调整到目标月份的最后一天。
    /// </remarks>
    function AddTo(const ADate: fafafa.core.time.date.TDate): fafafa.core.time.date.TDate;
    
    /// <summary>从日期减去此周期</summary>
    function SubtractFrom(const ADate: fafafa.core.time.date.TDate): fafafa.core.time.date.TDate;
    
    // =========================================================================
    // 比较运算符
    // =========================================================================
    
    class operator =(const A, B: TPeriod): Boolean; inline;
    class operator <>(const A, B: TPeriod): Boolean; inline;
    
    // =========================================================================
    // 字符串转换
    // =========================================================================
    
    /// <summary>转换为字符串表示</summary>
    /// <returns>格式: "P1Y2M3D" (ISO 8601 Period)</returns>
    function ToString: string;
    
    /// <summary>尝试从 ISO 8601 Period 格式解析</summary>
    class function TryParse(const AStr: string; out APeriod: TPeriod): Boolean; static;
  end;

implementation

// =============================================================================
// TPeriod 实现
// =============================================================================

class function TPeriod.Create(AYears, AMonths, ADays: Integer): TPeriod;
begin
  Result.FYears := AYears;
  Result.FMonths := AMonths;
  Result.FDays := ADays;
end;

class function TPeriod.OfYears(AYears: Integer): TPeriod;
begin
  Result.FYears := AYears;
  Result.FMonths := 0;
  Result.FDays := 0;
end;

class function TPeriod.OfMonths(AMonths: Integer): TPeriod;
begin
  Result.FYears := 0;
  Result.FMonths := AMonths;
  Result.FDays := 0;
end;

class function TPeriod.OfDays(ADays: Integer): TPeriod;
begin
  Result.FYears := 0;
  Result.FMonths := 0;
  Result.FDays := ADays;
end;

class function TPeriod.OfWeeks(AWeeks: Integer): TPeriod;
begin
  Result.FYears := 0;
  Result.FMonths := 0;
  Result.FDays := AWeeks * 7;
end;

class function TPeriod.Zero: TPeriod;
begin
  Result.FYears := 0;
  Result.FMonths := 0;
  Result.FDays := 0;
end;

class function TPeriod.Between(const AStart, AEnd: fafafa.core.time.date.TDate): TPeriod;
var
  StartY, StartM, StartD: Integer;
  EndY, EndM, EndD: Integer;
  Y, M, D: Integer;
  Negative: Boolean;
  TempStart, TempEnd: fafafa.core.time.date.TDate;
begin
  // 获取日期组件
  StartY := AStart.GetYear;
  StartM := AStart.GetMonth;
  StartD := AStart.GetDay;
  EndY := AEnd.GetYear;
  EndM := AEnd.GetMonth;
  EndD := AEnd.GetDay;
  
  // 处理负周期
  Negative := False;
  if (EndY < StartY) or ((EndY = StartY) and (EndM < StartM)) or
     ((EndY = StartY) and (EndM = StartM) and (EndD < StartD)) then
  begin
    Negative := True;
    // 交换
    TempStart := AEnd;
    TempEnd := AStart;
    StartY := TempStart.GetYear;
    StartM := TempStart.GetMonth;
    StartD := TempStart.GetDay;
    EndY := TempEnd.GetYear;
    EndM := TempEnd.GetMonth;
    EndD := TempEnd.GetDay;
  end;
  
  // 计算差值
  Y := EndY - StartY;
  M := EndM - StartM;
  D := EndD - StartD;
  
  // 调整负数天
  if D < 0 then
  begin
    Dec(M);
    // 需要上个月的天数
    D := D + fafafa.core.time.date.TDate.Create(EndY, EndM, 1).AddDays(-1).GetDay + 1;
    // 简化：直接加 30
    if D < 0 then D := D + 30;
  end;
  
  // 调整负数月
  if M < 0 then
  begin
    Dec(Y);
    M := M + 12;
  end;
  
  if Negative then
  begin
    Result.FYears := -Y;
    Result.FMonths := -M;
    Result.FDays := -D;
  end
  else
  begin
    Result.FYears := Y;
    Result.FMonths := M;
    Result.FDays := D;
  end;
end;

function TPeriod.GetYears: Integer;
begin
  Result := FYears;
end;

function TPeriod.GetMonths: Integer;
begin
  Result := FMonths;
end;

function TPeriod.GetDays: Integer;
begin
  Result := FDays;
end;

function TPeriod.TotalMonths: Integer;
begin
  Result := FYears * 12 + FMonths;
end;

function TPeriod.Plus(const AOther: TPeriod): TPeriod;
begin
  Result.FYears := FYears + AOther.FYears;
  Result.FMonths := FMonths + AOther.FMonths;
  Result.FDays := FDays + AOther.FDays;
end;

function TPeriod.Minus(const AOther: TPeriod): TPeriod;
begin
  Result.FYears := FYears - AOther.FYears;
  Result.FMonths := FMonths - AOther.FMonths;
  Result.FDays := FDays - AOther.FDays;
end;

function TPeriod.Negated: TPeriod;
begin
  Result.FYears := -FYears;
  Result.FMonths := -FMonths;
  Result.FDays := -FDays;
end;

function TPeriod.Multiplied(AFactor: Integer): TPeriod;
begin
  Result.FYears := FYears * AFactor;
  Result.FMonths := FMonths * AFactor;
  Result.FDays := FDays * AFactor;
end;

function TPeriod.Normalized: TPeriod;
var
  TotalM: Integer;
begin
  TotalM := TotalMonths;
  Result.FYears := TotalM div 12;
  Result.FMonths := TotalM mod 12;
  Result.FDays := FDays;
  
  // 处理负数情况：确保 Months 与 Years 符号一致
  if (Result.FYears > 0) and (Result.FMonths < 0) then
  begin
    Dec(Result.FYears);
    Result.FMonths := Result.FMonths + 12;
  end
  else if (Result.FYears < 0) and (Result.FMonths > 0) then
  begin
    Inc(Result.FYears);
    Result.FMonths := Result.FMonths - 12;
  end;
end;

function TPeriod.IsZero: Boolean;
begin
  Result := (FYears = 0) and (FMonths = 0) and (FDays = 0);
end;

function TPeriod.IsNegative: Boolean;
var
  TotalM: Integer;
begin
  TotalM := TotalMonths;
  // 如果总月数为负，或总月数为零但天数为负
  Result := (TotalM < 0) or ((TotalM = 0) and (FDays < 0));
end;

function TPeriod.AddTo(const ADate: fafafa.core.time.date.TDate): fafafa.core.time.date.TDate;
begin
  // 顺序：年 -> 月 -> 日
  Result := ADate.AddYears(FYears);
  Result := Result.AddMonths(FMonths);
  Result := Result.AddDays(FDays);
end;

function TPeriod.SubtractFrom(const ADate: fafafa.core.time.date.TDate): fafafa.core.time.date.TDate;
begin
  Result := Negated.AddTo(ADate);
end;

class operator TPeriod.=(const A, B: TPeriod): Boolean;
begin
  Result := (A.FYears = B.FYears) and (A.FMonths = B.FMonths) and (A.FDays = B.FDays);
end;

class operator TPeriod.<>(const A, B: TPeriod): Boolean;
begin
  Result := not (A = B);
end;

function TPeriod.ToString: string;
begin
  if IsZero then
    Result := 'P0D'
  else
  begin
    Result := 'P';
    if FYears <> 0 then
      Result := Result + IntToStr(FYears) + 'Y';
    if FMonths <> 0 then
      Result := Result + IntToStr(FMonths) + 'M';
    if FDays <> 0 then
      Result := Result + IntToStr(FDays) + 'D';
    // 如果只有 P，添加 0D
    if Result = 'P' then
      Result := 'P0D';
  end;
end;

class function TPeriod.TryParse(const AStr: string; out APeriod: TPeriod): Boolean;
var
  S: string;
  I, Start: Integer;
  NumStr: string;
  Num: Integer;
  Y, M, D: Integer;
begin
  Result := False;
  Y := 0;
  M := 0;
  D := 0;
  
  S := Trim(AStr);
  if (Length(S) < 2) or (S[1] <> 'P') then
    Exit;
  
  I := 2;
  Start := 2;
  
  while I <= Length(S) do
  begin
    case S[I] of
      'Y':
        begin
          NumStr := Copy(S, Start, I - Start);
          if not TryStrToInt(NumStr, Num) then Exit;
          Y := Num;
          Start := I + 1;
        end;
      'M':
        begin
          NumStr := Copy(S, Start, I - Start);
          if not TryStrToInt(NumStr, Num) then Exit;
          M := Num;
          Start := I + 1;
        end;
      'D':
        begin
          NumStr := Copy(S, Start, I - Start);
          if not TryStrToInt(NumStr, Num) then Exit;
          D := Num;
          Start := I + 1;
        end;
    end;
    Inc(I);
  end;
  
  APeriod := TPeriod.Create(Y, M, D);
  Result := True;
end;

end.
