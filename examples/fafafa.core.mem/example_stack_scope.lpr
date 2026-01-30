program example_stack_scope;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.stack_scope_helpers;

procedure ScopeDemo;
var
  LStack: TStackPool;
  LGuard: TStackScopeGuard;
  LPtr1: Pointer;
  LPtr2: Pointer;
begin
  WriteLn('--- StackPool Scope Demo (Guard) ---');
  LStack := TStackPool.Create(1024);
  try
    LGuard := TStackScopeGuard.Enter(LStack);
    try
      LPtr1 := LStack.Alloc(128);
      LPtr2 := LStack.Alloc(256, 16);
      WriteLn('UsedSize after allocs = ', LStack.UsedSize);
      if (LPtr1 = nil) or (LPtr2 = nil) then
        raise Exception.Create('Allocation failed in scope');
    finally
      LGuard.Leave;
      WriteLn('UsedSize after restore = ', LStack.UsedSize);
    end;
  finally
    LStack.Destroy;
  end;
end;

begin
  try
    ScopeDemo;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.
