{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
program test_range_simple;

uses
  fafafa.core.collections.vecdeque;

type
  TVecDequeInt = specialize TVecDeque<Integer>;

var
  VD: TVecDequeInt;
  Target: TVecDequeInt;
  Result: SizeUInt;
  i: Integer;

begin
  // 简单测试，验证编译和基本功能
  VD := TVecDequeInt.Create;
  Target := TVecDequeInt.Create;
  try
    // 测试 PopFrontRange
    VD.Clear;
    for i := 1 to 5 do
      VD.PushBack(i);

    Result := VD.PopFrontRange(3);
    // 验证结果
    if (Result = 3) and (VD.Count = 2) and (VD.Front = 4) then
      Write('PopFrontRange: OK')
    else
      Write('PopFrontRange: FAIL');

    // 测试 PopBackRange
    VD.Clear;
    for i := 1 to 5 do
      VD.PushBack(i);

    Result := VD.PopBackRange(3);
    if (Result = 3) and (VD.Count = 2) and (VD.Back = 2) then
      WriteLn(', PopBackRange: OK')
    else
      WriteLn(', PopBackRange: FAIL');

    // 测试 PopFrontRange 到容器
    VD.Clear;
    Target.Clear;
    for i := 10 to 15 do
      VD.PushBack(i);

    VD.PopFrontRange(3, Target);
    if (VD.Count = 3) and (Target.Count = 3) and (Target.Get(0) = 10) then
      WriteLn('PopFrontRange to collection: OK')
    else
      WriteLn('PopFrontRange to collection: FAIL');

  finally
    VD.Free;
    Target.Free;
  end;
end.
