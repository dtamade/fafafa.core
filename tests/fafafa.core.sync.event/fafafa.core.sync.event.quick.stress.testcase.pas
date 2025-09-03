unit fafafa.core.sync.event.quick.stress.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 简单工作线程 }
  TSimpleWorker = class(TThread)
  private
    FEvent: IEvent;
    FOperations: Integer;
    FCompleted: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvent: IEvent; AOperations: Integer);
    property Completed: Integer read FCompleted;
  end;

  { 快速压力测试 - 避免长时间运行和复杂并发 }
  TTestCase_Event_QuickStress = class(TTestCase)
  published
    // 边界值测试
    procedure Test_Boundary_ZeroTimeout_Rapid;
    procedure Test_Boundary_SetReset_Rapid;
    
    // 快速压力测试
    procedure Test_Stress_CreateDestroy_Fast;
    procedure Test_Stress_Operations_Fast;
    
    // 简单并发测试
    procedure Test_Concurrency_Simple;
    
    // 错误处理测试
    procedure Test_ErrorHandling_Consistency;
  end;

implementation

{ TTestCase_Event_QuickStress }

procedure TTestCase_Event_QuickStress.Test_Boundary_ZeroTimeout_Rapid;
var 
  E: IEvent; 
  i: Integer; 
  r: TWaitResult;
begin
  WriteLn('Testing rapid zero timeout operations...');
  E := fafafa.core.sync.event.MakeEvent(False, False);
  
  // 快速零超时测试
  for i := 1 to 10000 do
  begin
    r := E.WaitFor(0);
    AssertEquals(Format('Iteration %d should timeout', [i]), Ord(wrTimeout), Ord(r));
    
    if i mod 2000 = 0 then
      WriteLn(Format('Zero timeout test: %d/10000 completed', [i]));
  end;
  
  WriteLn('Rapid zero timeout test completed successfully');
end;

procedure TTestCase_Event_QuickStress.Test_Boundary_SetReset_Rapid;
var 
  E: IEvent; 
  i: Integer;
begin
  WriteLn('Testing rapid set/reset operations...');
  E := fafafa.core.sync.event.MakeEvent(True, False); // manual reset
  
  // 快速设置/重置循环
  for i := 1 to 20000 do
  begin
    E.SetEvent;
    // 手动重置事件：设置后应该能立即等待成功
    AssertEquals(Format('Should be signaled after set %d', [i]), Ord(wrSignaled), Ord(E.WaitFor(0)));
    E.ResetEvent;
    // 重置后应该超时
    AssertEquals(Format('Should be reset after reset %d', [i]), Ord(wrTimeout), Ord(E.WaitFor(0)));
    
    if i mod 5000 = 0 then
      WriteLn(Format('Set/reset test: %d/20000 completed', [i]));
  end;
  
  WriteLn('Rapid set/reset test completed successfully');
end;

procedure TTestCase_Event_QuickStress.Test_Stress_CreateDestroy_Fast;
var 
  i: Integer; 
  E: IEvent;
begin
  WriteLn('Testing fast create/destroy cycles...');
  
  // 快速创建/销毁循环
  for i := 1 to 5000 do
  begin
    E := fafafa.core.sync.event.MakeEvent(i mod 2 = 0, i mod 3 = 0);
    E.SetEvent;
    E.WaitFor(0);
    E.ResetEvent;
    E := nil; // 显式释放引用
    
    if i mod 1000 = 0 then
      WriteLn(Format('Create/destroy test: %d/5000 completed', [i]));
  end;
  
  WriteLn('Fast create/destroy test completed successfully');
end;

procedure TTestCase_Event_QuickStress.Test_Stress_Operations_Fast;
var 
  E: IEvent; 
  i: Integer; 
  r: TWaitResult;
begin
  WriteLn('Testing fast mixed operations...');
  E := fafafa.core.sync.event.MakeEvent(True, False); // manual reset
  
  // 混合操作测试
  for i := 1 to 10000 do
  begin
    case i mod 4 of
      0: E.SetEvent;
      1: E.ResetEvent;
      2: begin
        r := E.WaitFor(0);
        // 不检查结果，只要不崩溃即可
      end;
      3: E.TryWait; // 替代 IsSignaled
    end;
    
    if i mod 2000 = 0 then
      WriteLn(Format('Mixed operations test: %d/10000 completed', [i]));
  end;
  
  WriteLn('Fast mixed operations test completed successfully');
end;

procedure TTestCase_Event_QuickStress.Test_Concurrency_Simple;
var
  E: IEvent;
  Workers: array[0..4] of TSimpleWorker;
  i, TotalCompleted: Integer;
begin
  WriteLn('Testing simple concurrency...');
  E := fafafa.core.sync.event.MakeEvent(True, False); // manual reset
  
  // 创建5个简单工作线程
  for i := 0 to 4 do
  begin
    Workers[i] := TSimpleWorker.Create(E, 1000);
    Workers[i].Start;
  end;
  
  // 让线程运行一会儿
  Sleep(100);
  
  // 设置事件
  E.SetEvent;
  
  // 等待线程完成
  TotalCompleted := 0;
  for i := 0 to 4 do
  begin
    Workers[i].WaitFor;
    TotalCompleted := TotalCompleted + Workers[i].Completed;
    WriteLn(Format('Worker %d completed %d operations', [i, Workers[i].Completed]));
    Workers[i].Free;
  end;
  
  WriteLn(Format('Simple concurrency test completed: %d total operations', [TotalCompleted]));
  AssertTrue('Should complete some operations', TotalCompleted > 0);
end;

procedure TTestCase_Event_QuickStress.Test_ErrorHandling_Consistency;
var 
  E: IEvent; 
  i: Integer; 
  r: TWaitResult;
begin
  WriteLn('Testing basic operations consistency...');
  E := fafafa.core.sync.event.MakeEvent(True, False);
  
  // 测试各种操作的基本功能
  for i := 1 to 1000 do
  begin
    // 正常操作序列
    E.SetEvent;
    r := E.WaitFor(0);
    AssertEquals('WaitFor should succeed', Ord(wrSignaled), Ord(r));
    E.ResetEvent;

    if i mod 200 = 0 then
      WriteLn(Format('Basic operations test: %d/1000 completed', [i]));
  end;
  
  WriteLn('Basic operations consistency test completed successfully');
end;

{ TSimpleWorker }
constructor TSimpleWorker.Create(const AEvent: IEvent; AOperations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
  FOperations := AOperations;
  FCompleted := 0;
end;

procedure TSimpleWorker.Execute;
var 
  i: Integer; 
  r: TWaitResult;
begin
  for i := 1 to FOperations do
  begin
    if Terminated then Break;
    
    try
      r := FEvent.WaitFor(10); // 短超时
      if r = wrSignaled then
        Inc(FCompleted);
        
      // 每100次操作检查终止标志
      if (i mod 100 = 0) and Terminated then Break;
    except
      // 忽略异常，继续运行
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_Event_QuickStress);

end.
