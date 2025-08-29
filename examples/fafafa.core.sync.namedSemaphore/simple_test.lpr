program simple_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedSemaphore;

var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2, LGuard3, LGuard4: INamedSemaphoreGuard;
  LCurrentCount: Integer;

begin
  WriteLn('=== 简单测试 ===');

  try
    // 创建计数信号量：初始计数3，最大计数3
    WriteLn('创建信号量...');
    LSemaphore := MakeNamedSemaphore('SimpleTest', 3, 3);
    WriteLn('信号量创建成功: ', LSemaphore.GetName);
    WriteLn('最大计数: ', LSemaphore.GetMaxCount);

    // 获取当前计数
    LCurrentCount := LSemaphore.GetCurrentCount;
    if LCurrentCount >= 0 then
      WriteLn('当前可用计数: ', LCurrentCount);
    
    // 逐个获取信号量
    WriteLn('获取第1个信号量...');
    LGuard1 := LSemaphore.TryWait;
    if Assigned(LGuard1) then
      WriteLn('成功获取第1个信号量')
    else
      WriteLn('无法获取第1个信号量');
    
    WriteLn('获取第2个信号量...');
    LGuard2 := LSemaphore.TryWait;
    if Assigned(LGuard2) then
      WriteLn('成功获取第2个信号量')
    else
      WriteLn('无法获取第2个信号量');
    
    WriteLn('获取第3个信号量...');
    LGuard3 := LSemaphore.TryWait;
    if Assigned(LGuard3) then
      WriteLn('成功获取第3个信号量')
    else
      WriteLn('无法获取第3个信号量');
    
    WriteLn('尝试获取第4个信号量（应该失败）...');
    LGuard4 := LSemaphore.TryWait;
    if Assigned(LGuard4) then
      WriteLn('意外：获取了第4个信号量')
    else
      WriteLn('预期：无法获取第4个信号量');
    
    WriteLn('释放第1个信号量...');
    LGuard1 := nil;
    
    WriteLn('再次尝试获取信号量...');
    LGuard4 := LSemaphore.TryWait;
    if Assigned(LGuard4) then
      WriteLn('成功：释放后获取了信号量')
    else
      WriteLn('错误：释放后仍无法获取信号量');
    
    // 清理
    WriteLn('清理资源...');
    LGuard2 := nil;
    LGuard3 := nil;
    LGuard4 := nil;
    
    WriteLn('测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常：', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
