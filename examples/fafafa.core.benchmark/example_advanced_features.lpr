program example_advanced_features;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 高级功能演示：性能分析、模板管理、跨平台测试

// 优秀性能的算法
procedure ExcellentAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 10 do
      LSum := LSum + LI;
    aState.SetItemsProcessed(10);
  end;
end;

// 良好性能的算法
procedure GoodAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 100 do
      LSum := LSum + LI;
    aState.SetItemsProcessed(100);
  end;
end;

// 一般性能的算法
procedure FairAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI, LJ: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 100 do
      for LJ := 1 to 10 do
        LSum := LSum + LI * LJ;
    aState.SetItemsProcessed(1000);
  end;
end;

// 较差性能的算法
procedure PoorAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI, LJ, LK: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 50 do
      for LJ := 1 to 50 do
        for LK := 1 to 10 do
          LSum := LSum + LI * LJ * LK;
    aState.SetItemsProcessed(25000);
  end;
end;

// 内存操作算法
procedure MemoryAlgorithm(aState: IBenchmarkState);
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

procedure DemonstratePerformanceAnalysis;
begin
  WriteLn('=== 智能性能分析演示 ===');
  WriteLn;
  
  WriteLn('运行不同性能等级的算法并进行智能分析...');
  WriteLn;
  
  // 使用性能分析功能
  analyzed_benchmark('智能性能分析', [
    benchmark('优秀算法', @ExcellentAlgorithm),
    benchmark('良好算法', @GoodAlgorithm),
    benchmark('一般算法', @FairAlgorithm),
    benchmark('较差算法', @PoorAlgorithm)
  ]);
end;

procedure DemonstrateTemplateManagement;
var
  LTemplateManager: IBenchmarkTemplateManager;
  LTemplates: TBenchmarkTemplateArray;
  LI: Integer;
begin
  WriteLn('=== 模板管理演示 ===');
  WriteLn;
  
  LTemplateManager := CreateTemplateManager;
  
  // 显示所有可用模板
  LTemplates := LTemplateManager.GetAllTemplates;
  WriteLn('可用的基准测试模板:');
  for LI := 0 to High(LTemplates) do
  begin
    WriteLn('  ', LI + 1, '. ', LTemplates[LI].Name);
    WriteLn('     描述: ', LTemplates[LI].Description);
    WriteLn('     分类: ', LTemplates[LI].Category);
    WriteLn('     预期范围: ', Format('%.2f - %.2f μs', 
            [LTemplates[LI].ExpectedRange.MinTime / 1000, 
             LTemplates[LI].ExpectedRange.MaxTime / 1000]));
    WriteLn;
  end;
  
  // 使用算法模板
  WriteLn('使用算法模板进行测试:');
  template_benchmark('Algorithm', [
    benchmark('测试算法1', @GoodAlgorithm),
    benchmark('测试算法2', @FairAlgorithm)
  ]);
  
  WriteLn;
  
  // 使用内存模板
  WriteLn('使用内存模板进行测试:');
  template_benchmark('Memory', [
    benchmark('内存操作', @MemoryAlgorithm)
  ]);
end;

procedure DemonstrateCrossPlatformTesting;
var
  LPlatform: TPlatformInfo;
begin
  WriteLn('=== 跨平台测试演示 ===');
  WriteLn;
  
  LPlatform := GetCurrentPlatformInfo;
  
  WriteLn('当前平台信息:');
  WriteLn('  操作系统: ', LPlatform.OS);
  WriteLn('  架构: ', LPlatform.Architecture);
  WriteLn('  编译器版本: ', LPlatform.CompilerVersion);
  WriteLn('  CPU 核心数: ', LPlatform.CPUCores);
  WriteLn('  内存大小: ', LPlatform.MemorySize, ' MB');
  WriteLn;
  
  WriteLn('运行跨平台基准测试...');
  cross_platform_benchmark([
    benchmark('跨平台算法1', @GoodAlgorithm),
    benchmark('跨平台算法2', @FairAlgorithm),
    benchmark('跨平台内存操作', @MemoryAlgorithm)
  ], 'cross_platform_results.txt');
end;

procedure DemonstrateAdvancedReporting;
var
  LResults: TBenchmarkResultArray;
begin
  WriteLn('=== 高级报告生成演示 ===');
  WriteLn;
  
  WriteLn('运行测试并生成详细分析报告...');
  
  // 运行测试
  LResults := benchmarks('高级报告测试', [
    benchmark('算法A', @ExcellentAlgorithm),
    benchmark('算法B', @GoodAlgorithm),
    benchmark('算法C', @FairAlgorithm),
    benchmark('算法D', @PoorAlgorithm),
    benchmark('内存操作', @MemoryAlgorithm)
  ]);
  
  // 生成详细的性能分析报告
  GeneratePerformanceReport(LResults, 'detailed_performance_report.md');
  
  WriteLn('详细性能分析报告已生成: detailed_performance_report.md');
  WriteLn;
end;

procedure DemonstrateIntegratedWorkflow;
begin
  WriteLn('=== 集成工作流演示 ===');
  WriteLn;
  
  WriteLn('演示完整的性能测试工作流程...');
  WriteLn;
  
  // 1. 使用模板进行初始测试
  WriteLn('步骤 1: 使用模板进行初始测试');
  template_benchmark('Algorithm', [
    benchmark('核心算法', @GoodAlgorithm)
  ]);
  
  WriteLn;
  
  // 2. 进行性能分析
  WriteLn('步骤 2: 进行详细性能分析');
  analyzed_benchmark([
    benchmark('核心算法', @GoodAlgorithm),
    benchmark('优化后算法', @ExcellentAlgorithm)
  ]);
  
  WriteLn;
  
  // 3. 跨平台验证
  WriteLn('步骤 3: 跨平台性能验证');
  cross_platform_benchmark([
    benchmark('最终算法', @ExcellentAlgorithm)
  ], 'final_cross_platform_results.txt');
  
  WriteLn;
  
  // 4. 生成最终报告
  WriteLn('步骤 4: 生成最终报告');
  var LFinalResults := benchmarks([
    benchmark('最终版本', @ExcellentAlgorithm)
  ]);
  
  GeneratePerformanceReport(LFinalResults, 'final_performance_report.md');
  WriteLn('最终报告已生成: final_performance_report.md');
end;

procedure ShowAdvancedFeatures;
begin
  WriteLn('🚀 高级功能总览');
  WriteLn('================');
  WriteLn;
  WriteLn('✅ 已实现的高级功能:');
  WriteLn('  • 智能性能分析 - 自动分析性能等级和瓶颈');
  WriteLn('  • 优化建议系统 - 基于性能分析提供优化建议');
  WriteLn('  • 模板管理系统 - 预定义的测试模板和配置');
  WriteLn('  • 跨平台测试 - 记录平台信息的测试结果');
  WriteLn('  • 高级报告生成 - Markdown 格式的详细分析报告');
  WriteLn('  • 集成工作流 - 完整的性能测试流程');
  WriteLn;
  WriteLn('🎯 功能特点:');
  WriteLn('  • 自动化分析 - 无需手工分析性能数据');
  WriteLn('  • 智能建议 - 基于性能特征提供优化方向');
  WriteLn('  • 标准化模板 - 不同场景的最佳实践配置');
  WriteLn('  • 平台感知 - 考虑平台差异的性能测试');
  WriteLn('  • 专业报告 - 适合技术文档和团队分享');
  WriteLn;
  WriteLn('📝 API 接口:');
  WriteLn('  analyzed_benchmark()         - 智能分析测试');
  WriteLn('  template_benchmark()         - 模板化测试');
  WriteLn('  cross_platform_benchmark()   - 跨平台测试');
  WriteLn('  GeneratePerformanceReport()  - 生成分析报告');
  WriteLn('  CreateBenchmarkAnalyzer()    - 创建分析器');
  WriteLn('  CreateTemplateManager()      - 创建模板管理器');
  WriteLn;
end;

begin
  WriteLn('========================================');
  WriteLn('高级功能演示');
  WriteLn('========================================');
  WriteLn;
  
  try
    ShowAdvancedFeatures;
    DemonstratePerformanceAnalysis;
    DemonstrateTemplateManagement;
    DemonstrateCrossPlatformTesting;
    DemonstrateAdvancedReporting;
    DemonstrateIntegratedWorkflow;
    
    WriteLn('========================================');
    WriteLn('高级功能演示完成！');
    WriteLn('========================================');
    WriteLn;
    WriteLn('生成的文件:');
    WriteLn('  • cross_platform_results.txt - 跨平台测试结果');
    WriteLn('  • detailed_performance_report.md - 详细性能分析报告');
    WriteLn('  • final_cross_platform_results.txt - 最终跨平台结果');
    WriteLn('  • final_performance_report.md - 最终性能报告');
    WriteLn;
    WriteLn('这些高级功能让基准测试框架具备了');
    WriteLn('专业级的性能分析和管理能力！');
    
  except
    on E: Exception do
    begin
      WriteLn('演示运行出错: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
