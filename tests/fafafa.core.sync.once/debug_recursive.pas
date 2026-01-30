program debug_recursive;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.sync.once, fafafa.core.sync.base;

var
  Once: IOnce;
  CallCount: Integer = 0;
  RecursiveCallDetected: Boolean = False;

procedure TestCallback;
begin
  Inc(CallCount);
  WriteLn('外层回调执行，CallCount = ', CallCount);
  
  // 尝试递归调用
  try
    WriteLn('尝试递归调用...');
    Once.Call(@TestCallback);
    WriteLn('错误：递归调用没有被检测到！');
  except
    on E: EOnceRecursiveCall do
    begin
      WriteLn('✓ 递归调用被正确检测: ', E.Message);
      RecursiveCallDetected := True;
    end;
    on E: Exception do
    begin
      WriteLn('意外异常: ', E.ClassName, ': ', E.Message);
    end;
  end;
  
  WriteLn('外层回调完成');
end;

begin
  WriteLn('=== 递归调用检测调试 ===');
  
  Once := MakeOnce;
  
  try
    WriteLn('开始调用 Once.Call...');
    Once.Call(@TestCallback);
    WriteLn('Once.Call 完成');
  except
    on E: Exception do
    begin
      WriteLn('外层异常: ', E.ClassName, ': ', E.Message);
    end;
  end;
  
  WriteLn('=== 结果 ===');
  WriteLn('CallCount: ', CallCount);
  WriteLn('RecursiveCallDetected: ', RecursiveCallDetected);
  WriteLn('Once.Completed: ', Once.Completed);
  WriteLn('Once.Poisoned: ', Once.Poisoned);
  
  if RecursiveCallDetected and (CallCount = 1) and Once.Completed then
    WriteLn('✓ 递归调用检测测试通过')
  else
    WriteLn('✗ 递归调用检测测试失败');
end.
