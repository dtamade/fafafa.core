program lockfree_ifaces_factories_tests;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$DEFINE FAFAFA_CORE_IFACE_FACTORIES}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, consoletestrunner,
  fafafa.core.lockfree,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.factories,
  ifaces_factories.testcase;

begin
  DefaultFormat := fPlain;
  with TTestRunner.Create(nil) do
  try
    Initialize;
    Run;
  finally
    Free;
  end;
end.

