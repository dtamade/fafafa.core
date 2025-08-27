program debug_hashmap_test;


{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.lockfree;

// 调试小容量哈希冲突问题
procedure DebugSmallCapacityCollisions;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, string>;
  LValue: string;
  I: Integer;
  LInsertCount, LGetCount: Integer;
  LKey: Integer;
  LValueStr: string;
  LExpectedValue: string;
begin
  WriteLn('=== 调试小容量哈希冲突问题 ===');
  
  // 使用很小的容量强制冲突
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, string>.Create(64);
  try
    WriteLn('初始容量: ', LHashMap.GetCapacity);
    WriteLn('初始大小: ', LHashMap.GetSize);
    WriteLn;
    
    LInsertCount := 0;
    
    // 尝试插入20个键，这些键在小容量下会产生冲突
    WriteLn('开始插入键...');
    for I := 0 to 19 do
    begin
      LKey := I * 64; // 这些键会产生冲突
      LValueStr := 'Value' + IntToStr(LKey);
      
      Write(Format('插入键 %d... ', [LKey]));
      if LHashMap.Put(LKey, LValueStr) then
      begin
        WriteLn('成功');
        Inc(LInsertCount);
      end
      else
      begin
        WriteLn('失败');
      end;
      
      WriteLn(Format('  当前大小: %d, 容量: %d, 负载因子: %.2f', [
        LHashMap.GetSize, LHashMap.GetCapacity, LHashMap.GetLoadFactor
      ]));
    end;
    
    WriteLn;
    WriteLn(Format('插入完成：成功 %d 个，失败 %d 个', [LInsertCount, 20 - LInsertCount]));
    WriteLn(Format('最终大小: %d, 容量: %d', [LHashMap.GetSize, LHashMap.GetCapacity]));
    WriteLn;
    
    // 验证所有插入成功的键
    LGetCount := 0;
    WriteLn('开始验证键...');
    for I := 0 to 19 do
    begin
      LKey := I * 64;
      LExpectedValue := 'Value' + IntToStr(LKey);
      
      Write(Format('查找键 %d... ', [LKey]));
      if LHashMap.Get(LKey, LValue) then
      begin
        if LValue = LExpectedValue then
        begin
          WriteLn('成功');
          Inc(LGetCount);
        end
        else
        begin
          WriteLn(Format('值错误：期望 "%s"，实际 "%s"', [LExpectedValue, LValue]));
        end;
      end
      else
      begin
        WriteLn('未找到');
      end;
    end;
    
    WriteLn;
    WriteLn(Format('验证完成：找到 %d 个，丢失 %d 个', [LGetCount, LInsertCount - LGetCount]));
    
    if LGetCount = LInsertCount then
      WriteLn('✅ 所有插入的键都能正确找到')
    else
      WriteLn('❌ 有键丢失，存在问题');
    
  finally
    LHashMap.Free;
  end;
end;

// 调试大容量测试问题
procedure DebugLargeCapacityTest;
var
  LHashMap: specialize TAdvancedLockFreeHashMap<Integer, Integer>;
  LValue: Integer;
  I: Integer;
  LInsertCount, LGetCount: Integer;
  LBatchSize: Integer;
  LRandomKey: Integer;
begin
  WriteLn;
  WriteLn('=== 调试大容量测试问题 ===');
  
  LHashMap := specialize TAdvancedLockFreeHashMap<Integer, Integer>.Create(8192);
  try
    WriteLn('初始容量: ', LHashMap.GetCapacity);
    WriteLn;
    
    LInsertCount := 0;
    LBatchSize := 1000;
    
    // 分批插入，每批检查一次
    for I := 1 to 10000 do
    begin
      if LHashMap.Put(I, I * 2) then
        Inc(LInsertCount);
      
      // 每1000个检查一次
      if (I mod LBatchSize) = 0 then
      begin
        WriteLn(Format('已插入 %d 个，成功 %d 个，大小 %d，容量 %d', [
          I, LInsertCount, LHashMap.GetSize, LHashMap.GetCapacity
        ]));
      end;
    end;
    
    WriteLn;
    WriteLn(Format('插入完成：尝试 10000 个，成功 %d 个', [LInsertCount]));
    WriteLn(Format('哈希表大小: %d, 容量: %d', [LHashMap.GetSize, LHashMap.GetCapacity]));
    WriteLn;
    
    // 验证前100个键
    LGetCount := 0;
    WriteLn('验证前100个键...');
    for I := 1 to 100 do
    begin
      if LHashMap.Get(I, LValue) and (LValue = I * 2) then
        Inc(LGetCount);
    end;
    
    WriteLn(Format('前100个键：找到 %d 个', [LGetCount]));
    
    // 验证后100个键
    LGetCount := 0;
    WriteLn('验证后100个键...');
    for I := 9901 to 10000 do
    begin
      if LHashMap.Get(I, LValue) and (LValue = I * 2) then
        Inc(LGetCount);
    end;
    
    WriteLn(Format('后100个键：找到 %d 个', [LGetCount]));
    
    // 随机验证1000个键
    LGetCount := 0;
    WriteLn('随机验证1000个键...');
    for I := 1 to 1000 do
    begin
      LRandomKey := Random(10000) + 1;
      if LHashMap.Get(LRandomKey, LValue) and (LValue = LRandomKey * 2) then
        Inc(LGetCount);
    end;
    
    WriteLn(Format('随机1000个键：找到 %d 个', [LGetCount]));
    
  finally
    LHashMap.Free;
  end;
end;

begin
  WriteLn('TAdvancedLockFreeHashMap 调试测试');
  WriteLn('=================================');
  WriteLn;
  
  Randomize;
  
  try
    DebugSmallCapacityCollisions;
    DebugLargeCapacityTest;
    
    WriteLn;
    WriteLn('调试测试完成！按回车键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
