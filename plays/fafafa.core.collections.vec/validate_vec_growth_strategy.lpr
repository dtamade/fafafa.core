{$CODEPAGE UTF8}
program validate_vec_growth_strategy;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.core,
  fafafa.core.test.runner,
  fafafa.core.collections.base,
  fafafa.core.collections.vec;

// 临时验证：IGrowthStrategy 接口路径在 TVec 上的行为
// - 默认策略非空
// - SetGrowStrategy(nil) 恢复默认
// - 自定义接口策略的下界在首轮 Reserve 即生效
// - GetGrowStrategy 返回的接口等同于设置值（引用一致）

type
  TTestIGrowthStrategy = class(TInterfacedObject, IGrowthStrategy)
  private
    FDelta: SizeUInt;
  public
    constructor Create(aDelta: SizeUInt);
    function GetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
  end;

constructor TTestIGrowthStrategy.Create(aDelta: SizeUInt);
begin
  inherited Create;
  FDelta := aDelta;
end;

function TTestIGrowthStrategy.GetGrowSize(aCurrentSize, aRequiredSize: SizeUInt): SizeUInt;
begin
  // 简单策略：required + FDelta
  Result := aRequiredSize + FDelta;
end;

begin
  // 默认策略应非空
  Test('vec/grow/default_non_nil', procedure(const ctx: ITestContext)
  var V: specialize TVec<Integer>;
  begin
    V := specialize TVec<Integer>.Create;
    try
      ctx.AssertTrue(V.GetGrowStrategy <> nil, 'default strategy should not be nil');
    finally
      V.Free;
    end;
  end);

  // SetGrowStrategy(nil) 应恢复默认（不等于我们设置的自定义接口）
  Test('vec/grow/reset_to_default', procedure(const ctx: ITestContext)
  var V: specialize TVec<Integer>; S, S0: IGrowthStrategy;
  begin
    V := specialize TVec<Integer>.Create;
    try
      S := TTestIGrowthStrategy.Create(7);
      V.SetGrowStrategy(S);
      ctx.AssertTrue(V.GetGrowStrategy = S, 'get should equal the set interface');
      V.SetGrowStrategy(nil);
      S0 := V.GetGrowStrategy;
      ctx.AssertTrue(S0 <> nil, 'default after reset should be non-nil');
      ctx.AssertTrue(S0 <> S, 'default after reset should differ from custom');
    finally
      V.Free;
    end;
  end);

  // 自定义接口策略：首轮 Reserve(10) 在 0->? 时应 >= required+delta 且 >= old+10
  Test('vec/grow/custom_interface_lower_bound', procedure(const ctx: ITestContext)
  var V: specialize TVec<Integer>; OldCap: SizeUInt; S: IGrowthStrategy;
  begin
    V := specialize TVec<Integer>.Create;
    try
      S := TTestIGrowthStrategy.Create(7);
      V.SetGrowStrategy(S);
      OldCap := V.Capacity;
      V.Reserve(10);
      ctx.AssertTrue(V.Capacity >= OldCap + 10, 'cap should grow by at least required');
      ctx.AssertTrue(V.Capacity >= 17, 'custom lower bound (>= 10+7) should hold');
    finally
      V.Free;
    end;
  end);

  // 运行入口
  TestMain;
end.

