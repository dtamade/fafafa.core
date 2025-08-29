program once_usage_example_new;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.once;

var
  GlobalCounter: Integer = 0;
  GlobalInitialized: Boolean = False;

// 示例1：简单的全局初始化
procedure GlobalInitProc;
begin
  WriteLn('执行全局初始化...');
  GlobalInitialized := True;
  Inc(GlobalCounter);
end;

procedure TestBasicUsage;
var
  Once: IOnce;
begin
  WriteLn('=== 示例1：基础使用 ===');
  
  // 创建 Once 实例并传入回调
  Once := MakeOnce(@GlobalInitProc);
  
  WriteLn('第一次调用 Execute:');
  Once.Execute;
  
  WriteLn('第二次调用 Execute (应该被忽略):');
  Once.Execute;
  
  WriteLn('第三次调用 Execute (应该被忽略):');
  Once.Execute;
  
  WriteLn('全局初始化状态: ', GlobalInitialized);
  WriteLn('回调执行次数: ', GlobalCounter);
  WriteLn('是否已完成: ', Once.Completed);
  WriteLn;
end;

// 示例2：对象方法回调
type
  TExampleClass = class
  private
    FValue: Integer;
  public
    constructor Create;
    procedure InitializeMethod;
    property Value: Integer read FValue;
  end;

constructor TExampleClass.Create;
begin
  inherited Create;
  FValue := 0;
end;

procedure TExampleClass.InitializeMethod;
begin
  WriteLn('执行对象方法初始化...');
  FValue := 42;
end;

procedure TestMethodCallback;
var
  Once: IOnce;
  Obj: TExampleClass;
begin
  WriteLn('=== 示例2：对象方法回调 ===');
  
  Obj := TExampleClass.Create;
  try
    // 使用对象方法作为回调
    Once := MakeOnce(@Obj.InitializeMethod);
    
    WriteLn('初始值: ', Obj.Value);
    
    WriteLn('第一次调用 Execute:');
    Once.Execute;
    WriteLn('值: ', Obj.Value);
    
    WriteLn('第二次调用 Execute (应该被忽略):');
    Once.Execute;
    WriteLn('值: ', Obj.Value);
    
    WriteLn('是否已完成: ', Once.Completed);
  finally
    Obj.Free;
  end;
  WriteLn;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
// 示例3：匿名过程
procedure TestAnonymousProc;
var
  Once: IOnce;
  LocalValue: string;
begin
  WriteLn('=== 示例3：匿名过程 ===');
  
  LocalValue := '未初始化';
  
  // 使用匿名过程，可以捕获局部变量
  Once := MakeOnce(
    procedure
    begin
      WriteLn('执行匿名过程初始化...');
      LocalValue := '已初始化';
    end
  );
  
  WriteLn('初始值: ', LocalValue);
  
  WriteLn('第一次调用 Execute:');
  Once.Execute;
  WriteLn('值: ', LocalValue);
  
  WriteLn('第二次调用 Execute (应该被忽略):');
  Once.Execute;
  WriteLn('值: ', LocalValue);
  
  WriteLn('是否已完成: ', Once.Completed);
  WriteLn;
end;
{$ENDIF}

// 示例4：单例模式实现
type
  TExampleSingleton = class
  private
    class var FInstance: TExampleSingleton;
    class var FOnce: IOnce;
    FValue: string;
    class procedure CreateInstanceProc;
  public
    constructor Create;
    class constructor CreateClass;
    class function GetInstance: TExampleSingleton;
    function GetValue: string;
  end;

constructor TExampleSingleton.Create;
begin
  inherited Create;
  FValue := 'Singleton Instance Created';
end;

class constructor TExampleSingleton.CreateClass;
begin
  FOnce := MakeOnce(@CreateInstanceProc);
end;

class procedure TExampleSingleton.CreateInstanceProc;
begin
  WriteLn('创建单例实例...');
  FInstance := TExampleSingleton.Create;
end;

function TExampleSingleton.GetValue: string;
begin
  Result := FValue;
end;

class function TExampleSingleton.GetInstance: TExampleSingleton;
begin
  FOnce.Execute;
  Result := FInstance;
end;

procedure TestSingletonPattern;
var
  Instance1, Instance2: TExampleSingleton;
begin
  WriteLn('=== 示例4：单例模式 ===');
  
  WriteLn('获取第一个实例:');
  Instance1 := TExampleSingleton.GetInstance;
  WriteLn('实例值: ', Instance1.GetValue);

  WriteLn('获取第二个实例:');
  Instance2 := TExampleSingleton.GetInstance;
  WriteLn('实例值: ', Instance2.GetValue);
  
  WriteLn('两个实例是否相同: ', Instance1 = Instance2);
  WriteLn;
end;

// 示例5：ILock 接口兼容性
procedure TestILockInterface;
var
  Once: IOnce;
  Lock: ILock;
begin
  WriteLn('=== 示例5：ILock 接口兼容性 ===');
  
  Once := MakeOnce(@GlobalInitProc);
  Lock := Once; // IOnce 继承自 ILock
  
  WriteLn('TryAcquire (未执行): ', Lock.TryAcquire);
  
  WriteLn('调用 Acquire (等同于 Execute):');
  Lock.Acquire;
  
  WriteLn('TryAcquire (已执行): ', Lock.TryAcquire);
  
  WriteLn('调用 Release (无操作):');
  Lock.Release;
  
  WriteLn('TryAcquire (仍然已执行): ', Lock.TryAcquire);
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.sync.once Usage Examples');
    WriteLn('===================================');
    WriteLn;
    
    TestBasicUsage;
    TestMethodCallback;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    TestAnonymousProc;
    {$ENDIF}
    
    TestSingletonPattern;
    TestILockInterface;
    
    WriteLn('所有示例完成！');
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
