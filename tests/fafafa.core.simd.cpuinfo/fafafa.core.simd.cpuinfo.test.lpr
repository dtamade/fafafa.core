program fafafa_core_simd_cpuinfo_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  Interfaces, Forms, GuiTestRunner,
  fafafa.core.simd.cpuinfo.testcase;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.
