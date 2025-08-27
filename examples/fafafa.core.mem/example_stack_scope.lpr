{$CODEPAGE UTF8}
program example_stack_scope;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.stack_scope_helpers;

procedure ScopeDemo;
var
  S: TStackPool;
  Guard: TStackScopeGuard;
  P1, P2: Pointer;
begin
  WriteLn('--- StackPool Scope Demo (Guard) ---');
  S := TStackPool.Create(1024);
  try
    // 进入作用域：保存状态（RAII风格）
    Guard := TStackScopeGuard.Enter(S);
    try
      P1 := S.Alloc(128);
      P2 := S.Alloc(256, 16); // 对齐分配
      WriteLn('UsedSize after allocs = ', S.UsedSize);
      if (P1 = nil) or (P2 = nil) then
        raise Exception.Create('Allocation failed in scope');
      // 在此作用域内使用 P1/P2 ...
    finally
      // 离开作用域：恢复状态（隐式释放作用域内分配的全部内存）
      Guard.Leave;
      WriteLn('UsedSize after restore = ', S.UsedSize);
    end;
  finally
    S.Destroy;
  end;
end;

begin
  try
    ScopeDemo;
  except
    on E: Exception do begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

