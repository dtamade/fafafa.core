{$CODEPAGE UTF8}
unit Test_fafafa_core_id_snowflake;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, fpcunit, testutils, testregistry,
  fafafa.core.id.snowflake;

type
  TTestCase_Snowflake = class(TTestCase)
  published
    procedure Test_CreateSnowflake_Default;
    procedure Test_CreateSnowflakeEx_Policy;
  end;

implementation

procedure TTestCase_Snowflake.Test_CreateSnowflake_Default;
var G: ISnowflake; id: TSnowflakeID;
begin
  G := CreateSnowflake(1);
  id := G.NextID;
  AssertEquals('worker=1', 1, Snowflake_WorkerId(id));
  AssertTrue('seq<=4095', Snowflake_Sequence(id) <= 4095);
end;

procedure TTestCase_Snowflake.Test_CreateSnowflakeEx_Policy;
var C: TSnowflakeConfig; G: ISnowflake; id: TSnowflakeID;
begin
  C.EpochMs := 1288834974657; C.WorkerId := 2; C.BackwardPolicy := sbWait;
  G := CreateSnowflakeEx(C);
  id := G.NextID;
  AssertEquals('worker=2', 2, Snowflake_WorkerId(id));
  AssertTrue('ts>=epoch', Snowflake_TimestampMs(id, C.EpochMs) >= C.EpochMs);
end;

// Note: Hard to deterministically force seq overflow without mocking time.
// Here we only ensure NextID returns and timestamp is >= previous, as a sanity check.
// For full overflow behavior, consider injecting a time source in Snowflake later.


initialization
  RegisterTest('fafafa.core.id.Snowflake', TTestCase_Snowflake);
end.

