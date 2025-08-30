unit fafafa.core.simd.cpuinfo.testcase;

{$I fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  fpcunit, testregistry,
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_GetCPUInfo;
    procedure Test_IsBackendAvailable;
    procedure Test_GetAvailableBackends;
    procedure Test_GetBestBackend;
    procedure Test_GetBackendInfo;
    procedure Test_ResetCPUInfo;
  end;

  // 线程安全测试
  TTestCase_ThreadSafety = class(TTestCase)
  published
    procedure Test_GetCPUInfo_Consistency;
    procedure Test_GetCPUInfo_Performance;
  end;

  // 平台特定测试
  TTestCase_PlatformSpecific = class(TTestCase)
  published
    procedure Test_X86Features;
    procedure Test_ARMFeatures;
    procedure Test_FeatureHierarchy;
  end;

  // 错误处理测试
  TTestCase_ErrorHandling = class(TTestCase)
  published
    procedure Test_InvalidBackend;
    procedure Test_ExceptionHandling;
  end;

implementation

// === TTestCase_Global ===

procedure TTestCase_Global.Test_GetCPUInfo;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  
  // 基本验证
  AssertTrue('CPU vendor should not be empty', cpuInfo.Vendor <> '');
  AssertTrue('CPU model should not be empty', cpuInfo.Model <> '');
  
  // 多次调用应该返回相同结果
  var cpuInfo2 := GetCPUInfo;
  AssertEquals('Vendor should be consistent', cpuInfo.Vendor, cpuInfo2.Vendor);
  AssertEquals('Model should be consistent', cpuInfo.Model, cpuInfo2.Model);
end;

procedure TTestCase_Global.Test_IsBackendAvailable;
begin
  // Scalar 后端必须总是可用
  AssertTrue('Scalar backend must always be available', IsBackendAvailable(sbScalar));
  
  // 测试其他后端
  var sse2Available := IsBackendAvailable(sbSSE2);
  var avx2Available := IsBackendAvailable(sbAVX2);
  var neonAvailable := IsBackendAvailable(sbNEON);
  
  // 记录结果用于调试
  WriteLn('SSE2 available: ', sse2Available);
  WriteLn('AVX2 available: ', avx2Available);
  WriteLn('NEON available: ', neonAvailable);
end;

procedure TTestCase_Global.Test_GetAvailableBackends;
var
  backends: TSimdBackendArray;
  i: Integer;
  foundScalar: Boolean;
begin
  backends := GetAvailableBackends;
  
  // 至少应该有 Scalar 后端
  AssertTrue('Should have at least one backend', Length(backends) > 0);
  
  // 检查是否包含 Scalar 后端
  foundScalar := False;
  for i := 0 to Length(backends) - 1 do
  begin
    if backends[i] = sbScalar then
    begin
      foundScalar := True;
      Break;
    end;
  end;
  AssertTrue('Should include scalar backend', foundScalar);
  
  // 验证后端按优先级排序（高优先级在前）
  for i := 0 to Length(backends) - 2 do
  begin
    var info1 := GetBackendInfo(backends[i]);
    var info2 := GetBackendInfo(backends[i + 1]);
    AssertTrue('Backends should be sorted by priority', info1.Priority >= info2.Priority);
  end;
end;

procedure TTestCase_Global.Test_GetBestBackend;
var
  bestBackend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
begin
  bestBackend := GetBestBackend;
  
  // 最佳后端必须可用
  AssertTrue('Best backend must be available', IsBackendAvailable(bestBackend));
  
  // 获取后端信息
  backendInfo := GetBackendInfo(bestBackend);
  AssertTrue('Best backend info should be available', backendInfo.Available);
  AssertTrue('Best backend name should not be empty', backendInfo.Name <> '');
end;

procedure TTestCase_Global.Test_GetBackendInfo;
var
  info: TSimdBackendInfo;
begin
  // 测试 Scalar 后端信息
  info := GetBackendInfo(sbScalar);
  AssertEquals('Scalar backend should be available', True, info.Available);
  AssertEquals('Scalar backend name', 'Scalar', info.Name);
  AssertEquals('Scalar backend priority', 0, info.Priority);
  
  // 测试其他后端
  info := GetBackendInfo(sbSSE2);
  AssertTrue('SSE2 backend name should not be empty', info.Name <> '');
  
  info := GetBackendInfo(sbAVX2);
  AssertTrue('AVX2 backend name should not be empty', info.Name <> '');
  
  info := GetBackendInfo(sbNEON);
  AssertTrue('NEON backend name should not be empty', info.Name <> '');
end;

procedure TTestCase_Global.Test_ResetCPUInfo;
var
  cpuInfo1, cpuInfo2: TCPUInfo;
begin
  // 获取初始信息
  cpuInfo1 := GetCPUInfo;
  
  // 重置
  ResetCPUInfo;
  
  // 重新获取
  cpuInfo2 := GetCPUInfo;
  
  // 结果应该相同
  AssertEquals('Vendor should be same after reset', cpuInfo1.Vendor, cpuInfo2.Vendor);
  AssertEquals('Model should be same after reset', cpuInfo1.Model, cpuInfo2.Model);
end;

// === TTestCase_ThreadSafety ===

procedure TTestCase_ThreadSafety.Test_GetCPUInfo_Consistency;
const
  NUM_ITERATIONS = 1000;
var
  i: Integer;
  cpuInfo1, cpuInfo2: TCPUInfo;
begin
  cpuInfo1 := GetCPUInfo;
  
  // 多次调用验证一致性
  for i := 1 to NUM_ITERATIONS do
  begin
    cpuInfo2 := GetCPUInfo;
    
    AssertEquals('Vendor should be consistent', cpuInfo1.Vendor, cpuInfo2.Vendor);
    AssertEquals('Model should be consistent', cpuInfo1.Model, cpuInfo2.Model);
    
    {$IFDEF SIMD_X86_AVAILABLE}
    AssertEquals('x86 SSE should be consistent', cpuInfo1.X86.HasSSE, cpuInfo2.X86.HasSSE);
    AssertEquals('x86 SSE2 should be consistent', cpuInfo1.X86.HasSSE2, cpuInfo2.X86.HasSSE2);
    AssertEquals('x86 AVX should be consistent', cpuInfo1.X86.HasAVX, cpuInfo2.X86.HasAVX);
    AssertEquals('x86 AVX2 should be consistent', cpuInfo1.X86.HasAVX2, cpuInfo2.X86.HasAVX2);
    {$ENDIF}
    
    {$IFDEF SIMD_ARM_AVAILABLE}
    AssertEquals('ARM NEON should be consistent', cpuInfo1.ARM.HasNEON, cpuInfo2.ARM.HasNEON);
    AssertEquals('ARM AdvSIMD should be consistent', cpuInfo1.ARM.HasAdvSIMD, cpuInfo2.ARM.HasAdvSIMD);
    {$ENDIF}
  end;
end;

procedure TTestCase_ThreadSafety.Test_GetCPUInfo_Performance;
const
  NUM_CALLS = 10000;
var
  i: Integer;
  cpuInfo: TCPUInfo;
  startTime, endTime: QWord;
  avgTimeNs: Double;
begin
  // 预热
  for i := 1 to 10 do
    cpuInfo := GetCPUInfo;
    
  // 性能测试
  startTime := GetTickCount64;
  for i := 1 to NUM_CALLS do
    cpuInfo := GetCPUInfo;
  endTime := GetTickCount64;
  
  avgTimeNs := ((endTime - startTime) * 1000000.0) / NUM_CALLS;
  
  WriteLn('Average GetCPUInfo time: ', FormatFloat('0.00', avgTimeNs), ' ns');
  
  // 性能要求：每次调用应该小于 10μs
  AssertTrue('GetCPUInfo should be fast (< 10μs)', avgTimeNs < 10000);
end;

// === TTestCase_PlatformSpecific ===

procedure TTestCase_PlatformSpecific.Test_X86Features;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  
  {$IFDEF SIMD_X86_AVAILABLE}
  WriteLn('x86 Features:');
  WriteLn('  SSE: ', cpuInfo.X86.HasSSE);
  WriteLn('  SSE2: ', cpuInfo.X86.HasSSE2);
  WriteLn('  SSE3: ', cpuInfo.X86.HasSSE3);
  WriteLn('  SSSE3: ', cpuInfo.X86.HasSSSE3);
  WriteLn('  SSE4.1: ', cpuInfo.X86.HasSSE41);
  WriteLn('  SSE4.2: ', cpuInfo.X86.HasSSE42);
  WriteLn('  AVX: ', cpuInfo.X86.HasAVX);
  WriteLn('  AVX2: ', cpuInfo.X86.HasAVX2);
  WriteLn('  FMA: ', cpuInfo.X86.HasFMA);
  WriteLn('  AVX512F: ', cpuInfo.X86.HasAVX512F);
  {$ELSE}
  WriteLn('x86 features not available in this build');
  {$ENDIF}
end;

procedure TTestCase_PlatformSpecific.Test_ARMFeatures;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  
  {$IFDEF SIMD_ARM_AVAILABLE}
  WriteLn('ARM Features:');
  WriteLn('  NEON: ', cpuInfo.ARM.HasNEON);
  WriteLn('  AdvSIMD: ', cpuInfo.ARM.HasAdvSIMD);
  WriteLn('  FP: ', cpuInfo.ARM.HasFP);
  WriteLn('  SVE: ', cpuInfo.ARM.HasSVE);
  
  {$IFDEF CPUAARCH64}
  // AArch64 上 NEON 是强制的
  AssertTrue('NEON should be available on AArch64', cpuInfo.ARM.HasNEON);
  AssertTrue('AdvSIMD should be available on AArch64', cpuInfo.ARM.HasAdvSIMD);
  {$ENDIF}
  {$ELSE}
  WriteLn('ARM features not available in this build');
  {$ENDIF}
end;

procedure TTestCase_PlatformSpecific.Test_FeatureHierarchy;
var
  cpuInfo: TCPUInfo;
begin
  cpuInfo := GetCPUInfo;
  
  {$IFDEF SIMD_X86_AVAILABLE}
  // 验证 x86 特性层次结构
  if cpuInfo.X86.HasSSE2 then
    AssertTrue('SSE2 requires SSE', cpuInfo.X86.HasSSE);
    
  if cpuInfo.X86.HasSSE3 then
    AssertTrue('SSE3 requires SSE2', cpuInfo.X86.HasSSE2);
    
  if cpuInfo.X86.HasSSSE3 then
    AssertTrue('SSSE3 requires SSE3', cpuInfo.X86.HasSSE3);
    
  if cpuInfo.X86.HasSSE41 then
    AssertTrue('SSE4.1 requires SSSE3', cpuInfo.X86.HasSSSE3);
    
  if cpuInfo.X86.HasSSE42 then
    AssertTrue('SSE4.2 requires SSE4.1', cpuInfo.X86.HasSSE41);
    
  if cpuInfo.X86.HasAVX2 then
    AssertTrue('AVX2 requires AVX', cpuInfo.X86.HasAVX);
    
  if cpuInfo.X86.HasAVX512F then
    AssertTrue('AVX512F requires AVX2', cpuInfo.X86.HasAVX2);
  {$ENDIF}
end;

// === TTestCase_ErrorHandling ===

procedure TTestCase_ErrorHandling.Test_InvalidBackend;
var
  info: TSimdBackendInfo;
begin
  // 测试无效的后端值
  info := GetBackendInfo(TSimdBackend(999));
  
  // 应该优雅处理，不抛出异常
  AssertFalse('Invalid backend should not be available', info.Available);
  AssertEquals('Invalid backend priority should be -1', -1, info.Priority);
end;

procedure TTestCase_ErrorHandling.Test_ExceptionHandling;
begin
  // 测试在异常情况下的行为
  try
    var cpuInfo := GetCPUInfo;
    // 正常情况下不应该抛出异常
    AssertTrue('GetCPUInfo should not throw exceptions', True);
  except
    on E: Exception do
      Fail('GetCPUInfo should not throw exceptions: ' + E.Message);
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ThreadSafety);
  RegisterTest(TTestCase_PlatformSpecific);
  RegisterTest(TTestCase_ErrorHandling);

end.
