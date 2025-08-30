program test_windows_cpuid;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Windows;

// 使用 Windows API 获取 CPU 信息
procedure TestWindowsCPUID;
var
  si: SYSTEM_INFO;
  pfi: DWORD;
begin
  WriteLn('=== Windows API CPU 信息测试 ===');
  
  try
    // 获取系统信息
    GetSystemInfo(si);
    WriteLn('处理器架构: ', si.wProcessorArchitecture);
    WriteLn('处理器数量: ', si.dwNumberOfProcessors);
    WriteLn('处理器类型: ', si.dwProcessorType);
    WriteLn('处理器级别: ', si.wProcessorLevel);
    WriteLn('处理器版本: ', si.wProcessorRevision);
    
    // 检查处理器特性
    if IsProcessorFeaturePresent(PF_MMX_INSTRUCTIONS_AVAILABLE) then
      WriteLn('MMX: 支持')
    else
      WriteLn('MMX: 不支持');
      
    if IsProcessorFeaturePresent(PF_XMMI_INSTRUCTIONS_AVAILABLE) then
      WriteLn('SSE: 支持')
    else
      WriteLn('SSE: 不支持');
      
    if IsProcessorFeaturePresent(PF_XMMI64_INSTRUCTIONS_AVAILABLE) then
      WriteLn('SSE2: 支持')
    else
      WriteLn('SSE2: 不支持');
      
    if IsProcessorFeaturePresent(PF_SSE3_INSTRUCTIONS_AVAILABLE) then
      WriteLn('SSE3: 支持')
    else
      WriteLn('SSE3: 不支持');
      
    // 检查 AVX
    pfi := 17; // PF_AVX_INSTRUCTIONS_AVAILABLE
    if IsProcessorFeaturePresent(pfi) then
      WriteLn('AVX: 支持')
    else
      WriteLn('AVX: 不支持');
      
    // 检查 AVX2
    pfi := 40; // PF_AVX2_INSTRUCTIONS_AVAILABLE  
    if IsProcessorFeaturePresent(pfi) then
      WriteLn('AVX2: 支持')
    else
      WriteLn('AVX2: 不支持');
      
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
end;

// 尝试最简单的 CPUID
procedure SimplestCPUID;
var
  result: array[0..3] of DWord;
begin
  WriteLn('');
  WriteLn('=== 最简单的 CPUID 测试 ===');
  
  try
    // 初始化结果
    result[0] := $DEADBEEF;
    result[1] := $DEADBEEF;
    result[2] := $DEADBEEF;
    result[3] := $DEADBEEF;
    
    WriteLn('初始值:');
    WriteLn('  [0]: $', IntToHex(result[0], 8));
    WriteLn('  [1]: $', IntToHex(result[1], 8));
    WriteLn('  [2]: $', IntToHex(result[2], 8));
    WriteLn('  [3]: $', IntToHex(result[3], 8));
    
    // 尝试执行 CPUID
    WriteLn('执行 CPUID...');
    
    // 这里我们先不执行真实的 CPUID，只是测试框架
    WriteLn('CPUID 测试框架正常');
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
end;

begin
  try
    TestWindowsCPUID;
    SimplestCPUID;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('按任意键退出...');
  ReadLn;
end.
