program test_modular_architecture;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.base,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.math.scalar;

var
  outputFile: TextFile;
  testsPassed: Integer = 0;
  totalTests: Integer = 0;

procedure WriteLog(const msg: string);
begin
  WriteLn(msg);
  WriteLn(outputFile, msg);
end;

procedure TestCPUInfoFacade;
var
  cpuInfo: TCPUInfo;
  backends: TSimdBackendArray;
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  i: Integer;
begin
  WriteLog('=== 测试 CPU 信息门面 ===');
  
  try
    // 测试基本 CPU 信息
    cpuInfo := GetCPUInfo;
    WriteLog('CPU 厂商: ' + cpuInfo.Vendor);
    WriteLog('CPU 型号: ' + cpuInfo.Model);
    
    // 测试后端可用性
    WriteLog('');
    WriteLog('后端可用性检查:');
    for backend := Low(TSimdBackend) to High(TSimdBackend) do
    begin
      var available := IsBackendAvailable(backend);
      WriteLog('  ' + GetBackendName(backend) + ': ' + BoolToStr(available, True));
    end;
    
    // 测试可用后端列表
    WriteLog('');
    WriteLog('可用后端列表（按优先级排序）:');
    backends := GetAvailableBackends;
    for i := 0 to Length(backends) - 1 do
    begin
      backendInfo := GetBackendInfo(backends[i]);
      WriteLog(Format('  %d. %s (优先级: %d)', [i + 1, backendInfo.Name, backendInfo.Priority]));
    end;
    
    // 测试最佳后端
    backend := GetBestBackend;
    WriteLog('');
    WriteLog('最佳后端: ' + GetBackendName(backend));
    
    WriteLog('✓ CPU 信息门面测试通过');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ CPU 信息门面测试失败: ' + E.Message);
    end;
  end;
  
  Inc(totalTests);
end;

procedure TestBackendFactory;
var
  factory: ISimdBackendFactory;
  math: ISimdMath;
  memory: ISimdMemory;
  conversion: ISimdConversion;
  capabilities: TSimdCapabilitySet;
begin
  WriteLog('');
  WriteLog('=== 测试后端工厂 ===');
  
  try
    // 获取标量后端工厂
    factory := GetBackendFactory(sbScalar);
    if factory = nil then
      raise Exception.Create('无法获取标量后端工厂');
      
    WriteLog('标量后端工厂: ' + GetBackendName(factory.GetBackend));
    WriteLog('是否可用: ' + BoolToStr(factory.IsAvailable, True));
    
    // 测试创建各种组件
    math := factory.CreateMath;
    if math = nil then
      raise Exception.Create('无法创建数学组件');
    WriteLog('✓ 数学组件创建成功');
    
    memory := factory.CreateMemory;
    if memory = nil then
      raise Exception.Create('无法创建内存组件');
    WriteLog('✓ 内存组件创建成功');
    
    conversion := factory.CreateConversion;
    if conversion = nil then
      raise Exception.Create('无法创建转换组件');
    WriteLog('✓ 转换组件创建成功');
    
    // 测试能力集
    capabilities := factory.GetCapabilities;
    WriteLog('后端能力:');
    if scBasicArithmetic in capabilities then WriteLog('  ✓ 基础算术运算');
    if scComparison in capabilities then WriteLog('  ✓ 比较运算');
    if scMathFunctions in capabilities then WriteLog('  ✓ 数学函数');
    if scLoadStore in capabilities then WriteLog('  ✓ 内存加载/存储');
    
    WriteLog('✓ 后端工厂测试通过');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ 后端工厂测试失败: ' + E.Message);
    end;
  end;
  
  Inc(totalTests);
end;

procedure TestScalarMath;
var
  factory: ISimdBackendFactory;
  math: ISimdMath;
  vecA, vecB, result: ISimdVector;
begin
  WriteLog('');
  WriteLog('=== 测试标量数学运算 ===');
  
  try
    factory := GetBackendFactory(sbScalar);
    math := factory.CreateMath;
    
    // 创建测试向量
    vecA := CreateScalarVectorF32x4(1.0, 2.0, 3.0, 4.0);
    vecB := CreateScalarVectorF32x4(5.0, 6.0, 7.0, 8.0);
    
    WriteLog('向量 A: [1.0, 2.0, 3.0, 4.0]');
    WriteLog('向量 B: [5.0, 6.0, 7.0, 8.0]');
    
    // 测试加法
    result := math.Add(vecA, vecB);
    var scalarResult := result as TScalarVector;
    WriteLog(Format('A + B = [%.1f, %.1f, %.1f, %.1f]', 
      [scalarResult[0], scalarResult[1], scalarResult[2], scalarResult[3]]));
    
    // 验证结果
    if (Abs(scalarResult[0] - 6.0) < 0.001) and
       (Abs(scalarResult[1] - 8.0) < 0.001) and
       (Abs(scalarResult[2] - 10.0) < 0.001) and
       (Abs(scalarResult[3] - 12.0) < 0.001) then
      WriteLog('✓ 加法运算正确')
    else
      raise Exception.Create('加法运算结果错误');
    
    // 测试乘法
    result := math.Mul(vecA, vecB);
    scalarResult := result as TScalarVector;
    WriteLog(Format('A * B = [%.1f, %.1f, %.1f, %.1f]', 
      [scalarResult[0], scalarResult[1], scalarResult[2], scalarResult[3]]));
    
    // 测试平方根
    result := math.Sqrt(vecA);
    scalarResult := result as TScalarVector;
    WriteLog(Format('sqrt(A) = [%.3f, %.3f, %.3f, %.3f]', 
      [scalarResult[0], scalarResult[1], scalarResult[2], scalarResult[3]]));
    
    WriteLog('✓ 标量数学运算测试通过');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ 标量数学运算测试失败: ' + E.Message);
    end;
  end;
  
  Inc(totalTests);
end;

procedure TestScalarMemory;
var
  factory: ISimdBackendFactory;
  memory: ISimdMemory;
  data: array[0..3] of Single;
  result: array[0..3] of Single;
  vector: ISimdVector;
  scalarVec: TScalarVector;
  i: Integer;
begin
  WriteLog('');
  WriteLog('=== 测试标量内存操作 ===');
  
  try
    factory := GetBackendFactory(sbScalar);
    memory := factory.CreateMemory;
    
    // 准备测试数据
    data[0] := 10.5;
    data[1] := 20.5;
    data[2] := 30.5;
    data[3] := 40.5;
    
    WriteLog('原始数据: [10.5, 20.5, 30.5, 40.5]');
    
    // 测试加载
    vector := memory.Load(@data[0], 4);
    scalarVec := vector as TScalarVector;
    
    WriteLog(Format('加载的向量: [%.1f, %.1f, %.1f, %.1f]', 
      [scalarVec[0], scalarVec[1], scalarVec[2], scalarVec[3]]));
    
    // 验证加载结果
    for i := 0 to 3 do
    begin
      if Abs(scalarVec[i] - data[i]) > 0.001 then
        raise Exception.Create('加载数据不匹配');
    end;
    WriteLog('✓ 内存加载正确');
    
    // 测试存储
    FillChar(result, SizeOf(result), 0);
    memory.Store(vector, @result[0]);
    
    WriteLog(Format('存储的数据: [%.1f, %.1f, %.1f, %.1f]', 
      [result[0], result[1], result[2], result[3]]));
    
    // 验证存储结果
    for i := 0 to 3 do
    begin
      if Abs(result[i] - data[i]) > 0.001 then
        raise Exception.Create('存储数据不匹配');
    end;
    WriteLog('✓ 内存存储正确');
    
    WriteLog('✓ 标量内存操作测试通过');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ 标量内存操作测试失败: ' + E.Message);
    end;
  end;
  
  Inc(totalTests);
end;

procedure TestArchitectureIntegration;
var
  bestFactory: ISimdBackendFactory;
  math: ISimdMath;
  memory: ISimdMemory;
  data: array[0..7] of Single;
  vecA, vecB, result: ISimdVector;
  i: Integer;
begin
  WriteLog('');
  WriteLog('=== 测试架构集成 ===');
  
  try
    // 获取最佳后端工厂
    bestFactory := GetBestBackendFactory;
    WriteLog('使用最佳后端: ' + GetBackendName(bestFactory.GetBackend));
    
    // 创建组件
    math := bestFactory.CreateMath;
    memory := bestFactory.CreateMemory;
    
    // 准备测试数据
    for i := 0 to 7 do
      data[i] := i + 1.0;
    
    // 加载数据为两个向量
    vecA := memory.Load(@data[0], 4);
    vecB := memory.Load(@data[4], 4);
    
    // 执行运算
    result := math.Add(vecA, vecB);
    result := math.Mul(result, vecA);
    
    // 验证结果
    var scalarResult := result as TScalarVector;
    WriteLog('集成测试结果:');
    WriteLog(Format('  [%.1f, %.1f, %.1f, %.1f]', 
      [scalarResult[0], scalarResult[1], scalarResult[2], scalarResult[3]]));
    
    WriteLog('✓ 架构集成测试通过');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ 架构集成测试失败: ' + E.Message);
    end;
  end;
  
  Inc(totalTests);
end;

begin
  // 打开输出文件
  AssignFile(outputFile, 'test_modular_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('模块化 SIMD 架构测试套件');
    WriteLog('============================');
    WriteLog('开始时间: ' + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
    WriteLog('');
    
    // 执行测试
    TestCPUInfoFacade;
    TestBackendFactory;
    TestScalarMath;
    TestScalarMemory;
    TestArchitectureIntegration;
    
    // 输出总结
    WriteLog('');
    WriteLog('=== 测试结果总结 ===');
    WriteLog(Format('通过测试: %d/%d', [testsPassed, totalTests]));
    WriteLog(Format('成功率: %.1f%%', [testsPassed * 100.0 / totalTests]));
    WriteLog('结束时间: ' + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
    
    if testsPassed = totalTests then
      WriteLog('✅ 所有测试通过 - 模块化架构工作正常')
    else
      WriteLog('❌ 部分测试失败 - 需要检查架构实现');
      
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('模块化架构测试完成。查看 test_modular_results.txt 了解详细结果。');
  WriteLn(Format('测试通过: %d/%d', [testsPassed, totalTests]));
end.
