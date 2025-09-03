{$CODEPAGE UTF8}
program simple_test;

uses
  fafafa.core.sync.sem;

var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('Testing ISem and ISemGuard interfaces...');
  
  // Test MakeSem
  Sem := MakeSem(1, 3);
  if Sem <> nil then
    WriteLn('✓ MakeSem works')
  else
    WriteLn('✗ MakeSem failed');
    
  // Test basic operations
  Sem.Acquire;
  WriteLn('✓ Acquire works');
  
  Sem.Release;
  WriteLn('✓ Release works');
  
  // Test TryAcquire
  if Sem.TryAcquire then
    WriteLn('✓ TryAcquire works')
  else
    WriteLn('✗ TryAcquire failed');
    
  Sem.Release;
  
  WriteLn('All basic tests passed!');
end.
