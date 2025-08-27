program EnhancedDiagnosticsDemo;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem;

var
  LTracker: TTrackingAllocator;
  LPtr1, LPtr2, LPtr3: Pointer;
  LRecentAllocations: array[0..4] of SizeUInt;
  I: Integer;

procedure SimulateWorkload;
begin
  WriteLn('模拟工作负载...');
  
  // 创建跟踪分配器
  LTracker := TTrackingAllocator.Create;
  try
    // 模拟不同大小的分配
    LPtr1 := LTracker.GetMem(512);
    TMemoryDiagnostics.RecordAllocation(512);
    Sleep(100);
    
    LPtr2 := LTracker.GetMem(1024);
    TMemoryDiagnostics.RecordAllocation(1024);
    Sleep(50);
    
    LPtr3 := LTracker.GetMem(256);
    TMemoryDiagnostics.RecordAllocation(256);
    Sleep(75);
    
    // 释放一些内存
    LTracker.FreeMem(LPtr1);
    Sleep(25);
    
    // 再分配一些
    LPtr1 := LTracker.GetMem(2048);
    TMemoryDiagnostics.RecordAllocation(2048);
    Sleep(100);
    
    // 清理
    LTracker.FreeMem(LPtr1);
    LTracker.FreeMem(LPtr2);
    LTracker.FreeMem(LPtr3);
  finally
    LTracker.Free;
  end;
end;

begin
  WriteLn('=== 增强内存诊断系统演示 ===');
  WriteLn;

  // 初始化诊断系统
  InitializeMemoryDiagnostics;
  WriteLn('1. 诊断系统已初始化');
  WriteLn('   运行时间: ', TMemoryDiagnostics.GetUptime:0:3, ' 秒');
  WriteLn;

  // 等待一小段时间以显示运行时间
  Sleep(500);
  
  WriteLn('2. 等待 0.5 秒后:');
  WriteLn('   运行时间: ', TMemoryDiagnostics.GetUptime:0:3, ' 秒');
  WriteLn;

  // 模拟工作负载
  WriteLn('3. 执行模拟工作负载:');
  SimulateWorkload;
  WriteLn('   工作负载完成');
  WriteLn;

  // 显示基本统计
  WriteLn('4. 基本统计信息:');
  WriteLn('   运行时间: ', TMemoryDiagnostics.GetUptime:0:3, ' 秒');
  WriteLn('   分配速率: ', TMemoryDiagnostics.GetAllocationRate:0:2, ' 分配/秒');
  WriteLn('   平均分配大小: ', TMemoryDiagnostics.GetAverageAllocationSize:0:2, ' 字节');
  WriteLn;

  // 显示最近的分配历史
  WriteLn('5. 最近的分配历史:');

  // 清零数组
  for I := 0 to High(LRecentAllocations) do
    LRecentAllocations[I] := 0;

  TMemoryDiagnostics.GetRecentAllocations(5, LRecentAllocations);

  WriteLn('   最近 5 次分配:');
  for I := 0 to High(LRecentAllocations) do
  begin
    if LRecentAllocations[I] > 0 then
      WriteLn('   ', I + 1, '. ', LRecentAllocations[I], ' 字节')
    else
      Break;
  end;
  WriteLn;

  // 显示详细诊断信息
  WriteLn('6. 详细诊断信息:');
  TMemoryDiagnostics.PrintDetailedDiagnostics;
  WriteLn;

  // 再次模拟工作负载以显示累积效果
  WriteLn('7. 再次执行工作负载:');
  SimulateWorkload;
  WriteLn;

  // 最终详细诊断
  WriteLn('8. 最终详细诊断:');
  TMemoryDiagnostics.PrintDetailedDiagnostics;
  WriteLn;

  // 重置统计
  WriteLn('9. 重置统计信息:');
  TMemoryDiagnostics.ResetGlobalStats;
  WriteLn('   统计已重置');
  TMemoryDiagnostics.PrintDiagnostics;
  WriteLn;

  // 清理诊断系统
  FinalizeMemoryDiagnostics;
  WriteLn('10. 诊断系统已清理');
  WriteLn;

  WriteLn('=== 增强诊断系统演示完成 ===');
end.
