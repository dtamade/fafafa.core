program example_quick_benchmark;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 快手接口演示 - 超级简洁的一行式基准测试

// 测试函数1：字符串操作
procedure StringConcat(aState: IBenchmarkState);
var
  LStr: string;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LStr := '';
    for LI := 1 to 100 do
      LStr := LStr + 'x';
    aState.SetItemsProcessed(100);
  end;
end;

// 测试函数2：数学计算
procedure MathCalc(aState: IBenchmarkState);
var
  LSum: Double;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 1000 do
      LSum := LSum + Sqrt(LI);
    aState.SetItemsProcessed(1000);
  end;
end;

// 测试函数3：数组操作
procedure ArrayOps(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    for LI := 0 to 999 do
      LArray[LI] := Random(1000);
    aState.ResumeTiming;
    
    LSum := 0;
    for LI := 0 to 999 do
      LSum := LSum + LArray[LI];
    
    aState.SetItemsProcessed(1000);
  end;
end;

// 测试函数4：内存分配
procedure MemAlloc(aState: IBenchmarkState);
var
  LPtr: Pointer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    for LI := 1 to 100 do
    begin
      GetMem(LPtr, 1024);
      FreeMem(LPtr);
    end;
    aState.SetItemsProcessed(100);
  end;
end;

begin
  WriteLn('🚀 快手基准测试演示');
  WriteLn('==================');
  WriteLn;
  
  Randomize;
  
  WriteLn('这就是您想要的超级简洁接口！');
  WriteLn;
  
  // ✨ 这就是您要的一行式基准测试！
  WriteLn('1. 最简单的用法 - 一行搞定：');
  WriteLn;
  
  quick_benchmark([
    benchmark('字符串连接', @StringConcat),
    benchmark('数学计算', @MathCalc),
    benchmark('数组操作', @ArrayOps),
    benchmark('内存分配', @MemAlloc)
  ]);
  
  WriteLn;
  WriteLn('2. 带标题的版本：');
  WriteLn;
  
  quick_benchmark('算法性能对比', [
    benchmark('字符串连接', @StringConcat),
    benchmark('数学计算', @MathCalc)
  ]);
  
  WriteLn;
  WriteLn('3. 自定义配置：');
  WriteLn;
  
  var LQuickConfig := CreateDefaultBenchmarkConfig;
  LQuickConfig.WarmupIterations := 1;
  LQuickConfig.MeasureIterations := 3;
  
  quick_benchmark('快速测试', [
    benchmark('字符串连接', @StringConcat, LQuickConfig),
    benchmark('数学计算', @MathCalc, LQuickConfig)
  ]);
  
  WriteLn;
  WriteLn('4. 只获取结果，不显示：');
  WriteLn;
  
  var LResults := benchmarks([
    benchmark('测试A', @StringConcat),
    benchmark('测试B', @MathCalc)
  ]);
  
  WriteLn('获得 ', Length(LResults), ' 个结果');
  for var LI := 0 to High(LResults) do
    WriteLn('  ', LResults[LI].Name, ': ', 
            Format('%.2f μs/op', [LResults[LI].GetTimePerIteration(buMicroSeconds)]));
  
  WriteLn;
  WriteLn('5. 带标题获取结果：');
  WriteLn;
  
  LResults := benchmarks('我的测试套件', [
    benchmark('算法A', @StringConcat),
    benchmark('算法B', @MathCalc),
    benchmark('算法C', @ArrayOps)
  ]);
  
  WriteLn;
  WriteLn('6. 超级简洁的对比测试：');
  WriteLn;
  
  // 这种写法是不是超级简洁？
  quick_benchmark('排序算法对比', [
    benchmark('冒泡排序', @ArrayOps),  // 这里可以换成真正的排序算法
    benchmark('快速排序', @MathCalc)   // 这里可以换成真正的排序算法
  ]);
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('✨ 快手接口特点：');
  WriteLn('  • 一行代码搞定多个测试');
  WriteLn('  • 自动显示结果和对比');
  WriteLn('  • 支持自定义配置');
  WriteLn('  • 可以只获取结果不显示');
  WriteLn('  • 语法简洁，易于使用');
  WriteLn;
  WriteLn('🎯 使用场景：');
  WriteLn('  • 快速性能测试');
  WriteLn('  • 算法对比');
  WriteLn('  • 代码优化验证');
  WriteLn('  • 学习和实验');
  WriteLn;
  WriteLn('📝 语法说明：');
  WriteLn('  benchmark(名称, 函数)           - 创建测试定义');
  WriteLn('  benchmark(名称, 函数, 配置)     - 带配置的测试');
  WriteLn('  benchmarks([测试数组])          - 运行并返回结果');
  WriteLn('  quick_benchmark([测试数组])     - 运行并显示结果');
  WriteLn;
  WriteLn('这就是您想要的超级简洁接口！');
  WriteLn('现在基准测试变得像写 Hello World 一样简单！');
  WriteLn;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
