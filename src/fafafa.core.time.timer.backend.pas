unit fafafa.core.time.timer.backend;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{*
  fafafa.core.time.timer.backend - 定时器队列后端接口

  提供可插拔的定时器队列后端抽象，允许在不同实现之间切换：
  - BinaryHeapBackend: 基于二叉堆，适用于中小规模定时器（默认）
  - HashedWheelBackend: 基于时间轮，适用于大量定时器场景

  时间复杂度对比:
  ┌─────────────────┬──────────────────┬──────────────────┐
  │ 操作            │ BinaryHeap       │ HashedWheel      │
  ├─────────────────┼──────────────────┼──────────────────┤
  │ Enqueue         │ O(log n)         │ O(1)             │
  │ Dequeue         │ O(log n)         │ O(1)*            │
  │ PeekNext        │ O(1)             │ O(1)             │
  │ Remove          │ O(log n)         │ O(1)             │
  │ Update          │ O(log n)         │ O(1)             │
  └─────────────────┴──────────────────┴──────────────────┘
  * 时间轮的 Dequeue 是分摊 O(1)，需要 Tick 驱动

  设计决策:
  - 后端不持有 Entry 的所有权，由 Scheduler 负责生命周期管理
  - 后端不处理线程安全，由调用者（Scheduler）负责加锁
  - 后端只关心 Entry 的 Deadline 字段用于排序
*}

interface

uses
  SysUtils,
  fafafa.core.time.instant;

type
  // 前向声明 - 实际类型在 fafafa.core.time.timer 中定义
  // 这里只需要指针操作，不需要完整类型定义
  PTimerEntryOpaque = Pointer;

  {**
   * ITimerQueueBackend - 定时器队列后端接口
   *
   * 提供定时器队列的核心操作抽象。
   * 所有实现必须保证：
   * - Dequeue 返回的是 Deadline 最早的条目
   * - 同一 Entry 不能重复入队（除非先移除）
   *}
  ITimerQueueBackend = interface
    ['{F7A8B9C0-D1E2-4F3A-B5C6-7D8E9F0A1B2C}']

    {** 入队一个定时器条目 *}
    procedure Enqueue(E: PTimerEntryOpaque);

    {** 出队最早到期的条目，如果队列为空返回 nil *}
    function Dequeue: PTimerEntryOpaque;

    {** 批量出队所有已到期的条目（截止时间 <= Now）
        @param Now 当前时间
        @param MaxCount 最大返回数量（0 = 无限制）
        @param DueEntries 输出数组（调用者负责分配）
        @return 实际返回的条目数量 *}
    function PopDue(const Now: TInstant; MaxCount: Integer; out DueEntries: array of PTimerEntryOpaque): Integer;

    {** 查看最早到期的条目（不移除），如果队列为空返回 nil *}
    function Peek: PTimerEntryOpaque;

    {** 获取最早到期时间，如果队列为空返回 False *}
    function PeekNextDeadline(out Dl: TInstant): Boolean;

    {** 移除指定条目（通过 HeapIndex 快速定位） *}
    procedure Remove(E: PTimerEntryOpaque);

    {** 更新条目的截止时间后重新排序 *}
    procedure UpdateDeadline(E: PTimerEntryOpaque);

    {** 当前队列中的条目数量 *}
    function Count: Integer;

    {** 队列是否为空 *}
    function IsEmpty: Boolean;

    {** 清空队列（不释放 Entry，只移除引用） *}
    procedure Clear;

    {** 后端名称（用于调试/日志） *}
    function GetName: string;
  end;

  {**
   * TTimerQueueBackendKind - 后端类型枚举
   *}
  TTimerQueueBackendKind = (
    tbkBinaryHeap,    // 二叉堆（默认）
    tbkHashedWheel    // 时间轮
  );

  {**
   * TBackendConfig - 后端配置
   *}
  TBackendConfig = record
    Kind: TTimerQueueBackendKind;
    // 时间轮专用配置
    WheelSlotCount: Integer;     // 槽数量（默认 64）
    WheelTickIntervalMs: Integer; // Tick 间隔（默认 10ms）
  end;

const
  DEFAULT_BACKEND_CONFIG: TBackendConfig = (
    Kind: tbkBinaryHeap;
    WheelSlotCount: 64;
    WheelTickIntervalMs: 10;
  );

{** 创建默认后端（二叉堆） *}
function CreateDefaultBackend: ITimerQueueBackend;

{** 根据配置创建后端 *}
function CreateBackend(const Config: TBackendConfig): ITimerQueueBackend;

{** 创建二叉堆后端 *}
function CreateBinaryHeapBackend: ITimerQueueBackend;

{** 创建时间轮后端 *}
function CreateHashedWheelBackend(SlotCount: Integer = 64; TickIntervalMs: Integer = 10): ITimerQueueBackend;

{** 工厂注册（供后端实现单元调用） *}
type
  TBackendFactory = function: ITimerQueueBackend;
  TBackendFactoryWithConfig = function(SlotCount, TickMs: Integer): ITimerQueueBackend;

procedure RegisterBinaryHeapFactory(F: TBackendFactory);
procedure RegisterHashedWheelFactory(F: TBackendFactoryWithConfig);

implementation

// 后端实现将在单独的单元中提供
// 这里提供延迟绑定的工厂函数

var
  GBinaryHeapFactory: TBackendFactory = nil;
  GHashedWheelFactory: TBackendFactoryWithConfig = nil;

procedure RegisterBinaryHeapFactory(F: TBackendFactory);
begin
  GBinaryHeapFactory := F;
end;

procedure RegisterHashedWheelFactory(F: TBackendFactoryWithConfig);
begin
  GHashedWheelFactory := F;
end;

function CreateDefaultBackend: ITimerQueueBackend;
begin
  Result := CreateBinaryHeapBackend;
end;

function CreateBackend(const Config: TBackendConfig): ITimerQueueBackend;
begin
  case Config.Kind of
    tbkBinaryHeap:
      Result := CreateBinaryHeapBackend;
    tbkHashedWheel:
      Result := CreateHashedWheelBackend(Config.WheelSlotCount, Config.WheelTickIntervalMs);
  end;
  // 注意: 所有 TBackendKind 枚举值已覆盖，无需 else 分支
end;

function CreateBinaryHeapBackend: ITimerQueueBackend;
begin
  if Assigned(GBinaryHeapFactory) then
    Result := GBinaryHeapFactory()
  else
    raise Exception.Create('BinaryHeapBackend factory not registered. Include fafafa.core.time.timer.backend.heap unit.');
end;

function CreateHashedWheelBackend(SlotCount: Integer; TickIntervalMs: Integer): ITimerQueueBackend;
begin
  if Assigned(GHashedWheelFactory) then
    Result := GHashedWheelFactory(SlotCount, TickIntervalMs)
  else
    raise Exception.Create('HashedWheelBackend factory not registered. Include fafafa.core.time.timer.backend.wheel unit.');
end;

end.
