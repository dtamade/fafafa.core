program OnceUsageExample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.once;

var
  GlobalInitCount: Integer = 0;
  GlobalResource: TObject = nil;

// 示例1：简单的初始化过程
procedure InitializeGlobalResource;
begin
  Inc(GlobalInitCount);
  GlobalResource := TStringList.Create;
  WriteLn('全局资源已初始化，计数: ', GlobalInitCount);
end;

// 示例2：使用 MakeOnce 的不同方式
procedure DemonstrateBasicUsage;
var
  Once: IOnce;
begin
  WriteLn('=== 基本用法演示 ===');
  
  // 方式1：构造时传入过程，使用 Execute
  WriteLn('方式1：构造时传入过程');
  Once := MakeOnce(@InitializeGlobalResource);
  Once.Execute; // 执行初始化
  Once.Execute; // 不会重复执行
  
  // 重置用于演示
  GlobalInitCount := 0;
  if Assigned(GlobalResource) then
    FreeAndNil(GlobalResource);
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 方式2：使用匿名过程
  WriteLn('方式2：使用匿名过程');
  Once := MakeOnce(
    procedure
    begin
      Inc(GlobalInitCount);
      WriteLn('匿名过程执行，计数: ', GlobalInitCount);
    end
  );
  Once.Execute;
  Once.Execute; // 不会重复执行
  {$ENDIF}
  
  // 方式3：使用 ILock 接口
  WriteLn('方式3：使用 ILock 接口');
  GlobalInitCount := 0;
  if Assigned(GlobalResource) then
    FreeAndNil(GlobalResource);

  Once := MakeOnce(@InitializeGlobalResource);
  Once.Acquire; // 等同于 Execute
  Once.Acquire; // 不会重复执行
end;

// 示例3：单例模式实现
type
  TExampleSingleton = class
  private
    class var FInstance: TExampleSingleton;
    class var FOnce: IOnce;
    FValue: string;
    {$IFNDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class procedure CreateInstanceProc;
    {$ENDIF}
  public
    constructor Create;
    class constructor CreateClass;
    class function GetInstance: TExampleSingleton;
    property Value: string read FValue write FValue;
  end;

constructor TExampleSingleton.Create;
begin
  inherited Create;
  FValue := 'Singleton Instance Created at ' + DateTimeToStr(Now);
  WriteLn('单例实例已创建');
end;

class constructor TExampleSingleton.CreateClass;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 构造时传入创建实例的匿名过程
  FOnce := MakeOnce(
    procedure
    begin
      FInstance := TExampleSingleton.Create;
    end
  );
  {$ELSE}
  // 不支持匿名过程时使用普通过程
  FOnce := MakeOnce(@CreateInstanceProc);
  {$ENDIF}
end;

{$IFNDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class procedure TExampleSingleton.CreateInstanceProc;
begin
  FInstance := TExampleSingleton.Create;
end;
{$ENDIF}

class function TExampleSingleton.GetInstance: TExampleSingleton;
begin
  FOnce.Execute; // 执行一次性初始化
  Result := FInstance;
end;

procedure DemonstrateSingleton;
var
  Instance1, Instance2: TExampleSingleton;
begin
  WriteLn('=== 单例模式演示 ===');
  
  Instance1 := TExampleSingleton.GetInstance;
  Instance2 := TExampleSingleton.GetInstance;
  
  WriteLn('Instance1 = Instance2: ', Instance1 = Instance2);
  WriteLn('Instance1.Value: ', Instance1.Value);
  WriteLn('Instance2.Value: ', Instance2.Value);
end;

// 示例4：多线程安全初始化
procedure DemonstrateThreadSafety;
var
  Once: IOnce;
  ThreadCount: Integer;
  
  procedure ThreadProc;
  begin
    Once.Execute; // 线程安全的一次性执行
    InterlockedIncrement(ThreadCount);
  end;
  
var
  Threads: array[0..4] of TThread;
  i: Integer;
begin
  WriteLn('=== 多线程安全演示 ===');
  
  GlobalInitCount := 0;
  ThreadCount := 0;
  if Assigned(GlobalResource) then
    FreeAndNil(GlobalResource);
  
  Once := MakeOnce(@InitializeGlobalResource);
  
  // 创建多个线程同时调用 Execute
  for i := 0 to High(Threads) do
  begin
    Threads[i] := TThread.CreateAnonymousThread(@ThreadProc);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  WriteLn('线程数量: ', Length(Threads));
  WriteLn('完成的线程: ', ThreadCount);
  WriteLn('初始化次数: ', GlobalInitCount, ' (应该为 1)');
end;

// 示例5：状态查询
procedure DemonstrateStateQuery;
var
  Once: IOnce;
begin
  WriteLn('=== 状态查询演示 ===');
  
  Once := MakeOnce(@InitializeGlobalResource);
  
  WriteLn('执行前状态: ', Ord(Once.GetState));
  WriteLn('是否已完成: ', Once.Completed);
  
  Once.Execute;
  
  WriteLn('执行后状态: ', Ord(Once.GetState));
  WriteLn('是否已完成: ', Once.Completed);
  
  // 使用 TryAcquire
  if Once.TryAcquire then
    WriteLn('TryAcquire 成功（已完成状态）')
  else
    WriteLn('TryAcquire 失败');
end;

// 主程序
begin
  try
    WriteLn('fafafa.core.sync.once 使用示例');
    WriteLn('================================');
    
    DemonstrateBasicUsage;
    WriteLn;
    
    DemonstrateSingleton;
    WriteLn;
    
    DemonstrateThreadSafety;
    WriteLn;
    
    DemonstrateStateQuery;
    WriteLn;
    
    WriteLn('所有示例执行完成！');
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  // 清理资源
  if Assigned(GlobalResource) then
    FreeAndNil(GlobalResource);
    
  WriteLn('按回车键退出...');
  ReadLn;
end.
