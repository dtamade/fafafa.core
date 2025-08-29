program simple_leak_test;

{$mode objfpc}{$H+}

var
  p: Pointer;
begin
  WriteLn('=== 简单内存泄漏测试 ===');
  WriteLn('分配 100 字节内存但不释放...');
  
  // 故意泄漏内存
  GetMem(p, 100);
  // 不调用 FreeMem(p, 100);
  
  WriteLn('程序结束，检查 HeapTrc 输出...');
end.
