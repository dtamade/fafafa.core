program example_use_cases;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
{$CODEPAGE UTF8}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin;

// ===== 使用场景1: 共享计数器 =====
type
  TSharedCounter = class
  private
    FValue: Integer;
    FLock: ISpin;
  public
    constructor Create;
    procedure Increment;
    procedure Decrement;
    function GetValue: Integer;
    property Value: Integer read GetValue;
  end;

constructor TSharedCounter.Create;
begin
  inherited Create;
  FValue := 0;
  FLock := MakeSpin;
end;

procedure TSharedCounter.Increment;
begin
  FLock.Acquire;
  try
    Inc(FValue);
  finally
    FLock.Release;
  end;
end;

procedure TSharedCounter.Decrement;
begin
  FLock.Acquire;
  try
    Dec(FValue);
  finally
    FLock.Release;
  end;
end;

function TSharedCounter.GetValue: Integer;
begin
  FLock.Acquire;
  try
    Result := FValue;
  finally
    FLock.Release;
  end;
end;

// ===== 使用场景2: 缓存管理 =====
type
  TCacheEntry = record
    Key: string;
    Value: string;
    LastAccess: QWord;
  end;
  
  TSimpleCache = class
  private
    FEntries: array[0..15] of TCacheEntry;
    FLock: ISpinLock;
    function HashKey(const Key: string): Integer;
  public
    constructor Create;
    procedure Put(const Key, Value: string);
    function Get(const Key: string; out Value: string): Boolean;
    procedure Clear;
  end;

constructor TSimpleCache.Create;
var
  Policy: TSpinLockPolicy;
  i: Integer;
begin
  inherited Create;
  
  // 对于缓存，使用中等自旋次数和指数退避
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 64;
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 8;
  
  FLock := MakeSpinLock(Policy);
  
  // 初始化缓存条目
  for i := 0 to High(FEntries) do
  begin
    FEntries[i].Key := '';
    FEntries[i].Value := '';
    FEntries[i].LastAccess := 0;
  end;
end;

function TSimpleCache.HashKey(const Key: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Key) do
    Result := (Result * 31 + Ord(Key[i])) mod Length(FEntries);
end;

procedure TSimpleCache.Put(const Key, Value: string);
var
  Index: Integer;
begin
  Index := HashKey(Key);
  
  FLock.Acquire;
  try
    FEntries[Index].Key := Key;
    FEntries[Index].Value := Value;
    FEntries[Index].LastAccess := GetTickCount64;
  finally
    FLock.Release;
  end;
end;

function TSimpleCache.Get(const Key: string; out Value: string): Boolean;
var
  Index: Integer;
begin
  Index := HashKey(Key);
  
  FLock.Acquire;
  try
    if FEntries[Index].Key = Key then
    begin
      Value := FEntries[Index].Value;
      FEntries[Index].LastAccess := GetTickCount64;
      Result := True;
    end
    else
    begin
      Value := '';
      Result := False;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TSimpleCache.Clear;
var
  i: Integer;
begin
  FLock.Acquire;
  try
    for i := 0 to High(FEntries) do
    begin
      FEntries[i].Key := '';
      FEntries[i].Value := '';
      FEntries[i].LastAccess := 0;
    end;
  finally
    FLock.Release;
  end;
end;

// ===== 使用场景3: 工作队列 =====
type
  TWorkItem = record
    ID: Integer;
    Data: string;
  end;
  
  TWorkQueue = class
  private
    FItems: array[0..99] of TWorkItem;
    FHead, FTail, FCount: Integer;
    FLock: ISpinLock;
  public
    constructor Create;
    function Enqueue(const Item: TWorkItem): Boolean;
    function Dequeue(out Item: TWorkItem): Boolean;
    function GetCount: Integer;
    property Count: Integer read GetCount;
  end;

constructor TWorkQueue.Create;
var
  Policy: TSpinLockPolicy;
begin
  inherited Create;
  FHead := 0;
  FTail := 0;
  FCount := 0;
  
  // 对于队列，使用高自旋次数和自适应退避
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 128;
  Policy.BackoffStrategy := sbsAdaptive;
  Policy.MaxBackoffMs := 16;
  
  FLock := MakeSpinLock(Policy);
end;

function TWorkQueue.Enqueue(const Item: TWorkItem): Boolean;
begin
  FLock.Acquire;
  try
    if FCount < Length(FItems) then
    begin
      FItems[FTail] := Item;
      FTail := (FTail + 1) mod Length(FItems);
      Inc(FCount);
      Result := True;
    end
    else
      Result := False; // 队列满
  finally
    FLock.Release;
  end;
end;

function TWorkQueue.Dequeue(out Item: TWorkItem): Boolean;
begin
  FLock.Acquire;
  try
    if FCount > 0 then
    begin
      Item := FItems[FHead];
      FHead := (FHead + 1) mod Length(FItems);
      Dec(FCount);
      Result := True;
    end
    else
    begin
      Item.ID := 0;
      Item.Data := '';
      Result := False; // 队列空
    end;
  finally
    FLock.Release;
  end;
end;

function TWorkQueue.GetCount: Integer;
begin
  FLock.Acquire;
  try
    Result := FCount;
  finally
    FLock.Release;
  end;
end;

// ===== 主程序 =====
procedure DemoSharedCounter;
var
  Counter: TSharedCounter;
  i: Integer;
begin
  WriteLn('=== 共享计数器示例 ===');
  
  Counter := TSharedCounter.Create;
  try
    WriteLn('初始值: ', Counter.Value);
    
    for i := 1 to 10 do
      Counter.Increment;
    WriteLn('增加10次后: ', Counter.Value);
    
    for i := 1 to 3 do
      Counter.Decrement;
    WriteLn('减少3次后: ', Counter.Value);
  finally
    Counter.Free;
  end;
  
  WriteLn('');
end;

procedure DemoSimpleCache;
var
  Cache: TSimpleCache;
  Value: string;
begin
  WriteLn('=== 简单缓存示例 ===');
  
  Cache := TSimpleCache.Create;
  try
    // 存储一些值
    Cache.Put('key1', 'value1');
    Cache.Put('key2', 'value2');
    Cache.Put('key3', 'value3');
    
    // 读取值
    if Cache.Get('key1', Value) then
      WriteLn('key1 = ', Value)
    else
      WriteLn('key1 not found');
    
    if Cache.Get('key2', Value) then
      WriteLn('key2 = ', Value)
    else
      WriteLn('key2 not found');
    
    if Cache.Get('nonexistent', Value) then
      WriteLn('nonexistent = ', Value)
    else
      WriteLn('nonexistent not found');
    
    Cache.Clear;
    WriteLn('缓存已清空');
  finally
    Cache.Free;
  end;
  
  WriteLn('');
end;

procedure DemoWorkQueue;
var
  Queue: TWorkQueue;
  Item: TWorkItem;
  i: Integer;
begin
  WriteLn('=== 工作队列示例 ===');
  
  Queue := TWorkQueue.Create;
  try
    WriteLn('初始队列大小: ', Queue.Count);
    
    // 添加一些工作项
    for i := 1 to 5 do
    begin
      Item.ID := i;
      Item.Data := 'Work item ' + IntToStr(i);
      if Queue.Enqueue(Item) then
        WriteLn('已入队: ', Item.Data)
      else
        WriteLn('入队失败: ', Item.Data);
    end;
    
    WriteLn('入队后队列大小: ', Queue.Count);
    
    // 处理工作项
    while Queue.Dequeue(Item) do
      WriteLn('已出队: ', Item.Data);
    
    WriteLn('处理完成后队列大小: ', Queue.Count);
  finally
    Queue.Free;
  end;
  
  WriteLn('');
end;

begin
  WriteLn('自旋锁使用场景示例');
  WriteLn('==================');
  WriteLn('');
  
  DemoSharedCounter;
  DemoSimpleCache;
  DemoWorkQueue;
  
  WriteLn('所有示例完成！');
end.
