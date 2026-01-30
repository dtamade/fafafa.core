program fafafa_core_mem_pool_fixed_growable_tests;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, fpcunit, consoletestrunner,
  fafafa.core.mem.pool.fixed.growable.testcase;

// registration is in unit itself

begin
  // Default console test runner format
  // Ensure registration is called
  fafafa.core.mem.pool.fixed.growable.testcase.RegisterTests;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

