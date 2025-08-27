program test_slices_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure RunSlicesTests;
var
  D: specialize TVecDeque<Integer>;
  Buf: array of Integer;
  i, Fail: Integer;

  procedure CheckEqual(const Title: string; A, B: Integer);
  begin
    if A <> B then
    begin
      WriteLn('[FAIL] ', Title, ': expected=', B, ' actual=', A);
      Inc(Fail);
    end;
  end;

begin
  Fail := 0;
  WriteLn('=== 测试 VecDeque SerializeToArrayBuffer 在连续与跨环两种场景 ===');

  // 场景1：连续内存
  D := specialize TVecDeque<Integer>.Create;
  try
    for i := 0 to 9 do D.PushBack(i);
    SetLength(Buf, 10);
    D.SerializeToArrayBuffer(@Buf[0], 10);
    for i := 0 to 9 do
      CheckEqual('连续场景 Buf[' + IntToStr(i) + ']', Buf[i], i);
  finally
    D.Free;
  end;

  // 场景2：跨环（通过 ReserveExact 固定容量、PopFront 后再 PushBack 触发环绕）
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    for i := 0 to 5 do D.PushBack(i);      // [0,1,2,3,4,5]
    for i := 0 to 3 do D.PopFront;         // [4,5]
    for i := 6 to 11 do D.PushBack(i);     // 触发环绕，[4,5,6,7,8,9,10,11]

    if D.Count <> 8 then
      WriteLn('注意：期望 Count=8，实际=', D.Count);

    SetLength(Buf, 8);
    D.SerializeToArrayBuffer(@Buf[0], 8);
    for i := 0 to 7 do
      CheckEqual('跨环场景 Buf[' + IntToStr(i) + ']', Buf[i], 4 + i);
  finally
    D.Free;
  end;

  if Fail = 0 then
  begin
    WriteLn('[PASS] slices simple passed');
    Halt(0);
  end
  else
  begin
    WriteLn('[FAIL] slices simple failed, count=', Fail);
    Halt(1);
  end;
end;

begin
  RunSlicesTests;
end.

