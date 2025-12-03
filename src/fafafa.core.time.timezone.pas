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
begin
  // 简化实现：检查当前时刻的 DST 状态
  // 完整实现需要查询系统时区数据
  LUnixSec := AInstant.AsUnixSec;
  if LUnixSec >= 0 then
  begin
    LDateTime := UnixToDateTime(LUnixSec);
    // FreePascal 没有直接的 DST 查询函数
    // 返回 False 作为简化实现
    Result := False;
  end
  else
    Result := False;
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
