program simple_test;

{$I fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin;

var
  Spin: ISpin;
  i: Integer;
  StartTime, EndTime: QWord;
  Operations: Int64;

begin
  WriteLn('fafafa.core.sync.spin 简单测试');
  WriteLn('==============================');
  
  try
    // 创建自旋锁
    Spin := MakeSpin;
    WriteLn('✓ 自旋锁创建成功');
    
    // 基本功能测试
    Spin.Acquire;
    WriteLn('✓ 获取锁成功');
    
    Spin.Release;
    WriteLn('✓ 释放锁成功');
    
    // TryAcquire 测试
    if Spin.TryAcquire then
    begin
      WriteLn('✓ TryAcquire 成功');
      Spin.Release;
      WriteLn('✓ 释放锁成功');
    end
    else
      WriteLn('✗ TryAcquire 失败');
    
    // 性能测试
    WriteLn('');
    WriteLn('开始性能测试...');
    Operations := 0;
    StartTime := GetTickCount64;
    
    for i := 1 to 1000000 do
    begin
      Spin.Acquire;
      Spin.Release;
      Inc(Operations);
    end;
    
    EndTime := GetTickCount64;
    
    WriteLn(Format('完成 %d 次操作', [Operations]));
    WriteLn(Format('耗时: %d ms', [EndTime - StartTime]));
    if (EndTime - StartTime) > 0 then
      WriteLn(Format('吞吐量: %.0f ops/sec', [Operations * 1000.0 / (EndTime - StartTime)]));
    
    WriteLn('');
    WriteLn('✓ 所有测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
