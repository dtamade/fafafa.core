program ReaderWriterLock;

{$mode objfpc}{$H+}

{
  读写锁模拟示例
  
  本示例演示：
  1. 使用事件实现读写锁
  2. 多读者单写者模式
  3. 读写优先级控制
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 使用事件实现的读写锁 }
  TEventReaderWriterLock = class
  private
    FReadersCount: Integer;
    FWritersWaiting: Integer;
    FWriterActive: Boolean;
    FLock: TRTLCriticalSection;
    FReadersEvent: IEvent;   // 读者可以进入的信号
    FWriterEvent: IEvent;    // 写者可以进入的信号
    
    procedure UpdateEvents;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    
    function GetReadersCount: Integer;
    function GetWritersWaiting: Integer;
    function IsWriterActive: Boolean;
  end;

  { 读者线程 }
  TReaderThread = class(TThread)
  private
    FReaderId: Integer;
    FLock: TEventReaderWriterLock;
    FSharedData: PInteger;
    FReadsPerformed: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AReaderId: Integer; ALock: TEventReaderWriterLock; ASharedData: PInteger);
    property ReadsPerformed: Integer read FReadsPerformed;
  end;

  { 写者线程 }
  TWriterThread = class(TThread)
  private
    FWriterId: Integer;
    FLock: TEventReaderWriterLock;
    FSharedData: PInteger;
    FWritesPerformed: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AWriterId: Integer; ALock: TEventReaderWriterLock; ASharedData: PInteger);
    property WritesPerformed: Integer read FWritesPerformed;
  end;

{ TEventReaderWriterLock }
constructor TEventReaderWriterLock.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
  FReadersCount := 0;
  FWritersWaiting := 0;
  FWriterActive := False;
  
  // 初始状态：读者可以进入，写者不能进入
  FReadersEvent := MakeEvent(True, True);   // 手动重置，初始信号
  FWriterEvent := MakeEvent(True, False);   // 手动重置，初始无信号
end;

destructor TEventReaderWriterLock.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TEventReaderWriterLock.UpdateEvents;
begin
  // 更新读者事件：没有写者活动且没有写者等待时，读者可以进入
  if not FWriterActive and (FWritersWaiting = 0) then
    FReadersEvent.SetEvent
  else
    FReadersEvent.ResetEvent;
    
  // 更新写者事件：没有读者且没有写者活动时，写者可以进入
  if (FReadersCount = 0) and not FWriterActive then
    FWriterEvent.SetEvent
  else
    FWriterEvent.ResetEvent;
end;

procedure TEventReaderWriterLock.AcquireRead;
begin
  while True do
  begin
    // 等待读者可以进入的信号
    FReadersEvent.WaitFor;
    
    EnterCriticalSection(FLock);
    try
      // 再次检查条件（避免竞争条件）
      if not FWriterActive and (FWritersWaiting = 0) then
      begin
        Inc(FReadersCount);
        UpdateEvents;
        Break; // 成功获取读锁
      end;
    finally
      LeaveCriticalSection(FLock);
    end;
    
    // 条件不满足，继续等待
    Sleep(1);
  end;
end;

procedure TEventReaderWriterLock.ReleaseRead;
begin
  EnterCriticalSection(FLock);
  try
    Dec(FReadersCount);
    UpdateEvents;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TEventReaderWriterLock.AcquireWrite;
begin
  EnterCriticalSection(FLock);
  try
    Inc(FWritersWaiting);
    UpdateEvents;
  finally
    LeaveCriticalSection(FLock);
  end;
  
  while True do
  begin
    // 等待写者可以进入的信号
    FWriterEvent.WaitFor;
    
    EnterCriticalSection(FLock);
    try
      // 再次检查条件
      if (FReadersCount = 0) and not FWriterActive then
      begin
        FWriterActive := True;
        Dec(FWritersWaiting);
        UpdateEvents;
        Break; // 成功获取写锁
      end;
    finally
      LeaveCriticalSection(FLock);
    end;
    
    // 条件不满足，继续等待
    Sleep(1);
  end;
end;

procedure TEventReaderWriterLock.ReleaseWrite;
begin
  EnterCriticalSection(FLock);
  try
    FWriterActive := False;
    UpdateEvents;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TEventReaderWriterLock.GetReadersCount: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FReadersCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TEventReaderWriterLock.GetWritersWaiting: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FWritersWaiting;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TEventReaderWriterLock.IsWriterActive: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FWriterActive;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

{ TReaderThread }
constructor TReaderThread.Create(AReaderId: Integer; ALock: TEventReaderWriterLock; ASharedData: PInteger);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FReaderId := AReaderId;
  FLock := ALock;
  FSharedData := ASharedData;
  FReadsPerformed := 0;
end;

procedure TReaderThread.Execute;
var
  i: Integer;
  Value: Integer;
begin
  WriteLn('读者 ', FReaderId, ' 开始工作');
  
  for i := 1 to 5 do
  begin
    if Terminated then Break;
    
    // 获取读锁
    WriteLn('读者 ', FReaderId, ' 请求读锁');
    FLock.AcquireRead;
    
    try
      // 读取共享数据
      Value := FSharedData^;
      WriteLn('读者 ', FReaderId, ' 读取到值：', Value, 
              ' (当前读者数：', FLock.GetReadersCount, ')');
      Inc(FReadsPerformed);
      
      // 模拟读取时间
      Sleep(100 + Random(200));
      
    finally
      // 释放读锁
      FLock.ReleaseRead;
      WriteLn('读者 ', FReaderId, ' 释放读锁');
    end;
    
    // 读取间隔
    Sleep(50 + Random(100));
  end;
  
  WriteLn('读者 ', FReaderId, ' 完成，共读取 ', FReadsPerformed, ' 次');
end;

{ TWriterThread }
constructor TWriterThread.Create(AWriterId: Integer; ALock: TEventReaderWriterLock; ASharedData: PInteger);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWriterId := AWriterId;
  FLock := ALock;
  FSharedData := ASharedData;
  FWritesPerformed := 0;
end;

procedure TWriterThread.Execute;
var
  i: Integer;
  NewValue: Integer;
begin
  WriteLn('写者 ', FWriterId, ' 开始工作');
  
  for i := 1 to 3 do
  begin
    if Terminated then Break;
    
    // 获取写锁
    WriteLn('写者 ', FWriterId, ' 请求写锁 (等待写者：', FLock.GetWritersWaiting + 1, ')');
    FLock.AcquireWrite;
    
    try
      // 写入共享数据
      NewValue := FWriterId * 1000 + i;
      WriteLn('写者 ', FWriterId, ' 将值从 ', FSharedData^, ' 改为 ', NewValue);
      FSharedData^ := NewValue;
      Inc(FWritesPerformed);
      
      // 模拟写入时间
      Sleep(200 + Random(300));
      
    finally
      // 释放写锁
      FLock.ReleaseWrite;
      WriteLn('写者 ', FWriterId, ' 释放写锁');
    end;
    
    // 写入间隔
    Sleep(100 + Random(200));
  end;
  
  WriteLn('写者 ', FWriterId, ' 完成，共写入 ', FWritesPerformed, ' 次');
end;

procedure RunReaderWriterDemo;
const
  ReaderCount = 4;
  WriterCount = 2;
var
  Lock: TEventReaderWriterLock;
  SharedData: Integer;
  Readers: array[0..ReaderCount-1] of TReaderThread;
  Writers: array[0..WriterCount-1] of TWriterThread;
  i: Integer;
  TotalReads, TotalWrites: Integer;
begin
  WriteLn('=== 读写锁演示 ===');
  WriteLn('读者数量：', ReaderCount);
  WriteLn('写者数量：', WriterCount);
  WriteLn;
  
  SharedData := 0;
  Lock := TEventReaderWriterLock.Create;
  try
    // 创建读者线程
    for i := 0 to ReaderCount - 1 do
    begin
      Readers[i] := TReaderThread.Create(i + 1, Lock, @SharedData);
      Readers[i].Start;
    end;
    
    // 创建写者线程
    for i := 0 to WriterCount - 1 do
    begin
      Writers[i] := TWriterThread.Create(i + 1, Lock, @SharedData);
      Writers[i].Start;
    end;
    
    // 等待所有线程完成
    for i := 0 to ReaderCount - 1 do
    begin
      Readers[i].WaitFor;
      Readers[i].Free;
    end;
    
    for i := 0 to WriterCount - 1 do
    begin
      Writers[i].WaitFor;
      Writers[i].Free;
    end;
    
    // 统计结果
    TotalReads := 0;
    TotalWrites := 0;
    for i := 0 to ReaderCount - 1 do
      TotalReads := TotalReads + Readers[i].ReadsPerformed;
    for i := 0 to WriterCount - 1 do
      TotalWrites := TotalWrites + Writers[i].WritesPerformed;
    
    WriteLn;
    WriteLn('=== 统计结果 ===');
    WriteLn('总读取次数：', TotalReads);
    WriteLn('总写入次数：', TotalWrites);
    WriteLn('最终数据值：', SharedData);
    
  finally
    Lock.Free;
  end;
end;

begin
  WriteLn('fafafa.core 事件同步原语 - 读写锁示例');
  WriteLn('==========================================');
  WriteLn;
  
  Randomize;
  
  try
    RunReaderWriterDemo;
    WriteLn;
    WriteLn('演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生错误：', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
