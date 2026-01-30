program comprehensive_hashmap_tests;

{$MODE OBJFPC}{$H+}
{$apptype console}

program comprehensive_hashmap_tests;

uses
  SysUtils, fpcunit, testregistry, consoletestrunner,
  Test_Contracts_IMap;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  RunRegisteredTests;
end.

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, DateUtils, Math,
  fafafa.core.lockfree;

type
  TTestResult = record
    TestName: string;
    Passed: Boolean;
    ErrorMessage: string;
    ElapsedMs: QWord;
  end;

var
  GTestResults: array of TTestResult;
  GTestCount: Integer = 0;

procedure AddTestResult(const ATestName: string; APassed: Boolean;
  const AErrorMessage: string = ''; AElapsedMs: QWord = 0);
begin
  SetLength(GTestResults, Length(GTestResults) + 1);
  with GTestResults[High(GTestResults)] do
  begin
    TestName := ATestName;
    Passed := APassed;
    ErrorMessage := AErrorMessage;
    ElapsedMs := AElapsedMs;
  end;
  Inc(GTestCount);
end;

procedure Assert(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('断言失败: ' + AMessage);
end;

// 测试1：基本插入和查找
procedure TestBasicPutGet;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LValue: string;
  LStartTime: QWord;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(1024);
  try
    // 测试插入
    Assert(LHashMap.Put(1, 'One'), '应该能插入键值对');
    Assert(LHashMap.Put(2, 'Two'), '应该能插入第二个键值对');
    Assert(LHashMap.Put(100, 'Hundred'), '应该能插入大键值');

    // 测试查找
    Assert(LHashMap.Get(1, LValue) and (LValue = 'One'), '应该能找到键1');
    Assert(LHashMap.Get(2, LValue) and (LValue = 'Two'), '应该能找到键2');
    Assert(LHashMap.Get(100, LValue) and (LValue = 'Hundred'), '应该能找到键100');

    // 测试不存在的键
    Assert(not LHashMap.Get(999, LValue), '不应该找到不存在的键');

    // 测试大小
    Assert(LHashMap.GetSize = 3, '大小应该是3');
    Assert(not LHashMap.IsEmpty, '不应该为空');

    AddTestResult('基本插入和查找', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('基本插入和查找', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试2：覆盖和更新
procedure TestOverwriteAndUpdate;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LValue: string;
  LStartTime: QWord;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(1024);
  try
    // 插入初始值
    Assert(LHashMap.Put(1, 'Original'), '应该能插入原始值');

    // 覆盖值
    Assert(LHashMap.Put(1, 'Updated'), '应该能覆盖值');
    Assert(LHashMap.Get(1, LValue) and (LValue = 'Updated'), '应该获取到更新后的值');

    // 大小不应该变化
    Assert(LHashMap.GetSize = 1, '覆盖后大小应该还是1');

    // 测试PutIfAbsent
    Assert(not LHashMap.PutIfAbsent(1, 'ShouldNotInsert'), 'PutIfAbsent应该失败');
    Assert(LHashMap.Get(1, LValue) and (LValue = 'Updated'), '值不应该被PutIfAbsent改变');

    Assert(LHashMap.PutIfAbsent(2, 'NewValue'), 'PutIfAbsent应该成功插入新键');
    Assert(LHashMap.Get(2, LValue) and (LValue = 'NewValue'), '应该能获取PutIfAbsent插入的值');

    AddTestResult('覆盖和更新', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('覆盖和更新', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试3：删除操作
procedure TestRemoveOperations;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LValue: string;
  LStartTime: QWord;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(1024);
  try
    // 插入测试数据
    LHashMap.Put(1, 'One');
    LHashMap.Put(2, 'Two');
    LHashMap.Put(3, 'Three');

    // 测试删除存在的键
    Assert(LHashMap.Remove(2), '应该能删除存在的键');
    Assert(not LHashMap.Get(2, LValue), '删除后不应该能找到键');
    Assert(LHashMap.GetSize = 2, '删除后大小应该减少');

    // 测试删除不存在的键
    Assert(not LHashMap.Remove(999), '不应该能删除不存在的键');
    Assert(LHashMap.GetSize = 2, '删除不存在键后大小不变');

    // 测试GetAndRemove
    Assert(LHashMap.GetAndRemove(1, LValue) and (LValue = 'One'), 'GetAndRemove应该返回值并删除');
    Assert(not LHashMap.Get(1, LValue), 'GetAndRemove后键应该被删除');
    Assert(LHashMap.GetSize = 1, 'GetAndRemove后大小应该减少');

    // 测试ContainsKey
    Assert(LHashMap.ContainsKey(3), '应该包含剩余的键');
    Assert(not LHashMap.ContainsKey(1), '不应该包含已删除的键');

    AddTestResult('删除操作', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('删除操作', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试4：大容量测试
procedure TestLargeCapacity;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, Integer>;
  LValue: Integer;
  I: Integer;
  LStartTime: QWord;
  LInsertCount, LGetCount, LRemoveCount: Integer;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, Integer>.Create(8192);
  try
    LInsertCount := 0;
    LGetCount := 0;
    LRemoveCount := 0;

    // 插入10000个键值对
    for I := 1 to 10000 do
    begin
      if LHashMap.Put(I, I * 2) then
        Inc(LInsertCount);
    end;

    Assert(LInsertCount = 10000, Format('应该插入10000个，实际插入%d个', [LInsertCount]));
    Assert(LHashMap.GetSize = 10000, Format('大小应该是10000，实际是%d', [LHashMap.GetSize]));

    // 验证所有键值对
    for I := 1 to 10000 do
    begin
      if LHashMap.Get(I, LValue) and (LValue = I * 2) then
        Inc(LGetCount);
    end;

    Assert(LGetCount = 10000, Format('应该找到10000个，实际找到%d个', [LGetCount]));

    // 删除一半
    for I := 1 to 5000 do
    begin
      if LHashMap.Remove(I) then
        Inc(LRemoveCount);
    end;

    Assert(LRemoveCount = 5000, Format('应该删除5000个，实际删除%d个', [LRemoveCount]));
    Assert(LHashMap.GetSize = 5000, Format('删除后大小应该是5000，实际是%d', [LHashMap.GetSize]));

    // 验证剩余的键值对
    LGetCount := 0;
    for I := 5001 to 10000 do
    begin
      if LHashMap.Get(I, LValue) and (LValue = I * 2) then
        Inc(LGetCount);
    end;

    Assert(LGetCount = 5000, Format('应该找到剩余5000个，实际找到%d个', [LGetCount]));

    AddTestResult('大容量测试', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('大容量测试', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试5：哈希冲突测试
procedure TestHashCollisions;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LValue: string;
  I: Integer;
  LStartTime: QWord;
  LKeys: array of Integer;
  LCollisionRate: Single;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(64); // 小容量强制冲突
  try
    // 生成会产生冲突的键
    SetLength(LKeys, 200);
    for I := 0 to 199 do
      LKeys[I] := I * 64; // 这些键在小容量下会产生冲突

    // 插入所有键
    for I := 0 to 199 do
    begin
      Assert(LHashMap.Put(LKeys[I], 'Value' + IntToStr(LKeys[I])),
             Format('应该能插入键%d', [LKeys[I]]));
    end;

    Assert(LHashMap.GetSize = 200, Format('应该有200个元素，实际有%d个', [LHashMap.GetSize]));

    // 验证所有键都能正确找到
    for I := 0 to 199 do
    begin
      Assert(LHashMap.Get(LKeys[I], LValue) and (LValue = 'Value' + IntToStr(LKeys[I])),
             Format('应该能找到键%d对应的值', [LKeys[I]]));
    end;

    // 测试冲突率
    LCollisionRate := LHashMap.GetCollisionRate;
    WriteLn(Format('冲突率: %.2f%%', [LCollisionRate * 100]));

    AddTestResult('哈希冲突测试', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('哈希冲突测试', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试6：边界条件测试
procedure TestBoundaryConditions;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LValue: string;
  LStartTime: QWord;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(4); // 最小容量
  try
    // 测试空哈希表
    Assert(LHashMap.IsEmpty, '新哈希表应该为空');
    Assert(LHashMap.GetSize = 0, '新哈希表大小应该为0');
    Assert(not LHashMap.Get(1, LValue), '空哈希表不应该找到任何键');
    Assert(not LHashMap.Remove(1), '空哈希表不应该能删除任何键');
    Assert(not LHashMap.ContainsKey(1), '空哈希表不应该包含任何键');

    // 测试极值键
    Assert(LHashMap.Put(0, 'Zero'), '应该能插入键0');
    Assert(LHashMap.Put(-1, 'MinusOne'), '应该能插入负键');
    Assert(LHashMap.Put(MaxInt, 'MaxInt'), '应该能插入最大整数键');
    Assert(LHashMap.Put(Low(Integer), 'MinInt'), '应该能插入最小整数键');

    // 验证极值键
    Assert(LHashMap.Get(0, LValue) and (LValue = 'Zero'), '应该能找到键0');
    Assert(LHashMap.Get(-1, LValue) and (LValue = 'MinusOne'), '应该能找到负键');
    Assert(LHashMap.Get(MaxInt, LValue) and (LValue = 'MaxInt'), '应该能找到最大整数键');
    Assert(LHashMap.Get(Low(Integer), LValue) and (LValue = 'MinInt'), '应该能找到最小整数键');

    AddTestResult('边界条件测试', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('边界条件测试', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试7：性能基准测试
procedure TestPerformanceBenchmark;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, Integer>;
  LValue: Integer;
  I: Integer;
  LStartTime, LInsertTime, LGetTime, LRemoveTime: QWord;
  LOperationCount: Integer;
  LTotalTime: QWord;
begin
  LOperationCount := 50000; // 减少操作数以便快速测试
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, Integer>.Create(65536);
  try
    WriteLn(Format('开始性能基准测试 (%d 次操作)...', [LOperationCount]));

    // 插入性能测试
    LStartTime := GetTickCount64;
    for I := 1 to LOperationCount do
      LHashMap.Put(I, I * 2);
    LInsertTime := GetTickCount64 - LStartTime;

    // 查找性能测试
    LStartTime := GetTickCount64;
    for I := 1 to LOperationCount do
      LHashMap.Get(I, LValue);
    LGetTime := GetTickCount64 - LStartTime;

    // 删除性能测试
    LStartTime := GetTickCount64;
    for I := 1 to LOperationCount do
      LHashMap.Remove(I);
    LRemoveTime := GetTickCount64 - LStartTime;

    WriteLn(Format('插入 %d 次耗时: %d ms (%.0f ops/sec)',
      [LOperationCount, LInsertTime, LOperationCount * 1000.0 / Max(LInsertTime, 1)]));
    WriteLn(Format('查找 %d 次耗时: %d ms (%.0f ops/sec)',
      [LOperationCount, LGetTime, LOperationCount * 1000.0 / Max(LGetTime, 1)]));
    WriteLn(Format('删除 %d 次耗时: %d ms (%.0f ops/sec)',
      [LOperationCount, LRemoveTime, LOperationCount * 1000.0 / Max(LRemoveTime, 1)]));

    LTotalTime := LInsertTime + LGetTime + LRemoveTime;
    WriteLn(Format('总计 %d 次操作耗时: %d ms (%.0f ops/sec)',
      [LOperationCount * 3, LTotalTime, LOperationCount * 3 * 1000.0 / Max(LTotalTime, 1)]));

    AddTestResult('性能基准测试', True, '', LTotalTime);
  except
    on E: Exception do
      AddTestResult('性能基准测试', False, E.Message, 0);
  end;
  LHashMap.Free;
end;

// 测试8：内存使用测试
procedure TestMemoryUsage;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LStartTime: QWord;
  LMemoryUsage: LongInt;
  LLoadFactor: Single;
  I: Integer;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(1024);
  try
    // 插入数据
    for I := 1 to 500 do
      LHashMap.Put(I, 'Value' + IntToStr(I));

    LMemoryUsage := LHashMap.GetMemoryUsage;
    LLoadFactor := LHashMap.GetLoadFactor;

    WriteLn(Format('内存使用: %d 字节', [LMemoryUsage]));
    WriteLn(Format('负载因子: %.2f', [LLoadFactor]));
    WriteLn(Format('容量: %d', [LHashMap.GetCapacity]));
    WriteLn(Format('大小: %d', [LHashMap.GetSize]));

    Assert(LMemoryUsage > 0, '内存使用应该大于0');
    Assert(LLoadFactor >= 0, '负载因子应该非负');
    Assert(LLoadFactor <= 1.0, '负载因子应该不超过1.0');

    AddTestResult('内存使用测试', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('内存使用测试', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

// 测试9：数据类型测试
procedure TestDifferentDataTypes;
var
  LIntStringMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LStringIntMap: specialize TAdvancedLockFreeHashMap<string, Integer>;
  LIntIntMap: specialize TAdvancedLockFreeHashMap<Integer, Integer>;
  LStartTime: QWord;
  LStringValue: string;
  LIntValue: Integer;
begin
  LStartTime := GetTickCount64;
  try
    // 测试Integer -> String
    LIntStringMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(1024);
    LIntStringMap.Put(1, 'One');
    LIntStringMap.Put(2, 'Two');
    Assert(LIntStringMap.Get(1, LStringValue) and (LStringValue = 'One'), 'Integer->String映射应该工作');

    // 测试String -> Integer
    LStringIntMap := specialize TAdvancedLockFreeHashMap<string, Integer>.Create(1024);
    LStringIntMap.Put('One', 1);
    LStringIntMap.Put('Two', 2);
    Assert(LStringIntMap.Get('One', LIntValue) and (LIntValue = 1), 'String->Integer映射应该工作');

    // 测试Integer -> Integer
    LIntIntMap := specialize TAdvancedLockFreeHashMap<Integer, Integer>.Create(1024);
    LIntIntMap.Put(1, 100);
    LIntIntMap.Put(2, 200);
    Assert(LIntIntMap.Get(1, LIntValue) and (LIntValue = 100), 'Integer->Integer映射应该工作');

    AddTestResult('数据类型测试', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('数据类型测试', False, E.Message, GetTickCount64 - LStartTime);
  end;

  LIntStringMap.Free;
  LStringIntMap.Free;
  LIntIntMap.Free;
end;

// 测试10：压力测试
procedure TestStressTest;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, Integer>;
  LStartTime: QWord;
  I, LValue: Integer;
  LSuccessCount: Integer;
begin
  LStartTime := GetTickCount64;
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, Integer>.Create(1024);
  try
    LSuccessCount := 0;

    // 混合操作压力测试
    for I := 1 to 10000 do
    begin
      case I mod 4 of
        0: if LHashMap.Put(I, I * 2) then Inc(LSuccessCount);
        1: if LHashMap.Get(I div 2, LValue) then Inc(LSuccessCount);
        2: if LHashMap.Remove(I div 3) then Inc(LSuccessCount);
        3: if LHashMap.ContainsKey(I div 4) then Inc(LSuccessCount);
      end;
    end;

    WriteLn(Format('压力测试：10000次混合操作，成功%d次', [LSuccessCount]));
    Assert(LSuccessCount > 0, '压力测试应该有成功的操作');

    AddTestResult('压力测试', True, '', GetTickCount64 - LStartTime);
  except
    on E: Exception do
      AddTestResult('压力测试', False, E.Message, GetTickCount64 - LStartTime);
  end;
  LHashMap.Free;
end;

procedure PrintTestResults;
var
  I: Integer;
  LPassedCount, LFailedCount: Integer;
  LTotalTime: QWord;
  LStatus: string;
begin
  WriteLn;
  WriteLn('=== 测试结果汇总 ===');
  WriteLn('测试名称                     状态    耗时(ms)  错误信息');
  WriteLn('--------------------------------------------------------');

  LPassedCount := 0;
  LFailedCount := 0;
  LTotalTime := 0;

  for I := 0 to High(GTestResults) do
  begin
    with GTestResults[I] do
    begin
      if Passed then
        LStatus := '✅ 通过'
      else
        LStatus := '❌ 失败';

      WriteLn(Format('%-25s %s %8d  %s', [
        TestName,
        LStatus,
        ElapsedMs,
        ErrorMessage
      ]));

      if Passed then
        Inc(LPassedCount)
      else
        Inc(LFailedCount);

      Inc(LTotalTime, ElapsedMs);
    end;
  end;

  WriteLn('--------------------------------------------------------');
  WriteLn(Format('总计: %d 个测试，%d 个通过，%d 个失败', [
    GTestCount, LPassedCount, LFailedCount
  ]));
  WriteLn(Format('总耗时: %d ms', [LTotalTime]));
  WriteLn;

  if LFailedCount = 0 then
  begin
    WriteLn('🎉 所有测试通过！TAdvancedLockFreeHashMap 质量优秀！');
  end
  else
  begin
    WriteLn('⚠️  有测试失败，需要进一步改进。');
  end;
end;

begin
  WriteLn('TAdvancedLockFreeHashMap 综合测试套件');
  WriteLn('=====================================');
  WriteLn('全面测试高级无锁哈希表的功能、性能和稳定性');
  WriteLn;

  try
    // 执行所有测试
    TestBasicPutGet;
    TestOverwriteAndUpdate;
    TestRemoveOperations;
    TestLargeCapacity;
    TestHashCollisions;
    TestBoundaryConditions;
    TestPerformanceBenchmark;
    TestMemoryUsage;
    TestDifferentDataTypes;
    TestStressTest;

    // 打印结果
    PrintTestResults;

    WriteLn('测试完成！按回车键退出...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
