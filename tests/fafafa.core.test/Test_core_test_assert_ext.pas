unit Test_core_test_assert_ext;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test.core;

type
  TTestCase_CoreTest_AssertExt = class(TTestCase)
  published
    procedure Test_Throws_And_NotThrows;
    procedure Test_Skip_And_Assume;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_AssertExt.Test_Throws_And_NotThrows;
var
  Ctx: ITestContext;
  procedure Boom; begin raise EInvalidOp.Create('bad'); end;
  procedure Ok; begin end;
begin
  Ctx := NewTestContext;
  Ctx.Throws(EInvalidOp, @Boom, 'must throw');
  Ctx.NotThrows(@Ok, 'must not throw');
end;

procedure TTestCase_CoreTest_AssertExt.Test_Skip_And_Assume;
var
  Ctx: ITestContext;
begin
  Ctx := NewTestContext;
  // Skip should mark test as skipped (treated as success for now)
  Ctx.Skip('not applicable');
  // Assume false should also skip
  Ctx.Assume(False, 'env not ready');
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_AssertExt);
end;

end.

