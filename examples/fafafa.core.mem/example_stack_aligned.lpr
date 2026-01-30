program example_stack_aligned;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.stackPool;

procedure DemoAligned;
var
  LStack: TStackPool;
  LPtr: Pointer;
  LOk: Boolean;
  LAlign: SizeUInt;
begin
  Writeln('--- StackPool Aligned Allocation Demo ---');
  LStack := TStackPool.Create(1024);
  try
    // TryAllocAligned: 成功路径（32 字节对齐）
    LAlign := 32;
    LOk := LStack.TryAllocAligned(128, LPtr, LAlign);
    if LOk and (LPtr <> nil) then
      Writeln('TryAllocAligned(128, 32) => ok; Ptr = ', PtrUInt(LPtr))
    else
      Writeln('TryAllocAligned(128, 32) => failed');

    // TryAllocAligned: 非 2 的幂对齐，返回 False 而非抛异常
    LAlign := 3;
    LOk := LStack.TryAllocAligned(16, LPtr, LAlign);
    if not LOk then
      Writeln('TryAllocAligned(16, 3) => false (invalid alignment)');

    // AllocAligned: 非 2 的幂对齐，抛出异常（演示捕获）
    try
      LPtr := LStack.AllocAligned(16, 6);
      Writeln('AllocAligned(16, 6) unexpectedly succeeded: Ptr=', PtrUInt(LPtr));
    except
      on E: Exception do
        Writeln('AllocAligned(16, 6) raised: ', E.ClassName, ' - ', E.Message);
    end;

    // 正常再分配一次，验证连续对齐
    LPtr := LStack.AllocAligned(64, 16);
    if LPtr <> nil then
      Writeln('AllocAligned(64, 16) => Ptr = ', PtrUInt(LPtr));

    // 重置
    LStack.Reset;
    Writeln('Reset done. UsedSize = ', LStack.UsedSize);
  finally
    LStack.Destroy;
  end;
end;

begin
  try
    DemoAligned;
    Writeln('Example completed.');
  except
    on E: Exception do
    begin
      Writeln('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
