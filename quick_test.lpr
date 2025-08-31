program quick_test;

{$I ../../src/fafafa.core.settings.inc}
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
  WriteLn('fafafa.core.sync.spin Release 性能测试');
  WriteLn('====================================');
  
  try
    // 创建自旋锁
    Spin := MakeSpin;
    WriteLn('✓ 自旋锁创建成功');
    
    // 性能测试
    WriteLn('');
    WriteLn('开始 Release 性能测试...');
    Operations := 0;
    StartTime := GetTickCount64;
    
    for i := 1 to 10000000 do  // 1000万次操作
    begin
      Spin.Acquire;
      Spin.Release;
      Inc(Operations);
    end;
    
    EndTime := GetTickCount64;
    
    WriteLn(Format('完成 %d 次操作', [Operations]));
    WriteLn(Format('耗时: %d ms', [EndTime - StartTime]));
    if (EndTime - StartTime) > 0 then
    begin
      WriteLn(Format('吞吐量: %.0f ops/sec', [Operations * 1000.0 / (EndTime - StartTime)]));
      WriteLn(Format('平均延迟: %.2f ns/op', [(EndTime - StartTime) * 1000000.0 / Operations]));
    end;
    
    WriteLn('');
    WriteLn('✓ Release 性能测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
