{$CODEPAGE UTF8}
program guard_demo;

{$mode objfpc}{$H+}

uses
  fafafa.core.sync.sem;

procedure DemoBasicGuard;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 基础守卫演示 ===');
  
  Sem := MakeSem(1, 3);
  WriteLn('信号量创建: 初始=1, 最大=3');
  WriteLn('可用许可: ', Sem.GetAvailableCount);
  
  // 获取守卫 - 自动获取许可
  Guard := Sem.AcquireGuard;
  WriteLn('获取守卫后可用许可: ', Sem.GetAvailableCount);
  WriteLn('守卫持有许可数: ', Guard.GetCount);
  
  // 守卫超出作用域时自动释放
  Guard := nil;
  WriteLn('守卫释放后可用许可: ', Sem.GetAvailableCount);
end;

procedure DemoManualRelease;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 手动释放演示 ===');
  
  Sem := MakeSem(2, 3);
  WriteLn('信号量创建: 初始=2, 最大=3');
  
  Guard := Sem.AcquireGuard(2);  // 获取2个许可
  WriteLn('获取2个许可后可用: ', Sem.GetAvailableCount);
  WriteLn('守卫持有许可数: ', Guard.GetCount);
  
  // 手动释放
  Guard.Release;
  WriteLn('手动释放后可用许可: ', Sem.GetAvailableCount);
  WriteLn('守卫持有许可数: ', Guard.GetCount);
end;

procedure DemoRAII;
var
  Sem: ISem;
begin
  WriteLn('=== RAII 演示 ===');
  
  Sem := MakeSem(1, 2);
  WriteLn('信号量创建: 初始=1, 最大=2');
  
  begin
    var Guard := Sem.AcquireGuard;
    WriteLn('进入作用域，获取守卫');
    WriteLn('可用许可: ', Sem.GetAvailableCount);
    WriteLn('守卫持有许可数: ', Guard.GetCount);
    
    // 嵌套作用域
    begin
      var Guard2 := Sem.TryAcquireGuard;
      if Guard2 <> nil then
      begin
        WriteLn('嵌套获取成功');
        WriteLn('可用许可: ', Sem.GetAvailableCount);
      end
      else
        WriteLn('嵌套获取失败 - 无可用许可');
    end; // Guard2 自动释放
    
    WriteLn('嵌套作用域结束后可用许可: ', Sem.GetAvailableCount);
  end; // Guard 自动释放
  
  WriteLn('主作用域结束后可用许可: ', Sem.GetAvailableCount);
end;

begin
  try
    DemoBasicGuard;
    WriteLn;
    DemoManualRelease;
    WriteLn;
    DemoRAII;
    
    WriteLn('=== 守卫演示完成 ===');
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
end.
