{
  fafafa.core.id.sonyflake — Sony's Snowflake variant

  Sonyflake 是 Sony 设计的分布式 ID 生成算法:
  - 39 位时间戳 (10ms 单位) - 约 174 年
  - 8 位序列号 (每 10ms 256 个 ID)
  - 16 位机器 ID (65536 台机器)

  对比 Snowflake:
  - Snowflake: 41 时间 + 12 序列 + 10 机器 (4096 ID/ms, 1024 机器)
  - Sonyflake: 39 时间 + 8 序列 + 16 机器 (256 ID/10ms, 65536 机器)

  Sonyflake 适合大规模分布式系统，机器数量多但单机生成频率较低的场景

  Layout (63 bits):
    bit 0:      符号位 (始终为 0，保持正数)
    bits 1-39:  时间戳 (10ms 单位，从 epoch 开始)
    bits 40-47: 序列号 (0-255)
    bits 48-63: 机器 ID (0-65535)
}

unit fafafa.core.id.sonyflake;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.id.time;

type
  TSonyflakeID = Int64;

  { 时钟回退策略 }
  TSonyflakeClockPolicy = (
    scpSpinWait,    // 自旋等待时钟追上
    scpRaiseError,  // 抛出异常
    scpSkipAhead    // 跳过到最后已知时间
  );

  { Sonyflake 生成器接口 }
  ISonyflakeGenerator = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // ✅ P1: 统一方法命名 - NextRaw 返回原始类型
    function NextRaw: TSonyflakeID;
    function Next: string;
    // 向后兼容
    function NextID: TSonyflakeID; deprecated 'Use NextRaw instead';
    function GetMachineID: Word;
    function GetEpochMs: Int64;
    function Decompose(ID: TSonyflakeID; out TimeUnits, Sequence: Int64; out MachineID: Word): Boolean;
    property MachineID: Word read GetMachineID;
    property EpochMs: Int64 read GetEpochMs;
  end;

  // ✅ P1: 向后兼容别名
  ISonyflake = ISonyflakeGenerator;

  { Sonyflake 生成器实现 }
  TSonyflakeGenerator = class(TInterfacedObject, ISonyflakeGenerator)
  private const
    TIME_BITS = 39;
    SEQUENCE_BITS = 8;
    MACHINE_BITS = 16;
    MAX_SEQUENCE = (1 shl SEQUENCE_BITS) - 1;  // 255
    TIME_UNIT_MS = 10;  // 10ms per unit
  private
    FLock: TCriticalSection;  // ✅ P0: 线程安全锁
    FMachineID: Word;
    FEpochMs: Int64;
    FLastTime: Int64;      // 上次时间单位
    FSequence: Byte;       // 序列号
    FClockPolicy: TSonyflakeClockPolicy;

    function CurrentTimeUnits: Int64;
    function WaitForNextTimeUnit(LastTime: Int64): Int64;
  public
    constructor Create(AMachineID: Word; AEpochMs: Int64 = 0);
    destructor Destroy; override;  // ✅ P0: 析构函数

    function NextRaw: TSonyflakeID;
    function Next: string;
    function NextID: TSonyflakeID;
    function GetMachineID: Word;
    function GetEpochMs: Int64;
    function Decompose(ID: TSonyflakeID; out TimeUnits, Sequence: Int64; out MachineID: Word): Boolean;

    property ClockPolicy: TSonyflakeClockPolicy read FClockPolicy write FClockPolicy;
    property MachineID: Word read GetMachineID;
    property EpochMs: Int64 read GetEpochMs;
  end;

{ 工厂函数 }
function CreateSonyflake(MachineID: Word; EpochMs: Int64 = 0): ISonyflake;

{ 默认 Sonyflake Epoch (2014-09-01 00:00:00 UTC) }
const
  SONYFLAKE_DEFAULT_EPOCH = 1409529600000;  // 2014-09-01 UTC in ms

{ 便捷函数 }
function SonyflakeToString(ID: TSonyflakeID): string;
function SonyflakeFromString(const S: string): TSonyflakeID;
function SonyflakeTimestamp(ID: TSonyflakeID; EpochMs: Int64 = SONYFLAKE_DEFAULT_EPOCH): TDateTime;
function SonyflakeMachineID(ID: TSonyflakeID): Word;
function SonyflakeSequence(ID: TSonyflakeID): Byte;

implementation

{ Factory }

function CreateSonyflake(MachineID: Word; EpochMs: Int64): ISonyflake;
begin
  if EpochMs = 0 then
    EpochMs := SONYFLAKE_DEFAULT_EPOCH;
  Result := TSonyflakeGenerator.Create(MachineID, EpochMs);
end;

{ TSonyflakeGenerator }

constructor TSonyflakeGenerator.Create(AMachineID: Word; AEpochMs: Int64);
begin
  inherited Create;
  FLock := TCriticalSection.Create;  // ✅ P0: 创建线程安全锁
  FMachineID := AMachineID;
  FEpochMs := AEpochMs;
  FLastTime := -1;
  FSequence := 0;
  FClockPolicy := scpSpinWait;
end;

destructor TSonyflakeGenerator.Destroy;
begin
  // ✅ P0: 清理敏感数据
  FLastTime := 0;
  FSequence := 0;
  FLock.Free;
  inherited Destroy;
end;

function TSonyflakeGenerator.CurrentTimeUnits: Int64;
begin
  Result := (NowUnixMs - FEpochMs) div TIME_UNIT_MS;
end;

function TSonyflakeGenerator.WaitForNextTimeUnit(LastTime: Int64): Int64;
begin
  Result := CurrentTimeUnits;
  while Result <= LastTime do
  begin
    Sleep(1);
    Result := CurrentTimeUnits;
  end;
end;

function TSonyflakeGenerator.NextID: TSonyflakeID;
begin
  Result := NextRaw;
end;

// ✅ P1: 新增 Next 方法返回字符串
function TSonyflakeGenerator.Next: string;
begin
  Result := IntToStr(NextRaw);
end;

function TSonyflakeGenerator.NextRaw: TSonyflakeID;
var
  TimeUnits: Int64;
begin
  // ✅ P0: 线程安全 - 保护内部状态
  FLock.Acquire;
  try
    TimeUnits := CurrentTimeUnits;

    if TimeUnits < FLastTime then
    begin
      // 时钟回退
      case FClockPolicy of
        scpSpinWait:
          TimeUnits := WaitForNextTimeUnit(FLastTime);
        scpRaiseError:
          raise Exception.CreateFmt('Sonyflake clock rollback: current=%d, last=%d',
            [TimeUnits, FLastTime]);
        scpSkipAhead:
          TimeUnits := FLastTime;
      end;
    end;

    if TimeUnits = FLastTime then
    begin
      // 同一时间单位，递增序列号
      Inc(FSequence);
      if FSequence > MAX_SEQUENCE then
      begin
        // 序列号溢出，等待下一个时间单位
        TimeUnits := WaitForNextTimeUnit(FLastTime);
        FSequence := 0;
      end;
    end
    else
    begin
      // 新时间单位，重置序列号
      FSequence := 0;
    end;

    FLastTime := TimeUnits;

    // 组装 ID: 时间(39位) | 序列(8位) | 机器ID(16位)
    Result := (TimeUnits shl (SEQUENCE_BITS + MACHINE_BITS)) or
              (Int64(FSequence) shl MACHINE_BITS) or
              Int64(FMachineID);
  finally
    FLock.Release;
  end;
end;

function TSonyflakeGenerator.GetMachineID: Word;
begin
  Result := FMachineID;
end;

function TSonyflakeGenerator.GetEpochMs: Int64;
begin
  Result := FEpochMs;
end;

function TSonyflakeGenerator.Decompose(ID: TSonyflakeID; out TimeUnits, Sequence: Int64; out MachineID: Word): Boolean;
begin
  if ID < 0 then
  begin
    Result := False;
    TimeUnits := 0;
    Sequence := 0;
    MachineID := 0;
    Exit;
  end;

  MachineID := Word(ID and $FFFF);
  Sequence := (ID shr MACHINE_BITS) and MAX_SEQUENCE;
  TimeUnits := ID shr (SEQUENCE_BITS + MACHINE_BITS);
  Result := True;
end;

{ Convenience functions }

function SonyflakeToString(ID: TSonyflakeID): string;
begin
  Result := IntToStr(ID);
end;

function SonyflakeFromString(const S: string): TSonyflakeID;
begin
  Result := StrToInt64(S);
end;

function SonyflakeTimestamp(ID: TSonyflakeID; EpochMs: Int64): TDateTime;
var
  TimeUnits: Int64;
  Ms: Int64;
begin
  TimeUnits := ID shr (8 + 16);  // shift out sequence and machine bits
  Ms := EpochMs + (TimeUnits * 10);  // 10ms units
  Result := UnixToDateTime(Ms div 1000, False) + EncodeTime(0, 0, 0, Ms mod 1000);
end;

function SonyflakeMachineID(ID: TSonyflakeID): Word;
begin
  Result := Word(ID and $FFFF);
end;

function SonyflakeSequence(ID: TSonyflakeID): Byte;
begin
  Result := Byte((ID shr 16) and $FF);
end;

end.
