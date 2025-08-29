program test_new_interface;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.sync.once;

var
  GlobalCounter: Integer = 0;

procedure TestCallback;
begin
  Inc(GlobalCounter);
  WriteLn('回调执行，计数器: ', GlobalCounter);
end;

procedure TestBasicExecute;
var
  Once: IOnce;
begin
  WriteLn('=== 测试基础 Execute 方法 ===');
  
  // 测试无参数 Execute（应该什么都不做）
  Once := MakeOnce;
  Once.Execute;
  WriteLn('无参数 Execute 完成');
  
  // 测试带回调的 Execute
  Once.Execute(@TestCallback);
  Once.Execute(@TestCallback); // 第二次调用应该被忽略
  
  WriteLn('预期计数器: 1, 实际计数器: ', GlobalCounter);
  if GlobalCounter = 1 then
    WriteLn('✓ 基础 Execute 测试通过')
  else
    WriteLn('✗ 基础 Execute 测试失败');
end;

procedure TestFactoryFunctions;
var
  Once: IOnce;
begin
  WriteLn('=== 测试工厂函数 ===');
  
  GlobalCounter := 0;
  
  // 测试构造时传入回调的工厂函数
  Once := MakeOnce(@TestCallback);
  Once.Execute; // 应该执行存储的回调
  Once.Execute; // 第二次调用应该被忽略
  
  WriteLn('预期计数器: 1, 实际计数器: ', GlobalCounter);
  if GlobalCounter = 1 then
    WriteLn('✓ 工厂函数测试通过')
  else
    WriteLn('✗ 工厂函数测试失败');
end;

procedure TestILockInterface;
var
  Once: IOnce;
begin
  WriteLn('=== 测试 ILock 接口 ===');
  
  GlobalCounter := 0;
  
  Once := MakeOnce(@TestCallback);
  
  // 测试 TryAcquire（应该返回 false，因为还未执行）
  if not Once.TryAcquire then
    WriteLn('✓ TryAcquire 在未执行时返回 false')
  else
    WriteLn('✗ TryAcquire 在未执行时应该返回 false');
  
  // 测试 Acquire（等同于 Execute）
  Once.Acquire;
  
  WriteLn('预期计数器: 1, 实际计数器: ', GlobalCounter);
  if GlobalCounter = 1 then
    WriteLn('✓ Acquire 方法工作正常')
  else
    WriteLn('✗ Acquire 方法失败');
  
  // 测试 TryAcquire（应该返回 true，因为已经执行）
  if Once.TryAcquire then
    WriteLn('✓ TryAcquire 在已执行时返回 true')
  else
    WriteLn('✗ TryAcquire 在已执行时应该返回 true');
  
  // 测试 Release（应该是无操作）
  Once.Release;
  WriteLn('✓ Release 方法调用成功（无操作）');
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TestAnonymousCallback;
var
  Once: IOnce;
  LocalCounter: Integer;
begin
  WriteLn('=== 测试匿名过程 ===');
  
  LocalCounter := 0;
  
  Once := MakeOnce(
    procedure
    begin
      Inc(LocalCounter);
      WriteLn('匿名过程执行，局部计数器: ', LocalCounter);
    end
  );
  
  Once.Execute;
  Once.Execute; // 第二次调用应该被忽略
  
  WriteLn('预期局部计数器: 1, 实际局部计数器: ', LocalCounter);
  if LocalCounter = 1 then
    WriteLn('✓ 匿名过程测试通过')
  else
    WriteLn('✗ 匿名过程测试失败');
end;
{$ENDIF}

begin
  try
    WriteLn('fafafa.core.sync.once 新接口测试');
    WriteLn('==================================');
    WriteLn;
    
    TestBasicExecute;
    WriteLn;
    
    TestFactoryFunctions;
    WriteLn;
    
    TestILockInterface;
    WriteLn;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    TestAnonymousCallback;
    WriteLn;
    {$ENDIF}
    
    WriteLn('所有测试完成！');
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
