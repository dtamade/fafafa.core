program example_basic_operations;

{$APPTYPE CONSOLE}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.atomic;

var
  counter: Int32;
  flag: Int32;
  ptr: Pointer;
  old_val, new_val: Int32;

begin
  Writeln('=== fafafa.core.atomic 基础操作示例 ===');
  Writeln;

  // 1. 原子加载与存储
  Writeln('1. 原子加载与存储');
  counter := 0;
  atomic_store(counter, 42);
  Writeln('存储值 42，读取结果：', atomic_load(counter));
  Writeln;

  // 2. 原子交换
  Writeln('2. 原子交换');
  old_val := atomic_exchange(counter, 100);
  Writeln('交换前值：', old_val, '，交换后值：', atomic_load(counter));
  Writeln;

  // 3. 原子增减
  Writeln('3. 原子增减');
  counter := 10;
  Writeln('初始值：', counter);
  Writeln('increment 后：', atomic_increment(counter));
  Writeln('decrement 后：', atomic_decrement(counter));
  Writeln('fetch_add(5) 返回旧值：', atomic_fetch_add(counter, 5), '，新值：', atomic_load(counter));
  Writeln;

  // 4. 比较交换（CAS）
  Writeln('4. 比较交换（CAS）');
  counter := 15;
  old_val := 15;  // 期望值
  if atomic_compare_exchange_strong(counter, old_val, 20) then
    Writeln('CAS 成功：15 -> 20')
  else
    Writeln('CAS 失败，当前值：', old_val);

  old_val := 99;  // 错误的期望值
  if atomic_compare_exchange_strong(counter, old_val, 30) then
    Writeln('CAS 成功')
  else
    Writeln('CAS 失败，期望 99 但实际是：', old_val);
  Writeln;

  // 5. 位运算
  Writeln('5. 位运算');
  counter := $FF00;  // 65280
  Writeln('初始值：0x', IntToHex(counter, 4));
  old_val := atomic_fetch_and(counter, $0F0F);
  Writeln('AND 0x0F0F，旧值：0x', IntToHex(old_val, 4), '，新值：0x', IntToHex(counter, 4));
  
  old_val := atomic_fetch_or(counter, $F000);
  Writeln('OR 0xF000，旧值：0x', IntToHex(old_val, 4), '，新值：0x', IntToHex(counter, 4));
  Writeln;

  // 6. 指针运算
  Writeln('6. 指针运算');
  ptr := Pointer(1000);
  Writeln('初始指针：', PtrUInt(ptr));
  ptr := atomic_fetch_add(ptr, 100);  // 返回旧值
  Writeln('fetch_add(100) 返回旧值：', PtrUInt(ptr));
  Writeln('当前指针值：', PtrUInt(atomic_load(ptr)));
  Writeln;

  // 7. 内存序示例
  Writeln('7. 内存序示例');
  flag := 0;
  atomic_store(flag, 1);  // 释放语义
  if atomic_load(flag) = 1 then  // 获取语义
    Writeln('使用 acquire/release 内存序读取到标志位');

  // relaxed 内存序（仅保证原子性）
  atomic_store(counter, 999);
  Writeln('relaxed 存储后读取：', atomic_load(counter));
  Writeln;

  Writeln('=== 示例完成 ===');
end.
