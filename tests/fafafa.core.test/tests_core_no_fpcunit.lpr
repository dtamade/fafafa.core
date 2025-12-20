program tests_core_no_fpcunit;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}

{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.test.core,
  fafafa.core.test.runner;

procedure DefineTests;
begin
  // Minimal smoke (no TempDir)
  Test('core.smoke',
    procedure(const ctx: ITestContext)
    begin
      ctx.AssertTrue(True, 'smoke ok');
    end);

  // TempDir smoke (exercise CreateTempDir)
  Test('core.tempdir.smoke',
    procedure(const ctx: ITestContext)
    var P: string;
    begin
      P := ctx.TempDir;
      ctx.AssertTrue(DirectoryExists(P), 'Temp dir should exist');
    end);


  Test('core.equals',
    procedure(const ctx: ITestContext)
    begin
      ctx.AssertEquals('abc', 'a'+'bc', 'basic equals');
    end);
  Test('core.foreach',
    procedure(const ctx: ITestContext)
    var items: array[0..2] of string;
    begin
      items[0] := 'a'; items[1] := 'bb'; items[2] := 'ccc';
      ctx.ForEachStr('len', items,
        procedure(const c: ITestContext; const v: string)
        begin
          c.AssertTrue(Length(v) > 0, 'non-empty');
        end);
    end);

  Test('core.sub',
    procedure(const ctx: ITestContext)
    begin
      ctx.Run('a', procedure(const c: ITestContext)
      begin
        c.AssertTrue(True);
      end);
      ctx.Run('b', procedure(const c: ITestContext)
      begin
        c.AssertEquals('x','x');
      end);
    end);

  Test('core.foreach2',
    procedure(const ctx: ITestContext)
    const
      arr: array[0..2] of string = ('x','yy','zzz');
    begin
      ctx.ForEachStr('prefix', arr,
        procedure(const c: ITestContext; const v: string)
        begin
          c.AssertTrue(Length(v) >= 1);
        end);
    end);


end;


begin
  DefineTests;
  TestMain;
end.

