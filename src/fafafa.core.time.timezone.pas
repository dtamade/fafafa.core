unit fafafa.core.time.timezone;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.timezone - 时区支持

📖 概述：
  提供时区接口和基本实现，支持：
  - ITimeZone: 时区接口，支持 DST 查询
  - TFixedTimeZone: 固定偏移时区（无 DST）
  - TSystemTimeZone: 系统本地时区
  - TTimeZoneDatabase: 时区注册表

🔧 特性：
  • 接口化设计，便于扩展
  • 支持固定偏移时区
  • 支持系统本地时区
  • 时区名称解析

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.offset,
  fafafa.core.time.instant;

type
  TStringArray = array of string;
  
  /// <summary>
  ///   ITimeZone - 时区接口
  ///   提供时区标识、偏移量查询和 DST 状态查询
  /// </summary>
  ITimeZone = interface
    ['{E7A3B5C1-4D2F-4E8A-9B6C-3F1D7E5A2C8B}']
    
    /// <summary>获取时区标识符</summary>
    /// <returns>时区 ID，如 "UTC", "+08:00", "America/New_York"</returns>
    function GetId: string;
    
    /// <summary>获取指定时刻的 UTC 偏移</summary>
    /// <param name="AInstant">时间点</param>
    /// <returns>该时刻的 UTC 偏移</returns>
    function GetOffsetAt(const AInstant: TInstant): TUtcOffset;
    
    /// <summary>判断指定时刻是否处于夏令时</summary>
    /// <param name="AInstant">时间点</param>
    /// <returns>是否处于 DST</returns>
    function IsDST(const AInstant: TInstant): Boolean;
  end;
  
  /// <summary>
  ///   TFixedTimeZone - 固定偏移时区
  ///   偏移量不随时间变化，无 DST
  /// </summary>
  TFixedTimeZone = class(TInterfacedObject, ITimeZone)
  private
    FOffset: TUtcOffset;
    FId: string;
  public
    constructor Create(const AOffset: TUtcOffset);
    
    // ITimeZone
    function GetId: string;
    function GetOffsetAt(const AInstant: TInstant): TUtcOffset;
    function IsDST(const AInstant: TInstant): Boolean;
  end;
  
  /// <summary>
  ///   TSystemTimeZone - 系统本地时区
  ///   使用操作系统的时区设置
  /// </summary>
  TSystemTimeZone = class(TInterfacedObject, ITimeZone)
  private
    FId: string;
  public
    constructor Create;
    
    // ITimeZone
    function GetId: string;
    function GetOffsetAt(const AInstant: TInstant): TUtcOffset;
    function IsDST(const AInstant: TInstant): Boolean;
  end;
  
  /// <summary>
  ///   TTimeZoneDatabase - 时区数据库
  ///   提供时区查找和枚举功能
  /// </summary>
  TTimeZoneDatabase = class
  public
    /// <summary>根据 ID 获取时区</summary>
    /// <param name="AId">时区 ID，支持 "UTC", "Local", "+HH:MM", "-HH:MM"</param>
    /// <returns>时区接口，未找到返回 nil</returns>
    class function GetZone(const AId: string): ITimeZone; static;
    
    /// <summary>获取所有可用的时区 ID</summary>
    /// <returns>时区 ID 数组</returns>
    class function GetAvailableIds: TStringArray; static;
  end;

implementation

{ TFixedTimeZone }

constructor TFixedTimeZone.Create(const AOffset: TUtcOffset);
begin
  inherited Create;
  FOffset := AOffset;
  
  // 生成 ID
  if FOffset.IsUTC then
    FId := 'UTC'
  else
    FId := FOffset.ToISO8601;
end;

function TFixedTimeZone.GetId: string;
begin
  Result := FId;
end;

function TFixedTimeZone.GetOffsetAt(const AInstant: TInstant): TUtcOffset;
begin
  // 固定偏移，忽略时间点参数
  Result := FOffset;
end;

function TFixedTimeZone.IsDST(const AInstant: TInstant): Boolean;
begin
  // 固定偏移时区没有 DST
  Result := False;
end;

{ TSystemTimeZone }

constructor TSystemTimeZone.Create;
begin
  inherited Create;
  FId := 'Local';
end;

function TSystemTimeZone.GetId: string;
begin
  Result := FId;
end;

function TSystemTimeZone.GetOffsetAt(const AInstant: TInstant): TUtcOffset;
begin
  // 使用系统当前的本地时区偏移
  // 注意：这是简化实现，实际应该根据 AInstant 查询历史时区数据
  Result := TUtcOffset.Local;
end;

function TSystemTimeZone.IsDST(const AInstant: TInstant): Boolean;
var
  LUnixSec: Int64;
  LDateTime: TDateTime;
  LYear: Word;
  LJan1, LJul1: TDateTime;
  LJan1Offset, LJul1Offset, LCurrentOffset: Integer;
  LStandardOffset, LDstOffset: Integer;
begin
  // 跨平台 DST 检测方法：
  // 比较给定日期的时区偏移与同一年的 1 月 1 日和 7 月 1 日的偏移。
  // 假设：标准时间（非 DST）对应较小的偏移值（北半球冬季或南半球夏季）
  
  LUnixSec := AInstant.AsUnixSec;
  if LUnixSec < 0 then
  begin
    Result := False;
    Exit;
  end;
  
  LDateTime := UnixToDateTime(LUnixSec, False);  // 不转换为 UTC
  LYear := YearOf(LDateTime);
  
  // 获取 1 月 1 日和 7 月 1 日的时区偏移（分钟）
  LJan1 := EncodeDate(LYear, 1, 1);
  LJul1 := EncodeDate(LYear, 7, 1);
  
  // GetLocalTimeOffset 返回分钟数（UTC 之西为正，之东为负）
  LJan1Offset := -GetLocalTimeOffset(LJan1);  // 取反以获得 UTC+偏移
  LJul1Offset := -GetLocalTimeOffset(LJul1);
  LCurrentOffset := -GetLocalTimeOffset(LDateTime);
  
  // 如果两个偏移相同，该时区没有 DST
  if LJan1Offset = LJul1Offset then
  begin
    Result := False;
    Exit;
  end;
  
  // 标准时间偏移是较小的那个（先东的时区偏移值较大）
  // DST 时，时钟向前调，偏移变大
  if LJan1Offset < LJul1Offset then
  begin
    // 北半球模式：1月是冬季（标准时间），7月是夏季（DST）
    LStandardOffset := LJan1Offset;
    LDstOffset := LJul1Offset;
  end
  else
  begin
    // 南半球模式：7月是冬季（标准时间），1月是夏季（DST）
    LStandardOffset := LJul1Offset;
    LDstOffset := LJan1Offset;
  end;
  
  // 当前偏移等于 DST 偏移则处于夏令时
  Result := LCurrentOffset = LDstOffset;
end;

{ TTimeZoneDatabase }

class function TTimeZoneDatabase.GetZone(const AId: string): ITimeZone;
var
  LOffset: TUtcOffset;
  LUpperId: string;
begin
  Result := nil;
  LUpperId := UpperCase(AId);
  
  // 特殊 ID
  if LUpperId = 'UTC' then
    Exit(TFixedTimeZone.Create(TUtcOffset.UTC));
    
  if LUpperId = 'LOCAL' then
    Exit(TSystemTimeZone.Create);
  
  // 尝试解析固定偏移格式 (+HH:MM, -HH:MM)
  if TUtcOffset.TryParse(AId, LOffset) then
    Exit(TFixedTimeZone.Create(LOffset));
  
  // 未知时区返回 nil
  // 未来可以扩展支持 IANA 时区名称
  Result := nil;
end;

class function TTimeZoneDatabase.GetAvailableIds: TStringArray;
begin
  // 基本实现：返回内置支持的时区
  SetLength(Result, 2);
  Result[0] := 'UTC';
  Result[1] := 'Local';
  
  // 未来可以扩展：
  // - 枚举 /usr/share/zoneinfo 目录
  // - 加载嵌入的 TZDB 数据
end;

end.
