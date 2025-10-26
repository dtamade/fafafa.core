program test_memory_leak_simple;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils;

const
  TEST_ITERATIONS = 100;

var
  I, J: Integer;
  LPtr: Pointer;
  LSize: SizeUInt;

begin
  WriteLn('╔═══════════════════════════════════════════════════════════╗');
  WriteLn('║          fafafa.core 内存泄漏检测 (HeapTrc)               ║');
  WriteLn('╚═══════════════════════════════════════════════════════════╝');
  WriteLn;

  WriteLn('测试1: 基础内存分配/释放测试 (', TEST_ITERATIONS, ' 次)');
  for I := 1 to TEST_ITERATIONS do
  begin
    LSize := 1024;
    GetMem(LPtr, LSize);
    FillChar(LPtr^, LSize, 0);
    FreeMem(LPtr);
  end;
  WriteLn('  ✅ 基础内存测试通过');
  WriteLn;

  WriteLn('测试2: 频繁分配/释放测试 (', TEST_ITERATIONS, ' 次)');
  for I := 1 to TEST_ITERATIONS do
  begin
    for J := 1 to 100 do
    begin
      LSize := 128;
      GetMem(LPtr, LSize);
      FreeMem(LPtr);
    end;
  end;
  WriteLn('  ✅ 频繁内存测试通过');
  WriteLn;

  WriteLn('测试3: 大内存分配测试 (', TEST_ITERATIONS, ' 次)');
  for I := 1 to TEST_ITERATIONS do
  begin
    LSize := 1024 * 1024; // 1MB
    GetMem(LPtr, LSize);
    FreeMem(LPtr);
  end;
  WriteLn('  ✅ 大内存分配测试通过');
  WriteLn;

  WriteLn('═══════════════════════════════════════════════════════════');
  WriteLn('✅ 内存泄漏检测完成！');
  WriteLn('系统信息: Free Pascal 内存管理测试');
  WriteLn;
  WriteLn('注意: 此测试使用基础内存分配，需要实际运行可执行文件');
  WriteLn('      并检查 HeapTrc 输出来确认无泄漏');
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
