program debug_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

type
  TTestIGrowthStrategy = class(TInterfacedObject, IGrowthStrategy)
  public
    function GetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
  end;

function TTestIGrowthStrategy.GetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
begin
  WriteLn('GetGrowSize called: Current=', aCurrentSize, ', Required=', aRequiredSize);
  // 简单策略：始终增长到 aRequiredSize + 7
  if aRequiredSize + 7 > aCurrentSize then
    Result := aRequiredSize + 7
  else
    Result := aCurrentSize;
  WriteLn('GetGrowSize result: ', Result);
end;

var
  LVec: specialize TVec<Integer>;
  LOldCap: SizeUInt;
  LOK: Boolean;

procedure TestSinglePush;
var
  LVec: specialize TVec<Integer>;
begin
  WriteLn('=== 测试单个 Push 操作 ===');
  LVec := specialize TVec<Integer>.Create;
  try
    WriteLn('初始状态: Count=', LVec.Count, ', Capacity=', LVec.Capacity);

    WriteLn('准备调用 Push(1)...');
    LVec.Push(1);
    WriteLn('Push(1) 完成: Count=', LVec.Count, ', Capacity=', LVec.Capacity);

    WriteLn('✓ 单个 Push 测试完成');
  finally
    LVec.Free;
  end;
end;

procedure TestBasicOperations;
var
  LVec: specialize TVec<Integer>;
  i: Integer;
begin
  WriteLn('=== 测试基本操作 ===');
  LVec := specialize TVec<Integer>.Create;
  try
    // 测试 Push 操作
    WriteLn('测试 Push 操作...');
    for i := 1 to 3 do  // 减少到3个，避免长时间挂起
    begin
      WriteLn('准备 Push ', i, '...');
      LVec.Push(i);
      WriteLn('Push ', i, ' 完成, Count=', LVec.Count, ', Capacity=', LVec.Capacity);
    end;

    WriteLn('✓ 基本操作测试完成');
  finally
    LVec.Free;
  end;
end;

procedure TestGrowthStrategy;
var
  LVec: specialize TVec<Integer>;
  LOldCap: SizeUInt;
begin
  WriteLn('=== 测试增长策略 ===');
  LVec := specialize TVec<Integer>.Create;
  try
    LVec.SetGrowStrategy(TTestIGrowthStrategy.Create);
    LOldCap := LVec.Capacity;
    WriteLn('初始容量: ', LOldCap);

    LVec.Reserve(10);
    WriteLn('Reserve 完成，新容量: ', LVec.Capacity);

    if LVec.Capacity >= 17 then
      WriteLn('✓ 自定义增长策略正常')
    else
      WriteLn('✗ 自定义增长策略异常');
  finally
    LVec.Free;
  end;
end;

begin
  WriteLn('开始调试测试...');

  try
    TestSinglePush;
    // TestBasicOperations;  // 先注释掉，专注于单个 Push
    // TestGrowthStrategy;   // 先注释掉
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;

  WriteLn('调试测试完成');
end.
