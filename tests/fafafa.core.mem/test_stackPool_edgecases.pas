{$CODEPAGE UTF8}
unit test_stackPool_edgecases;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.stackPool;

type
  { TTestCase_StackPool_EdgeCases }
  TTestCase_StackPool_EdgeCases = class(TTestCase)
  published
    procedure Test_Alloc_OverCapacity_ReturnsNil;
    procedure Test_RestoreState_OutOfRange_Ignored;
  end;

implementation

procedure TTestCase_StackPool_EdgeCases.Test_Alloc_OverCapacity_ReturnsNil;
var
  P: Pointer;
  S: TStackPool;
begin
  S := TStackPool.Create(128);
  try
    // 分配超过容量的大小应返回 nil
    P := S.Alloc(256);
    AssertNull('Alloc over capacity should return nil', P);
  finally
    S.Destroy;
  end;
end;

procedure TTestCase_StackPool_EdgeCases.Test_RestoreState_OutOfRange_Ignored;
var
  S: TStackPool;
  State: SizeUInt;
begin
  S := TStackPool.Create(64);
  try
    // 先分配 32 字节，UsedSize=32
    AssertNotNull('Alloc should succeed', S.Alloc(32));
    State := S.SaveState;
    AssertEquals('Saved state should equal used size', S.UsedSize, State);

    // 恢复到非常大的状态（越界）应被忽略
    S.RestoreState(1024);
    AssertEquals('Out of range restore should be ignored (no change)', State, S.UsedSize);
  finally
    S.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_StackPool_EdgeCases);
end.

