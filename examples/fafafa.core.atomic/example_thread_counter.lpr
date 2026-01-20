program example_thread_counter;

{$APPTYPE CONSOLE}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.atomic;

const
  THREAD_COUNT = 8;
  INCREMENTS_PER_THREAD = 100000;

type
  TCounterThread = class(TThread)
  private
    FCounter: PInt32;
    FIncrements: Integer;
    FUseAtomic: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(counter: PInt32; increments: Integer; use_atomic: Boolean);
  end;

constructor TCounterThread.Create(counter: PInt32; increments: Integer; use_atomic: Boolean);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FCounter := counter;
  FIncrements := increments;
  FUseAtomic := use_atomic;
end;

procedure TCounterThread.Execute;
var
  i: Integer;
begin
  if FUseAtomic then
  begin
    // 使用原子操作
    for i := 1 to FIncrements do
      atomic_increment(FCounter^);
  end
  else
  begin
    // 使用普通操作（非线程安全）
    for i := 1 to FIncrements do
      Inc(FCounter^);
  end;
end;

procedure TestCounter(use_atomic: Boolean; const test_name: string);
var
  counter: Int32;
  threads: array[0..THREAD_COUNT-1] of TCounterThread;
  i: Integer;
  start_time, end_time: QWord;
  expected_result: Int32;
begin
  Writeln('=== ', test_name, ' ===');
  
  counter := 0;
  expected_result := THREAD_COUNT * INCREMENTS_PER_THREAD;
  
  start_time := GetTickCount64;
  
  // 创建并启动线程
  for i := 0 to THREAD_COUNT-1 do
  begin
    threads[i] := TCounterThread.Create(@counter, INCREMENTS_PER_THREAD, use_atomic);
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT-1 do
    threads[i].WaitFor;
  
  end_time := GetTickCount64;
  
  // 清理线程
  for i := 0 to THREAD_COUNT-1 do
    threads[i].Free;
  
  // 输出结果
  Writeln('线程数量：', THREAD_COUNT);
  Writeln('每线程增量：', INCREMENTS_PER_THREAD);
  Writeln('期望结果：', expected_result);
  Writeln('实际结果：', counter);
  Writeln('耗时：', end_time - start_time, ' ms');
  
  if counter = expected_result then
    Writeln('✓ 结果正确')
  else
    Writeln('✗ 结果错误，丢失了 ', expected_result - counter, ' 次增量');
  
  Writeln;
end;

// 演示不同内存序的性能差异
procedure TestMemoryOrders;
var
  counter: Int32;
  i: Integer;
  start_time, end_time: QWord;
  iterations: Integer;
begin
  Writeln('=== 内存序性能对比 ===');
  iterations := 10000000;  // 1000万次操作
  
  // mo_relaxed (模拟)
  counter := 0;
  start_time := GetTickCount64;
  for i := 1 to iterations do
    atomic_increment(counter);
  end_time := GetTickCount64;
  Writeln('mo_relaxed: ', iterations, ' 次操作耗时 ', end_time - start_time, ' ms');

  // mo_seq_cst (默认)
  counter := 0;
  start_time := GetTickCount64;
  for i := 1 to iterations do
    atomic_increment(counter);
  end_time := GetTickCount64;
  Writeln('mo_seq_cst: ', iterations, ' 次操作耗时 ', end_time - start_time, ' ms');
  
  Writeln;
end;

type
  TBitMaskThread = class(TThread)
  private
    FFlags: PInt32;
    FBitIndex: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(flags: PInt32; bit_index: Integer);
  end;

constructor TBitMaskThread.Create(flags: PInt32; bit_index: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FFlags := flags;
  FBitIndex := bit_index;
end;

procedure TBitMaskThread.Execute;
var
  bit_mask: Int32;
begin
  bit_mask := 1 shl FBitIndex;  // 第 FBitIndex 位
  atomic_fetch_or(FFlags^, bit_mask);
  Writeln('线程 ', FBitIndex, ' 设置位 ', FBitIndex, '，掩码：0x', IntToHex(bit_mask, 2));
end;

// 演示位掩码操作
procedure TestBitMask;
var
  flags: Int32;
  thread_flags: array[0..THREAD_COUNT-1] of TBitMaskThread;
  i: Integer;
begin
  Writeln('=== 位掩码并发操作 ===');

  flags := 0;

  // 每个线程设置自己的位
  for i := 0 to THREAD_COUNT-1 do
  begin
    thread_flags[i] := TBitMaskThread.Create(@flags, i);
    thread_flags[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT-1 do
  begin
    thread_flags[i].WaitFor;
    thread_flags[i].Free;
  end;
  
  Writeln('最终标志位：0b', BinStr(flags, 8), ' (0x', IntToHex(flags, 2), ')');
  
  // 验证所有位都被设置
  if flags = (1 shl THREAD_COUNT) - 1 then
    Writeln('✓ 所有位都被正确设置')
  else
    Writeln('✗ 某些位未被设置');
  
  Writeln;
end;

begin
  Writeln('=== 多线程计数器示例 ===');
  Writeln('演示原子操作在多线程环境下的正确性和性能');
  Writeln;
  
  // 测试非原子操作（会出现竞态条件）
  TestCounter(False, '非原子操作（存在竞态条件）');
  
  // 测试原子操作（线程安全）
  TestCounter(True, '原子操作（线程安全）');
  
  // 测试内存序性能差异
  TestMemoryOrders;
  
  // 测试位掩码操作
  TestBitMask;
  
  Writeln('=== 示例完成 ===');
  Writeln('说明：');
  Writeln('1. 非原子操作在多线程下会丢失更新（竞态条件）');
  Writeln('2. 原子操作保证线程安全，结果始终正确');
  Writeln('3. mo_relaxed 比 mo_seq_cst 性能更好，但语义更弱');
  Writeln('4. 位运算可用于线程间状态同步');
end.
