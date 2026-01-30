{$CODEPAGE UTF8}
program verify_rename;

uses
  fafafa.core.sync.sem;

var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('验证 ISemaphore → ISem 重命名...');
  
  // 测试 MakeSem
  Sem := MakeSem(1, 3);
  if Sem <> nil then
    WriteLn('✓ MakeSem 工作正常')
  else
    WriteLn('✗ MakeSem 失败');
    
  // 测试基本操作
  try
    Sem.Acquire;
    WriteLn('✓ Acquire 工作正常');
    
    Sem.Release;
    WriteLn('✓ Release 工作正常');
    
    // 测试 TryAcquire
    if Sem.TryAcquire then
    begin
      WriteLn('✓ TryAcquire 工作正常');
      Sem.Release;
    end
    else
      WriteLn('✗ TryAcquire 失败');
      
    WriteLn('✅ ISemaphore → ISem 重命名验证成功！');
  except
    on E: Exception do
      WriteLn('✗ 错误: ', E.Message);
  end;
end.
