program fafafa_core_args_help_enhanced_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  Interfaces, Forms, GuiTestRunner,
  fafafa.core.args.help.enhanced.testcase;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.
