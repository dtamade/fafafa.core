program test_debug_hooks;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$DEFINE FAFAFA_CORE_DEBUG_ONCE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.once;

var
  DebugMessages: TStringList;

procedure MyDebugHook(const AEvent: TOnceDebugEvent; const AInstance: Pointer; const AMessage: string);
var
  EventName: string;
begin
  case AEvent of
    odeCreated: EventName := 'CREATED';
    odeExecuteStart: EventName := 'EXECUTE_START';
    odeExecuteEnd: EventName := 'EXECUTE_END';
    odeExecuteSkip: EventName := 'EXECUTE_SKIP';
    odePoisoned: EventName := 'POISONED';
    odeRecursive: EventName := 'RECURSIVE';
  end;
  
  DebugMessages.Add(Format('[%s] Instance=%p Message=%s', [EventName, AInstance, AMessage]));
  WriteLn(Format('[DEBUG] %s: %s', [EventName, AMessage]));
end;

procedure TestCallback;
begin
  WriteLn('测试回调执行');
end;

procedure TestBasicDebug;
var
  Once: IOnce;
begin
  WriteLn('=== 基础调试测试 ===');
  
  // 设置调试钩子
  OnceDebugHook := @MyDebugHook;
  
  // 创建 Once 实例
  Once := MakeOnce(@TestCallback);
  
  // 第一次执行
  WriteLn('第一次执行:');
  Once.Execute;
  
  // 第二次执行（应该被跳过）
  WriteLn('第二次执行:');
  Once.Execute;
  
  WriteLn('调试消息总数: ', DebugMessages.Count);
  WriteLn;
end;

procedure TestPoisonedDebug;
var
  Once: IOnce;
begin
  WriteLn('=== 毒化状态调试测试 ===');
  
  Once := MakeOnce(
    procedure
    begin
      WriteLn('抛出异常的回调');
      raise Exception.Create('测试异常');
    end
  );
  
  try
    WriteLn('执行会抛出异常的回调:');
    Once.Execute;
  except
    on E: Exception do
      WriteLn('捕获异常: ', E.Message);
  end;
  
  try
    WriteLn('再次执行毒化的 Once:');
    Once.Execute;
  except
    on E: Exception do
      WriteLn('捕获毒化异常: ', E.Message);
  end;
  
  WriteLn;
end;

var
  i: Integer;
begin
  try
    DebugMessages := TStringList.Create;
    try
      WriteLn('fafafa.core.sync.once 调试钩子测试');
      WriteLn('==================================');
      WriteLn;

      TestBasicDebug;
      TestPoisonedDebug;

      WriteLn('所有调试消息:');
      WriteLn('============');
      for i := 0 to DebugMessages.Count - 1 do
        WriteLn(DebugMessages[i]);
      
      WriteLn;
      WriteLn('调试测试完成！');
      
    finally
      DebugMessages.Free;
    end;
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
