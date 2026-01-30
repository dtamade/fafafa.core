program coverage_test;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync.barrier;

procedure TestBasicFunctionality;
var
  B1, B2, B4: IBarrier;
begin
  WriteLn('=== 基础功能测试 ===');
  
  // 测试不同参与者数量的 barrier 创建
  B1 := MakeBarrier(1);
  B2 := MakeBarrier(2);
  B4 := MakeBarrier(4);
  
  WriteLn('✓ MakeBarrier(1): ', B1.GetParticipantCount);
  WriteLn('✓ MakeBarrier(2): ', B2.GetParticipantCount);
  WriteLn('✓ MakeBarrier(4): ', B4.GetParticipantCount);
  
  // 测试单参与者 barrier（应该立即返回 True）
  WriteLn('✓ Single participant Wait: ', B1.Wait);
  WriteLn('✓ Single participant Wait again: ', B1.Wait);
end;

procedure TestErrorConditions;
begin
  WriteLn('=== 错误条件测试 ===');
  
  try
    MakeBarrier(0);
    WriteLn('✗ MakeBarrier(0) should have failed');
  except
    on E: Exception do
      WriteLn('✓ MakeBarrier(0) correctly raised: ', E.ClassName);
  end;
  
  try
    MakeBarrier(-1);
    WriteLn('✗ MakeBarrier(-1) should have failed');
  except
    on E: Exception do
      WriteLn('✓ MakeBarrier(-1) correctly raised: ', E.ClassName);
  end;
end;

type
  TTestWorker = class(TThread)
  private
    FBarrier: IBarrier;
    FResult: PBoolean;
    FDelay: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ABarrier: IBarrier; AResult: PBoolean; ADelay: Integer = 0);
  end;

constructor TTestWorker.Create(ABarrier: IBarrier; AResult: PBoolean; ADelay: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FResult := AResult;
  FDelay := ADelay;
end;

procedure TTestWorker.Execute;
begin
  if FDelay > 0 then
    Sleep(FDelay);
  FResult^ := FBarrier.Wait;
end;

procedure TestConcurrency;
const
  PARTICIPANTS = 4;
var
  B: IBarrier;
  Workers: array[0..PARTICIPANTS-2] of TTestWorker;
  Results: array[0..PARTICIPANTS-1] of Boolean;
  i, SerialCount: Integer;
begin
  WriteLn('=== 并发测试 ===');
  
  B := MakeBarrier(PARTICIPANTS);
  
  // 创建工作线程
  for i := 0 to High(Workers) do
  begin
    Results[i+1] := False;
    Workers[i] := TTestWorker.Create(B, @Results[i+1], i * 10);
  end;
  
  try
    // 主线程参与
    Results[0] := B.Wait;
    
    // 等待所有工作线程
    for i := 0 to High(Workers) do
      Workers[i].WaitFor;
    
    // 统计串行线程数量
    SerialCount := 0;
    for i := 0 to High(Results) do
      if Results[i] then Inc(SerialCount);
    
    WriteLn('✓ Serial thread count: ', SerialCount, ' (should be 1)');
    
    if SerialCount = 1 then
      WriteLn('✓ Concurrency test PASSED')
    else
      WriteLn('✗ Concurrency test FAILED');
      
  finally
    for i := 0 to High(Workers) do
      Workers[i].Free;
  end;
end;

procedure TestReuse;
const
  ROUNDS = 5;
var
  B: IBarrier;
  Worker: TTestWorker;
  MainResult, WorkerResult: Boolean;
  Round, SerialCount: Integer;
begin
  WriteLn('=== 重用测试 ===');
  
  B := MakeBarrier(2);
  
  for Round := 1 to ROUNDS do
  begin
    MainResult := False;
    WorkerResult := False;
    
    Worker := TTestWorker.Create(B, @WorkerResult, 0);
    try
      MainResult := B.Wait;
      Worker.WaitFor;
      
      SerialCount := Integer(MainResult) + Integer(WorkerResult);
      WriteLn(Format('✓ Round %d: Serial count = %d', [Round, SerialCount]));
      
      if SerialCount <> 1 then
      begin
        WriteLn('✗ Reuse test FAILED at round ', Round);
        Exit;
      end;
    finally
      Worker.Free;
    end;
  end;
  
  WriteLn('✓ Reuse test PASSED');
end;

begin
  WriteLn('fafafa.core.sync.barrier 覆盖率测试');
  WriteLn('=====================================');
  
  try
    TestBasicFunctionality;
    WriteLn;
    
    TestErrorConditions;
    WriteLn;
    
    TestConcurrency;
    WriteLn;
    
    TestReuse;
    WriteLn;
    
    WriteLn('=====================================');
    WriteLn('✅ 所有覆盖率测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
