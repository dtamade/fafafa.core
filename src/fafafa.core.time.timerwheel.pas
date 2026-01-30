{
  fafafa.core.time.timerwheel - 时间轮定时器
  
  基于时间轮算法的高性能定时器实现。
  适用于大量定时器的场景，如网络服务器连接超时管理等。
  
  时间复杂度:
  - 添加定时器: O(1)
  - 取消定时器: O(1)
  - Tick推进: O(n) 其中n为当前槽中的定时器数量
}
unit fafafa.core.time.timerwheel;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils;

type
  { 定时器ID类型 }
  TTimerId = Int64;
  
  { 定时器回调函数类型 }
  TTimerCallback = procedure(AData: Pointer);

const
  { 无效的定时器ID }
  INVALID_TIMER_ID: TTimerId = -1;

type
  { 定时器条目 }
  PTimerEntry = ^TTimerEntry;
  TTimerEntry = record
    Id: TTimerId;
    Callback: TTimerCallback;
    Data: Pointer;
    Rounds: Integer;      // 剩余轮数
    Interval: Integer;    // 重复间隔(ms)，0表示一次性
    IsRepeat: Boolean;
    Next: PTimerEntry;
    Prev: PTimerEntry;
  end;

  { TTimerWheel - 时间轮定时器 }
  TTimerWheel = class
  private
    FSlots: array of PTimerEntry;   // 槽数组
    FSlotCount: Integer;            // 槽数量
    FTickInterval: Integer;         // tick间隔(ms)
    FCurrentSlot: Integer;          // 当前槽索引
    FTimerCount: Integer;           // 定时器总数
    FNextId: TTimerId;              // 下一个定时器ID
    
    function CalcSlotAndRounds(ADelayMs: Integer; out ARounds: Integer): Integer;
    procedure AddToSlot(ASlot: Integer; AEntry: PTimerEntry);
    procedure RemoveFromSlot(AEntry: PTimerEntry; ASlot: Integer);
    function FindEntry(AId: TTimerId; out ASlot: Integer): PTimerEntry;
  public
    constructor Create(ASlotCount: Integer = 64; ATickInterval: Integer = 10);
    destructor Destroy; override;
    
    { 添加一次性定时器 }
    function AddTimer(ADelayMs: Integer; ACallback: TTimerCallback; AData: Pointer): TTimerId;
    
    { 添加重复定时器 }
    function AddRepeatTimer(AIntervalMs: Integer; ACallback: TTimerCallback; AData: Pointer): TTimerId;
    
    { 取消定时器 }
    function CancelTimer(AId: TTimerId): Boolean;
    
    { 推进一个tick }
    procedure Tick;
    
    { 属性 }
    property SlotCount: Integer read FSlotCount;
    property TickInterval: Integer read FTickInterval;
    property TimerCount: Integer read FTimerCount;
  end;

implementation

{ TTimerWheel }

constructor TTimerWheel.Create(ASlotCount: Integer; ATickInterval: Integer);
var
  I: Integer;
begin
  inherited Create;
  FSlotCount := ASlotCount;
  FTickInterval := ATickInterval;
  FCurrentSlot := 0;
  FTimerCount := 0;
  FNextId := 1;
  
  SetLength(FSlots, FSlotCount);
  for I := 0 to FSlotCount - 1 do
    FSlots[I] := nil;
end;

destructor TTimerWheel.Destroy;
var
  I: Integer;
  Entry, Next: PTimerEntry;
begin
  // 释放所有定时器条目
  for I := 0 to FSlotCount - 1 do
  begin
    Entry := FSlots[I];
    while Entry <> nil do
    begin
      Next := Entry^.Next;
      Dispose(Entry);
      Entry := Next;
    end;
  end;
  SetLength(FSlots, 0);
  inherited Destroy;
end;

function TTimerWheel.CalcSlotAndRounds(ADelayMs: Integer; out ARounds: Integer): Integer;
var
  Ticks: Integer;
begin
  // 计算需要的tick数（向上取整）
  Ticks := ADelayMs div FTickInterval;
  if Ticks < 1 then
    Ticks := 1;
  
  // 计算目标槽和轮数
  // 定时器在 Ticks 次 Tick 后触发
  // 例如 Ticks=5，当前槽=0：定时器放入槽4，第5次Tick时处理槽4
  ARounds := Ticks div FSlotCount;
  Result := (FCurrentSlot + Ticks - 1 + FSlotCount) mod FSlotCount;
end;

procedure TTimerWheel.AddToSlot(ASlot: Integer; AEntry: PTimerEntry);
begin
  AEntry^.Next := FSlots[ASlot];
  AEntry^.Prev := nil;
  if FSlots[ASlot] <> nil then
    FSlots[ASlot]^.Prev := AEntry;
  FSlots[ASlot] := AEntry;
  Inc(FTimerCount);
end;

procedure TTimerWheel.RemoveFromSlot(AEntry: PTimerEntry; ASlot: Integer);
begin
  if AEntry^.Prev <> nil then
    AEntry^.Prev^.Next := AEntry^.Next
  else
    FSlots[ASlot] := AEntry^.Next;
    
  if AEntry^.Next <> nil then
    AEntry^.Next^.Prev := AEntry^.Prev;
    
  Dec(FTimerCount);
end;

function TTimerWheel.FindEntry(AId: TTimerId; out ASlot: Integer): PTimerEntry;
var
  I: Integer;
  Entry: PTimerEntry;
begin
  Result := nil;
  for I := 0 to FSlotCount - 1 do
  begin
    Entry := FSlots[I];
    while Entry <> nil do
    begin
      if Entry^.Id = AId then
      begin
        ASlot := I;
        Exit(Entry);
      end;
      Entry := Entry^.Next;
    end;
  end;
end;

function TTimerWheel.AddTimer(ADelayMs: Integer; ACallback: TTimerCallback; AData: Pointer): TTimerId;
var
  Entry: PTimerEntry;
  Slot, Rounds: Integer;
begin
  Slot := CalcSlotAndRounds(ADelayMs, Rounds);
  
  New(Entry);
  Entry^.Id := FNextId;
  Entry^.Callback := ACallback;
  Entry^.Data := AData;
  Entry^.Rounds := Rounds;
  Entry^.Interval := 0;
  Entry^.IsRepeat := False;
  
  AddToSlot(Slot, Entry);
  
  Result := FNextId;
  Inc(FNextId);
end;

function TTimerWheel.AddRepeatTimer(AIntervalMs: Integer; ACallback: TTimerCallback; AData: Pointer): TTimerId;
var
  Entry: PTimerEntry;
  Slot, Rounds: Integer;
begin
  Slot := CalcSlotAndRounds(AIntervalMs, Rounds);
  
  New(Entry);
  Entry^.Id := FNextId;
  Entry^.Callback := ACallback;
  Entry^.Data := AData;
  Entry^.Rounds := Rounds;
  Entry^.Interval := AIntervalMs;
  Entry^.IsRepeat := True;
  
  AddToSlot(Slot, Entry);
  
  Result := FNextId;
  Inc(FNextId);
end;

function TTimerWheel.CancelTimer(AId: TTimerId): Boolean;
var
  Entry: PTimerEntry;
  Slot: Integer;
begin
  Entry := FindEntry(AId, Slot);
  if Entry = nil then
    Exit(False);
    
  RemoveFromSlot(Entry, Slot);
  Dispose(Entry);
  Result := True;
end;

procedure TTimerWheel.Tick;
var
  Entry, Next: PTimerEntry;
  Slot, Rounds: Integer;
  RepeatList: PTimerEntry;
begin
  RepeatList := nil;
  
  // 遍历当前槽的所有定时器
  Entry := FSlots[FCurrentSlot];
  while Entry <> nil do
  begin
    Next := Entry^.Next;
    
    if Entry^.Rounds > 0 then
    begin
      // 还有剩余轮数，减1
      Dec(Entry^.Rounds);
    end
    else
    begin
      // 时间到，触发回调
      if Assigned(Entry^.Callback) then
        Entry^.Callback(Entry^.Data);
      
      // 从当前槽移除
      RemoveFromSlot(Entry, FCurrentSlot);
      
      if Entry^.IsRepeat then
      begin
        // 收集重复定时器，等槽前进后再添加
        Entry^.Next := RepeatList;
        RepeatList := Entry;
      end
      else
      begin
        // 一次性定时器，释放
        Dispose(Entry);
      end;
    end;
    
    Entry := Next;
  end;
  
  // 移动到下一个槽
  FCurrentSlot := (FCurrentSlot + 1) mod FSlotCount;
  
  // 重新添加重复定时器（从新的当前槽位置计算）
  Entry := RepeatList;
  while Entry <> nil do
  begin
    Next := Entry^.Next;
    Slot := CalcSlotAndRounds(Entry^.Interval, Rounds);
    Entry^.Rounds := Rounds;
    AddToSlot(Slot, Entry);
    Entry := Next;
  end;
end;

end.
