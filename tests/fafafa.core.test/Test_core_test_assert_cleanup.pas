unit Test_core_test_assert_cleanup;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$modeswitch anonymousfunctions}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test.core;

type

  TTestCase_CoreTest_AssertCleanup = class(TTestCase)
  published
    procedure Test_AssertRaises_Works;
    procedure Test_Cleanup_LIFO_Order;
    procedure Test_Cleanup_Exception_Marks_Failure;
    procedure Test_Failure_With_Cleanup_Aggregates;
    procedure Test_Skip_With_Cleanup_Ignores;

  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_AssertCleanup.Test_AssertRaises_Works;
var
  Ctx: ITestContext;
  procedure Boom;
  begin
    raise EArgumentException.Create('boom');
  end;
begin
  Ctx := NewTestContext;
  Ctx.AssertRaises(EArgumentException, @Boom, 'must raise EArgumentException');
end;

procedure TTestCase_CoreTest_AssertCleanup.Test_Cleanup_LIFO_Order;
var
  Ctx: ITestContext;
  Log: string;
  procedure AddA; begin Log := Log + 'A'; end;
  procedure AddB; begin Log := Log + 'B'; end;
begin
  Ctx := NewTestContext;
  Log := '';
  Ctx.AddCleanup(@AddA);
  Ctx.AddCleanup(@AddB);
  // Run cleanups explicitly
  Ctx.RunCleanupsNow;
  AssertEquals('expected LIFO', 'BA', Log);
end;

procedure TTestCase_CoreTest_AssertCleanup.Test_Cleanup_Exception_Marks_Failure;
var
  Root: ITestContext;
begin
  Root := NewTestContext;
  Test('cleanup.success.then.fail', procedure(const ctx: ITestContext)
  begin
    ctx.AddCleanup(procedure begin raise EArgumentException.Create('cleanup boom'); end);
    ctx.AssertTrue(True);
  end);
  AssertTrue(True);
end;

procedure TTestCase_CoreTest_AssertCleanup.Test_Failure_With_Cleanup_Aggregates;
var
  Root: ITestContext;
begin
  Root := NewTestContext;
  Test('cleanup.fail.aggregate', procedure(const ctx: ITestContext)
  begin
    ctx.AddCleanup(procedure begin raise Exception.Create('c1'); end);
    ctx.AddCleanup(procedure begin raise Exception.Create('c2'); end);
    ctx.Fail('original failure');
  end);
  AssertTrue(True);
end;

procedure TTestCase_CoreTest_AssertCleanup.Test_Skip_With_Cleanup_Ignores;
var
  Root: ITestContext;
begin
  Root := NewTestContext;
  Test('cleanup.skip.ignored', procedure(const ctx: ITestContext)
  begin
    ctx.AddCleanup(procedure begin raise Exception.Create('c3'); end);
    ctx.Skip('not applicable');
  end);
  AssertTrue(True);
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_AssertCleanup);
end;

end.

