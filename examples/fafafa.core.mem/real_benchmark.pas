program real_benchmark;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.production;

// 简化的IfThen函数
function IfThen(aCondition: Boolean; const aTrue, aFalse: string): string;
begin
  if aCondition then
    Result := aTrue
  else
    Result := aFalse;
end;

function IsNonInteractive: Boolean;
var
  LValue: string;
begin
  Result := FindCmdLineSwitch('ci', ['-', '/'], True) or
    FindCmdLineSwitch('no-pause', ['-', '/'], True) or
    FindCmdLineSwitch('nopause', ['-', '/'], True);
  if Result then Exit;
  LValue := Trim(GetEnvironmentVariable('CI'));
  Result := (LValue <> '') and (UpperCase(LValue) <> '0') and (UpperCase(LValue) <> 'FALSE');
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

procedure AddResult(const aTestName: string; aRTLTime, aFastMemTime: QWord; aSuccess: Boolean);
var
  LIndex: Integer;
begin
  LIndex := Length(GResults);
  SetLength(GResults, LIndex + 1);

  with GResults[LIndex] do
  begin
    TestName := aTestName;
    RTLTime := aRTLTime;
    FastMemTime := aFastMemTime;
    if aFastMemTime > 0 then
      Speedup := aRTLTime / aFastMemTime
    else
      Speedup := 0;
    Success := aSuccess;
  end;
end;

function BenchmarkFixedSize(aSize: SizeUInt; aIterations: Integer): TBenchmarkResult;
var
  LIndex: Integer;
  LStart: QWord;
  LEnd: QWord;
  LRTLTime: QWord;
  LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
begin
  Result.TestName := Format('固定大小 %d 字节', [aSize]);
  Result.Success := True;

  SetLength(LPtrs, aIterations);
  LManager := GetMemManager;

  try
    // 测试RTL
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
      LPtrs[LIndex] := GetMem(aSize);
    for LIndex := 0 to aIterations - 1 do
      FreeMem(LPtrs[LIndex]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;

    // 测试FastMem
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
      LPtrs[LIndex] := LManager.Alloc(aSize);
    for LIndex := 0 to aIterations - 1 do
      LManager.Free(LPtrs[LIndex]);
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

function BenchmarkMixedSizes(aIterations: Integer): TBenchmarkResult;
var
  LIndex: Integer;
  LStart: QWord;
  LEnd: QWord;
  LRTLTime: QWord;
  LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
  LSizes: array[0..7] of SizeUInt = (16, 32, 48, 64, 96, 128, 192, 256);
  LSize: SizeUInt;
begin
  Result.TestName := '混合大小分配';
  Result.Success := True;

  SetLength(LPtrs, aIterations);
  LManager := GetMemManager;

  try
    // 测试RTL
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
    begin
      LSize := LSizes[LIndex mod Length(LSizes)];
      LPtrs[LIndex] := GetMem(LSize);
    end;
    for LIndex := 0 to aIterations - 1 do
      FreeMem(LPtrs[LIndex]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;

    // 测试FastMem
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
    begin
      LSize := LSizes[LIndex mod Length(LSizes)];
      LPtrs[LIndex] := LManager.Alloc(LSize);
    end;
    for LIndex := 0 to aIterations - 1 do
      LManager.Free(LPtrs[LIndex]);
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

function BenchmarkFragmentation(aIterations: Integer): TBenchmarkResult;
var
  LIndex: Integer;
  LStart: QWord;
  LEnd: QWord;
  LRTLTime: QWord;
  LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
begin
  Result.TestName := '碎片化测试';
  Result.Success := True;

  SetLength(LPtrs, aIterations);
  LManager := GetMemManager;

  try
    // 测试RTL - 分配后随机释放一半
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
      LPtrs[LIndex] := GetMem(64);
    // 随机释放一半
    for LIndex := 0 to aIterations - 1 do
      if LIndex mod 2 = 0 then
        FreeMem(LPtrs[LIndex]);
    // 重新分配
    for LIndex := 0 to aIterations - 1 do
      if LIndex mod 2 = 0 then
        LPtrs[LIndex] := GetMem(64);
    // 全部释放
    for LIndex := 0 to aIterations - 1 do
      FreeMem(LPtrs[LIndex]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;

    // 测试FastMem
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
      LPtrs[LIndex] := LManager.Alloc(64);
    for LIndex := 0 to aIterations - 1 do
      if LIndex mod 2 = 0 then
        LManager.Free(LPtrs[LIndex]);
    for LIndex := 0 to aIterations - 1 do
      if LIndex mod 2 = 0 then
        LPtrs[LIndex] := LManager.Alloc(64);
    for LIndex := 0 to aIterations - 1 do
      LManager.Free(LPtrs[LIndex]);
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

function BenchmarkStackAllocation(aIterations: Integer): TBenchmarkResult;
var
  LIndex: Integer;
  LStart: QWord;
  LEnd: QWord;
  LRTLTime: QWord;
  LFastTime: QWord;
  LPtrs: array of Pointer;
  LManager: TMemManager;
begin
  Result.TestName := '栈式分配';
  Result.Success := True;

  SetLength(LPtrs, aIterations);
  LManager := GetMemManager;

  try
    // 测试RTL
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
      LPtrs[LIndex] := GetMem(32 + (LIndex mod 64));
    for LIndex := 0 to aIterations - 1 do
      FreeMem(LPtrs[LIndex]);
    LEnd := GetTickCount64;
    LRTLTime := LEnd - LStart;

    // 测试栈分配
    LStart := GetTickCount64;
    for LIndex := 0 to aIterations - 1 do
    begin
      LPtrs[LIndex] := LManager.StackAlloc(32 + (LIndex mod 64));
      if LPtrs[LIndex] = nil then
      begin
        LManager.StackReset;
        LPtrs[LIndex] := LManager.StackAlloc(32 + (LIndex mod 64));
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
  LIndex: Integer;
  LData: PByte;
begin
  WriteLn('测试内存完整性...');

  LManager := GetMemManager;

  // 分配并写入数据
  for LIndex := 0 to 999 do
  begin
    LPtrs[LIndex] := LManager.Alloc(64);
    if LPtrs[LIndex] <> nil then
    begin
      LData := PByte(LPtrs[LIndex]);
      LData^ := Byte(LIndex and $FF);
    end;
  end;

  // 验证数据
  for LIndex := 0 to 999 do
  begin
    if LPtrs[LIndex] <> nil then
    begin
      LData := PByte(LPtrs[LIndex]);
      if LData^ <> Byte(LIndex and $FF) then
      begin
        WriteLn('❌ 内存数据损坏，索引: ', LIndex);
        Exit;
      end;
    end;
  end;

  // 释放内存
  for LIndex := 0 to 999 do
    LManager.Free(LPtrs[LIndex]);

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
  LIndex: Integer;
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

  for LIndex := 0 to High(GResults) do
  begin
    with GResults[LIndex] do
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
  LIndex: Integer;
begin
  WriteLn('📈 内存统计测试...');

  LManager := GetMemManager;

  // 分配一些内存
  for LIndex := 0 to 99 do
    LPtrs[LIndex] := LManager.Alloc(64);

  LStats := LManager.GetTotalStats;
  WriteLn('总内存: ', LStats.TotalBytes, ' 字节');
  WriteLn('已使用: ', LStats.UsedBytes, ' 字节');
  WriteLn('分配次数: ', LStats.AllocCount);
  WriteLn('释放次数: ', LStats.FreeCount);

  // 释放内存
  for LIndex := 0 to 99 do
    LManager.Free(LPtrs[LIndex]);

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

  if not IsNonInteractive then
  begin
    WriteLn('按任意键退出...');
    ReadLn;
  end;
end.
