program test_example_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.once;

var
  GlobalCounter: Integer = 0;

procedure TestCallback;
begin
  Inc(GlobalCounter);
  WriteLn('回调执行，计数器: ', GlobalCounter);
end;

procedure TestBasicUsage;
var
  Once: IOnce;
begin
  WriteLn('=== 基础使用测试 ===');
  
  // 测试基础功能
  Once := MakeOnce(@TestCallback);
  Once.Execute;
  Once.Execute; // 第二次调用应该被忽略
  
  WriteLn('预期计数器: 1, 实际计数器: ', GlobalCounter);
  if GlobalCounter = 1 then
    WriteLn('✓ 基础使用测试通过')
  else
    WriteLn('✗ 基础使用测试失败');
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TestAnonymousProc;
var
  Once: IOnce;
  LocalCounter: Integer;
begin
  WriteLn('=== 匿名过程测试 ===');
  
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
    WriteLn('fafafa.core.sync.once 简化示例测试');
    WriteLn('==================================');
    WriteLn;
    
    TestBasicUsage;
    WriteLn;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    TestAnonymousProc;
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
