{$CODEPAGE UTF8}
program real_benchmark;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.production;

// 简化的IfThen函数
function IfThen(ACondition: Boolean; const ATrue, AFalse: string): string;
begin
  if ACondition then Result := ATrue else Result := AFalse;
end;

type
  TBenchmarkResult = record
    TestName: string;
    RTLTime: QWord;
    FastMemTime: QWord;
    Speedup: Single;
    Success: Boolean;
  end;

var
  GResults: array of TBenchmarkResult;

procedure AddResult(const ATestName: string; ARTLTime, AFastMemTime: QWord; ASuccess: Boolean);
var
  LIndex: Integer;
begin
  LIndex := Length(GResults);
  SetLength(GResults, LIndex + 1);
  
  with GResults[LIndex] do
  begin
    TestName := ATestName;
    RTLTime := ARTLTime;
    FastMemTime := AFastMemTime;
    if AFastMemTime > 0 then
      Speedup := ARTLTime / AFastMemTime
    else
      Speedup := 0;
    Success := ASuccess;
  end;
end;

function BenchmarkFixedSize(ASize: SizeUInt; AIterations: Integer): TBenchmarkResult;
var
  I: Integer;
  LStart, LEnd: QWord;
  LRTLTime, LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
begin
  Result.TestName := Format('固定大小 %d 字节', [ASize]);
  Result.Success := True;
  
  SetLength(LPtrs, AIterations);
  LManager := GetMemManager;
  
  try
    // 测试RTL
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
      LPtrs[I] := GetMem(ASize);
    for I := 0 to AIterations - 1 do
      FreeMem(LPtrs[I]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;
    
    // 测试FastMem
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
      LPtrs[I] := LManager.Alloc(ASize);
    for I := 0 to AIterations - 1 do
      LManager.Free(LPtrs[I]);
    LEnd := GetTickCount64;
    LFastTime := LEnd - LStart;
    
    Result.RTLTime := LRTLTime;
    Result.FastMemTime := LFastTime;
    if LFastTime > 0 then
      Result.Speedup := LRTLTime / LFastTime
    else
      Result.Speedup := 0;
      
  except
    on E: Exception do
    begin
      WriteLn('测试失败: ', E.Message);
      Result.Success := False;
    end;
  end;
end;

function BenchmarkMixedSizes(AIterations: Integer): TBenchmarkResult;
var
  I: Integer;
  LStart, LEnd: QWord;
  LRTLTime, LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
  LSizes: array[0..7] of SizeUInt = (16, 32, 48, 64, 96, 128, 192, 256);
  LSize: SizeUInt;
begin
  Result.TestName := '混合大小分配';
  Result.Success := True;
  
  SetLength(LPtrs, AIterations);
  LManager := GetMemManager;
  
  try
    // 测试RTL
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
    begin
      LSize := LSizes[I mod Length(LSizes)];
      LPtrs[I] := GetMem(LSize);
    end;
    for I := 0 to AIterations - 1 do
      FreeMem(LPtrs[I]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;
    
    // 测试FastMem
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
    begin
      LSize := LSizes[I mod Length(LSizes)];
      LPtrs[I] := LManager.Alloc(LSize);
    end;
    for I := 0 to AIterations - 1 do
      LManager.Free(LPtrs[I]);
    LEnd := GetTickCount64;
    LFastTime := LEnd - LStart;
    
    Result.RTLTime := LRTLTime;
    Result.FastMemTime := LFastTime;
    if LFastTime > 0 then
      Result.Speedup := LRTLTime / LFastTime
    else
      Result.Speedup := 0;
      
  except
    on E: Exception do
    begin
      WriteLn('混合大小测试失败: ', E.Message);
      Result.Success := False;
    end;
  end;
end;

function BenchmarkFragmentation(AIterations: Integer): TBenchmarkResult;
var
  I, J: Integer;
  LStart, LEnd: QWord;
  LRTLTime, LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
begin
  Result.TestName := '碎片化测试';
  Result.Success := True;
  
  SetLength(LPtrs, AIterations);
  LManager := GetMemManager;
  
  try
    // 测试RTL - 分配后随机释放一半
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
      LPtrs[I] := GetMem(64);
    // 随机释放一半
    for I := 0 to AIterations - 1 do
      if I mod 2 = 0 then
        FreeMem(LPtrs[I]);
    // 重新分配
    for I := 0 to AIterations - 1 do
      if I mod 2 = 0 then
        LPtrs[I] := GetMem(64);
    // 全部释放
    for I := 0 to AIterations - 1 do
      FreeMem(LPtrs[I]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;
    
    // 测试FastMem
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
      LPtrs[I] := LManager.Alloc(64);
    for I := 0 to AIterations - 1 do
      if I mod 2 = 0 then
        LManager.Free(LPtrs[I]);
    for I := 0 to AIterations - 1 do
      if I mod 2 = 0 then
        LPtrs[I] := LManager.Alloc(64);
    for I := 0 to AIterations - 1 do
      LManager.Free(LPtrs[I]);
    LEnd := GetTickCount64;
    LFastTime := LEnd - LStart;
    
    Result.RTLTime := LRTLTime;
    Result.FastMemTime := LFastTime;
    if LFastTime > 0 then
      Result.Speedup := LRTLTime / LFastTime
    else
      Result.Speedup := 0;
      
  except
    on E: Exception do
    begin
      WriteLn('碎片化测试失败: ', E.Message);
      Result.Success := False;
    end;
  end;
end;

function BenchmarkStackAllocation(AIterations: Integer): TBenchmarkResult;
var
  I: Integer;
  LStart, LEnd: QWord;
  LRTLTime, LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
begin
  Result.TestName := '栈式分配';
  Result.Success := True;
  
  SetLength(LPtrs, AIterations);
  LManager := GetMemManager;
  
  try
    // 测试RTL
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
      LPtrs[I] := GetMem(32 + (I mod 64));
    for I := 0 to AIterations - 1 do
      FreeMem(LPtrs[I]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;
    
    // 测试栈分配
    LStart := GetTickCount64;
    for I := 0 to AIterations - 1 do
    begin
      LPtrs[I] := LManager.StackAlloc(32 + (I mod 64));
      if LPtrs[I] = nil then
      begin
        LManager.StackReset;
        LPtrs[I] := LManager.StackAlloc(32 + (I mod 64));
      end;
    end;
    LManager.StackReset; // 批量释放
    LEnd := GetTickCount64;
    LFastTime := LEnd - LStart;
    
    Result.RTLTime := LRTLTime;
    Result.FastMemTime := LFastTime;
    if LFastTime > 0 then
      Result.Speedup := LRTLTime / LFastTime
    else
      Result.Speedup := 0;
      
  except
    on E: Exception do
    begin
      WriteLn('栈分配测试失败: ', E.Message);
      Result.Success := False;
    end;
  end;
end;

procedure TestMemoryIntegrity;
var
  LManager: TMemManager;
  LPtrs: array[0..999] of Pointer;
  I: Integer;
  LData: PByte;
begin
  WriteLn('测试内存完整性...');
  
  LManager := GetMemManager;
  
  // 分配并写入数据
  for I := 0 to 999 do
  begin
    LPtrs[I] := LManager.Alloc(64);
    if LPtrs[I] <> nil then
    begin
      LData := PByte(LPtrs[I]);
      LData^ := Byte(I and $FF);
    end;
  end;
  
  // 验证数据
  for I := 0 to 999 do
  begin
    if LPtrs[I] <> nil then
    begin
      LData := PByte(LPtrs[I]);
      if LData^ <> Byte(I and $FF) then
      begin
        WriteLn('❌ 内存数据损坏，索引: ', I);
        Exit;
      end;
    end;
  end;
  
  // 释放内存
  for I := 0 to 999 do
    LManager.Free(LPtrs[I]);
    
  // 验证池完整性
  if LManager.ValidateAll then
    WriteLn('✅ 内存完整性测试通过')
  else
    WriteLn('❌ 内存池完整性验证失败');
end;

procedure RunAllBenchmarks;
const
  ITERATIONS = 50000;
var
  LResult: TBenchmarkResult;
begin
  WriteLn('🚀 开始真实性能基准测试...');
  WriteLn('迭代次数: ', ITERATIONS);
  WriteLn;
  
  // 固定大小测试
  LResult := BenchmarkFixedSize(32, ITERATIONS);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
  
  LResult := BenchmarkFixedSize(64, ITERATIONS);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
  
  LResult := BenchmarkFixedSize(128, ITERATIONS);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
  
  LResult := BenchmarkFixedSize(256, ITERATIONS);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
  
  // 混合大小测试
  LResult := BenchmarkMixedSizes(ITERATIONS);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
  
  // 碎片化测试
  LResult := BenchmarkFragmentation(ITERATIONS div 2);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
  
  // 栈分配测试
  LResult := BenchmarkStackAllocation(ITERATIONS);
  AddResult(LResult.TestName, LResult.RTLTime, LResult.FastMemTime, LResult.Success);
end;

procedure PrintResults;
var
  I: Integer;
  LTotalSpeedup: Single;
  LSuccessCount: Integer;
begin
  WriteLn;
  WriteLn('📊 基准测试结果');
  WriteLn('═══════════════════════════════════════════════════════════════');
  WriteLn('测试名称                RTL时间    FastMem时间   提升倍数   状态');
  WriteLn('───────────────────────────────────────────────────────────────');
  
  LTotalSpeedup := 0;
  LSuccessCount := 0;
  
  for I := 0 to High(GResults) do
  begin
    with GResults[I] do
    begin
      WriteLn(Format('%-20s %8d ms %10d ms %8.2fx    %s',
        [TestName, RTLTime, FastMemTime, Speedup, 
         IfThen(Success, '✅', '❌')]));
         
      if Success then
      begin
        LTotalSpeedup := LTotalSpeedup + Speedup;
        Inc(LSuccessCount);
      end;
    end;
  end;
  
  WriteLn('═══════════════════════════════════════════════════════════════');
  
  if LSuccessCount > 0 then
  begin
    WriteLn(Format('平均性能提升: %.2fx', [LTotalSpeedup / LSuccessCount]));
    WriteLn(Format('成功测试: %d/%d', [LSuccessCount, Length(GResults)]));
  end;
  
  WriteLn;
end;

procedure TestMemoryStats;
var
  LManager: TMemManager;
  LStats: TMemStats;
  LPtrs: array[0..99] of Pointer;
  I: Integer;
begin
  WriteLn('📈 内存统计测试...');
  
  LManager := GetMemManager;
  
  // 分配一些内存
  for I := 0 to 99 do
    LPtrs[I] := LManager.Alloc(64);
    
  LStats := LManager.GetTotalStats;
  WriteLn('总内存: ', LStats.TotalBytes, ' 字节');
  WriteLn('已使用: ', LStats.UsedBytes, ' 字节');
  WriteLn('分配次数: ', LStats.AllocCount);
  WriteLn('释放次数: ', LStats.FreeCount);
  
  // 释放内存
  for I := 0 to 99 do
    LManager.Free(LPtrs[I]);
    
  LStats := LManager.GetTotalStats;
  WriteLn('释放后已使用: ', LStats.UsedBytes, ' 字节');
  WriteLn('释放次数: ', LStats.FreeCount);
  WriteLn;
end;

begin
  WriteLn('╔══════════════════════════════════════════════════════════════╗');
  WriteLn('║              fafafa.core.mem 真实性能基准测试                ║');
  WriteLn('╚══════════════════════════════════════════════════════════════╝');
  WriteLn;
  
  try
    // 运行所有基准测试
    RunAllBenchmarks;
    
    // 打印结果
    PrintResults;
    
    // 测试内存完整性
    TestMemoryIntegrity;
    WriteLn;
    
    // 测试统计功能
    TestMemoryStats;
    
    WriteLn('🎉 所有测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试过程中发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按任意键退出...');
  ReadLn;
end.
