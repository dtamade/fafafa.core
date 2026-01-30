{$CODEPAGE UTF8}
program example_core_test_minimal;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.core,
  fafafa.core.test.runner;

begin
  // Register a few minimal tests using the core API
  Test('example.smoke.equals', procedure(const ctx: ITestContext)
  begin
    ctx.AssertEquals('abc', 'a'+'bc');
  end);

  Test('example.smoke.subtests', procedure(const ctx: ITestContext)
  begin
    ctx.Run('a', procedure(const c: ITestContext)
    begin
      c.AssertTrue(True, 'subtest a must be true');
    end);
    ctx.Run('b', procedure(const c: ITestContext)
    begin
      c.AssertEquals('x', 'x');
    end);
  end);

  Test('example.foreach', procedure(const ctx: ITestContext)
  var
    arr: array[0..2] of string;
  begin
    arr[0] := 'a'; arr[1] := 'bb'; arr[2] := 'ccc';
    ctx.ForEachStr('len', arr, procedure(const c: ITestContext; const v: string)
    begin
      c.AssertTrue(Length(v) > 0, 'value must be non-empty');
    end);
  end);

  // Run via our custom runner (supports --filter/--junit/--json etc.)
  TestMain;
end.

