program tests_pipe_enh_only;

{$mode objfpc}{$H+}
{$HINTS OFF}
{$NOTES OFF}

uses
  Classes,
  consoletestrunner,
  test_pipeline_enhanced;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'pipeline enhanced only';
  Application.Run;
  Application.Free;
end.

