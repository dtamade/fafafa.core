{$CODEPAGE UTF8}
unit test_pipeline_stress_heavy;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, fafafa.core.process, fafafa.core.pipeline;

type
  TTestPipelineStressHeavy = class(TTestCase)
  published
    procedure Heavy_Output_With_Drain_Timeout_FailFast;
  end;

implementation

procedure TTestPipelineStressHeavy.Heavy_Output_With_Drain_Timeout_FailFast;
var
  B: IPipelineBuilder;
  P: IPipeline;
  OutS: string;
begin
  // 构造长输出：for /L %i in (1,1,2000) do @echo line%i
  B := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','for','/L','%i','in','(1,1,2000)','do','@echo','line%i']).CaptureStdOut.DrainOutput(True))
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','^line']).CaptureStdOut.DrainOutput(True))
        .FailFast(True)
        .CaptureOutput(True);

  P := B.Start;
  AssertTrue('pipeline should finish in time', P.WaitForExit(10000));
  AssertTrue('pipeline success', P.Success);
  OutS := P.Output;
  AssertTrue('should contain many lines', Length(OutS) > 1000);
end;

initialization
  {$IFDEF RUN_STRESS}
  RegisterTest(TTestPipelineStressHeavy);
  {$ENDIF}
end.

