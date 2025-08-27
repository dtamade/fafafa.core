program test_make_contiguous_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure RunMakeContiguousTests;
var
  D: specialize TVecDeque<Integer>;
  i, Fail: Integer;
  P1, P2: specialize TVecDeque<Integer>.PElement;
  L1, L2: SizeUInt;
  P: specialize TVecDeque<Integer>.PElement;

  procedure CheckEqual(const Title: string; A, B: Integer);
  begin
    if A <> B then
    begin
      WriteLn('[FAIL] ', Title, ': expected=', B, ' actual=', A);
      Inc(Fail);
    end;
  end;

  procedure FillRange(Count, StartAt: Integer);
  var j: Integer;
  begin
    for j := 0 to Count - 1 do D.PushBack(StartAt + j);
  end;

  function AlwaysEqualComparer(const aLeft, aRight: Integer; aData: Pointer): SizeInt;
  begin
    Result := 0;
  end;

begin
  Fail := 0;
  WriteLn('=== 测试 VecDeque MakeContiguous（通过 SortWith 间接触发）===');

  // 场景1：跨环 -> 通过 SortWith(saInsertionSort, AlwaysEqualComparer) 触发整理；顺序保持
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    FillRange(6, 0);   // [0..5]
    for i := 0 to 3 do D.PopFront; // [4,5]
    FillRange(6, 6);   // 触发环绕 -> [4,5,6,7,8,9,10,11]

    // 整理前应为两段
    D.GetTwoSlices(P1, L1, P2, L2);
    if not ((L1 > 0) and (L2 > 0)) then
    begin
      WriteLn('[FAIL] 场景1 预期跨环的两段切片不存在');
      Inc(Fail);
    end;

    // 通过排序触发内部 MakeContiguous（比较器恒等，InsertionSort 不改变顺序）
    D.SortWith(0, D.Count, saInsertionSort);

    // 验证已连续
    P := D.PeekRange(D.Count);
    if P = nil then
    begin
      WriteLn('[FAIL] 场景1 排序后应物理连续，但 PeekRange 返回 nil');
      Inc(Fail);
    end
    else
    begin
      // 检查顺序未变
      for i := 0 to D.Count - 1 do
        CheckEqual('场景1 顺序检查 i=' + IntToStr(i), P[i], 4 + i);

      // GetTwoSlices 再检查应为单段
      D.GetTwoSlices(P1, L1, P2, L2);
      if not ((L1 = D.Count) and (L2 = 0)) then
      begin
        WriteLn('[FAIL] 场景1 排序后仍非单段连续');
        Inc(Fail);
      end;
    end;
  finally
    D.Free;
  end;

  // 场景2：已连续 -> 排序不改变，仍连续
  D := specialize TVecDeque<Integer>.Create;
  try
    FillRange(10, 100);
    D.SortWith(0, D.Count, saInsertionSort);
    P := D.PeekRange(D.Count);
    if P = nil then begin WriteLn('[FAIL] 场景2 排序后应保持连续'); Inc(Fail); end;
    for i := 0 to 9 do CheckEqual('场景2 i=' + IntToStr(i), P[i], 100 + i);
  finally
    D.Free;
  end;

  // 场景3：空容器 -> PeekRange(0) = nil，PeekRange(>0) = nil
  D := specialize TVecDeque<Integer>.Create;
  try
    if D.PeekRange(0) <> nil then begin WriteLn('[FAIL] 场景3 空容器 PeekRange(0) 应为 nil'); Inc(Fail); end;
    if D.PeekRange(1) <> nil then begin WriteLn('[FAIL] 场景3 空容器 PeekRange(1) 应为 nil'); Inc(Fail); end;
  finally
    D.Free;
  end;

  if Fail = 0 then
  begin
    WriteLn('[PASS] make_contiguous simple passed');
    Halt(0);
  end
  else
  begin
    WriteLn('[FAIL] make_contiguous simple failed, count=', Fail);
    Halt(1);
  end;
end;

begin
  RunMakeContiguousTests;
end.

