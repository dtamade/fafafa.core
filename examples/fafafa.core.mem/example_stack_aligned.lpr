{$CODEPAGE UTF8}
program example_stack_aligned;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.stackPool;

procedure DemoAligned;
var
  S: TStackPool;
  P: Pointer;
  ok: Boolean;
  Align: SizeUInt;
begin
  Writeln('--- StackPool Aligned Allocation Demo ---');
  S := TStackPool.Create(1024);
  try
    // TryAllocAligned: 成功路径（32 字节对齐）
    Align := 32;
    ok := S.TryAllocAligned(128, P, Align);
    if ok and (P <> nil) then
      Writeln('TryAllocAligned(128, 32) => ok; Ptr = ', PtrUInt(P))
    else
      Writeln('TryAllocAligned(128, 32) => failed');

    // TryAllocAligned: 非 2 的幂对齐，返回 False 而非抛异常
    Align := 3;
    ok := S.TryAllocAligned(16, P, Align);
    if not ok then
      Writeln('TryAllocAligned(16, 3) => false (invalid alignment)');

    // AllocAligned: 非 2 的幂对齐，抛出异常（演示捕获）
    try
      P := S.AllocAligned(16, 6);
      Writeln('AllocAligned(16, 6) unexpectedly succeeded: Ptr=', PtrUInt(P));
    except
      on E: Exception do
        Writeln('AllocAligned(16, 6) raised: ', E.ClassName, ' - ', E.Message);
    end;

    // 正常再分配一次，验证连续对齐
    P := S.AllocAligned(64, 16);
    if P <> nil then
      Writeln('AllocAligned(64, 16) => Ptr = ', PtrUInt(P));

    // 重置
    S.Reset;
    Writeln('Reset done. UsedSize = ', S.UsedSize);
  finally
    S.Destroy;
  end;
end;

begin
  try
    DemoAligned;
    Writeln('Example completed.');
  except
    on E: Exception do begin
      Writeln('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

