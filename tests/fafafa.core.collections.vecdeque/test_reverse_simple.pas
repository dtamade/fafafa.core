program test_reverse_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure RunReverseTests;
var
  D: specialize TVecDeque<Integer>;
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
  WriteLn('=== 测试 VecDeque Reverse 在连续与跨环两种场景 ===');

  // 场景1：连续 reverse 整体
  D := specialize TVecDeque<Integer>.Create;
  try
    for i := 0 to 5 do D.PushBack(i);   // [0..5]
    D.Reverse(0, D.Count);
    for i := 0 to 5 do
      CheckEqual('连续 Reverse Buf[' + IntToStr(i) + ']', D.Get(i), 5 - i);
  finally
    D.Free;
  end;

  // 场景2：跨环 reverse 子区间
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    for i := 0 to 5 do D.PushBack(i);  // [0,1,2,3,4,5]
    for i := 0 to 3 do D.PopFront;     // [4,5]
    for i := 6 to 11 do D.PushBack(i); // 环绕 -> [4,5,6,7,8,9,10,11]

    // 反转 [2..6) 的 4 个元素：逻辑下标 2..5 -> 期望 [4,5,10,9,8,7,6,11]
    D.Reverse(2, 4);
    CheckEqual('跨环 Reverse Count', D.Count, 8);
    // 检查整体序列
    CheckEqual('R[0]', D.Get(0), 4);
    CheckEqual('R[1]', D.Get(1), 5);
    CheckEqual('R[2]', D.Get(2), 9);
    CheckEqual('R[3]', D.Get(3), 8);
    CheckEqual('R[4]', D.Get(4), 7);
    CheckEqual('R[5]', D.Get(5), 6);
    CheckEqual('R[6]', D.Get(6), 10);
    CheckEqual('R[7]', D.Get(7), 11);
  finally
    D.Free;
  end;

  if Fail = 0 then
  begin
    WriteLn('[PASS] reverse simple passed');
    Halt(0);
  end
  else
  begin
    WriteLn('[FAIL] reverse simple failed, count=', Fail);
    Halt(1);
  end;
end;

begin
  RunReverseTests;
end.

