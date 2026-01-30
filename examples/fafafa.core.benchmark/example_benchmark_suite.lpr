program example_benchmark_suite;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 示例套件主程序 - 演示如何运行多个示例

procedure ShowMenu;
begin
  WriteLn('========================================');
  WriteLn('fafafa.core.benchmark 示例套件');
  WriteLn('========================================');
  WriteLn;
  WriteLn('可用的示例:');
  WriteLn('  1. 算法性能对比 (example_algorithm_comparison.exe)');
  WriteLn('  2. 内存性能测试 (example_memory_performance.exe)');
  WriteLn('  3. 字符串处理性能 (example_string_performance.exe)');
  WriteLn('  4. 数据结构性能 (example_data_structures.exe)');
  WriteLn('  5. 配置选项验证 (example_configuration_options.exe)');
  WriteLn('  6. 基础功能演示 (example_benchmark.exe)');
  WriteLn('  0. 退出');
  WriteLn;
  Write('请选择要运行的示例 (0-6): ');
end;

function RunExample(const aExampleName: string): Boolean;
var
  LExePath: string;
  LExitCode: Integer;
begin
  Result := False;
  LExePath := '..\..\bin\' + aExampleName + '.exe';
  
  WriteLn;
  WriteLn('正在运行: ', aExampleName);
  WriteLn('路径: ', LExePath);
  WriteLn('----------------------------------------');
  
  if not FileExists(LExePath) then
  begin
    WriteLn('错误: 找不到示例程序 ', LExePath);
    WriteLn('请先编译相应的示例程序。');
    Exit;
  end;
  
  try
    // 运行示例程序
    LExitCode := ExecuteProcess(LExePath, '');
    
    WriteLn('----------------------------------------');
    if LExitCode = 0 then
    begin
      WriteLn('示例运行成功完成');
      Result := True;
    end
    else
    begin
      WriteLn('示例运行失败，退出代码: ', LExitCode);
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('运行示例时出错: ', E.Message);
    end;
  end;
end;

procedure RunAllExamples;
var
  LExamples: array[0..5] of string = (
    'example_algorithm_comparison',
    'example_memory_performance', 
    'example_string_performance',
    'example_data_structures',
    'example_configuration_options',
    'example_benchmark'
  );
  LI: Integer;
  LSuccessCount: Integer;
begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('运行所有示例程序');
  WriteLn('========================================');
  
  LSuccessCount := 0;
  
  for LI := 0 to High(LExamples) do
  begin
    WriteLn;
    WriteLn('运行示例 ', LI + 1, '/', Length(LExamples), ': ', LExamples[LI]);
    
    if RunExample(LExamples[LI]) then
      Inc(LSuccessCount);
    
    WriteLn;
    WriteLn('按回车键继续下一个示例...');
    ReadLn;
  end;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('所有示例运行完成');
  WriteLn('成功: ', LSuccessCount, '/', Length(LExamples));
  WriteLn('========================================');
end;

procedure ShowExampleInfo;
begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('示例程序说明');
  WriteLn('========================================');
  WriteLn;
  WriteLn('1. 算法性能对比:');
  WriteLn('   - 比较不同排序算法的性能');
  WriteLn('   - 演示相对性能分析');
  WriteLn('   - 展示吞吐量计算');
  WriteLn;
  WriteLn('2. 内存性能测试:');
  WriteLn('   - 测试内存分配策略');
  WriteLn('   - 内存复制和填充性能');
  WriteLn('   - 字符串和动态数组操作');
  WriteLn;
  WriteLn('3. 字符串处理性能:');
  WriteLn('   - 字符串连接方法对比');
  WriteLn('   - 查找、替换、分割性能');
  WriteLn('   - 编码转换性能');
  WriteLn;
  WriteLn('4. 数据结构性能:');
  WriteLn('   - 不同列表类型对比');
  WriteLn('   - 数组访问性能');
  WriteLn('   - 哈希表操作性能');
  WriteLn;
  WriteLn('5. 配置选项验证:');
  WriteLn('   - 预热和测量迭代次数影响');
  WriteLn('   - 持续时间设置效果');
  WriteLn('   - 不同测量模式对比');
  WriteLn;
  WriteLn('6. 基础功能演示:');
  WriteLn('   - 新旧 API 使用方法');
  WriteLn('   - 报告器功能展示');
  WriteLn('   - 全局注册机制');
end;

procedure CreateBuildScript;
var
  LScript: TextFile;
begin
  WriteLn;
  WriteLn('创建构建脚本...');
  
  AssignFile(LScript, 'build_all_examples.bat');
  Rewrite(LScript);
  
  WriteLn(LScript, '@echo off');
  WriteLn(LScript, 'echo 构建所有示例程序...');
  WriteLn(LScript, 'echo.');
  WriteLn(LScript, '');
  WriteLn(LScript, 'set "FPC_OPTIONS=-Fu../../src -FE../../bin -O3"');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译算法性能对比示例...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_algorithm_comparison.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译内存性能测试示例...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_memory_performance.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译字符串处理性能示例...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_string_performance.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译数据结构性能示例...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_data_structures.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译配置选项验证示例...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_configuration_options.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译基础功能演示示例...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_benchmark.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo 编译示例套件...');
  WriteLn(LScript, 'fpc %FPC_OPTIONS% example_benchmark_suite.lpr');
  WriteLn(LScript, '');
  WriteLn(LScript, 'echo.');
  WriteLn(LScript, 'echo 所有示例程序编译完成！');
  WriteLn(LScript, 'pause');
  
  CloseFile(LScript);
  
  WriteLn('构建脚本已创建: build_all_examples.bat');
end;

var
  LChoice: string;
  LChoiceNum: Integer;

begin
  WriteLn('fafafa.core.benchmark 示例套件启动中...');
  WriteLn;
  
  repeat
    ShowMenu;
    ReadLn(LChoice);
    
    if TryStrToInt(LChoice, LChoiceNum) then
    begin
      case LChoiceNum of
        0: begin
          WriteLn('退出示例套件。');
          Break;
        end;
        1: RunExample('example_algorithm_comparison');
        2: RunExample('example_memory_performance');
        3: RunExample('example_string_performance');
        4: RunExample('example_data_structures');
        5: RunExample('example_configuration_options');
        6: RunExample('example_benchmark');
        99: RunAllExamples; // 隐藏选项
        98: ShowExampleInfo; // 隐藏选项
        97: CreateBuildScript; // 隐藏选项
        else
          WriteLn('无效选择，请输入 0-6 之间的数字。');
      end;
    end
    else
    begin
      // 检查特殊命令
      if LowerCase(LChoice) = 'all' then
        RunAllExamples
      else if LowerCase(LChoice) = 'info' then
        ShowExampleInfo
      else if LowerCase(LChoice) = 'build' then
        CreateBuildScript
      else
        WriteLn('无效输入，请输入数字 0-6 或特殊命令 (all, info, build)。');
    end;
    
    WriteLn;
    
  until False;
  
  WriteLn;
  WriteLn('感谢使用 fafafa.core.benchmark 示例套件！');
end.
