{$CODEPAGE UTF8}
unit test_pipeline_split_capture;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.pipeline, fafafa.core.process;

type
  TTestCase_Pipeline_Split_Capture = class(TTestCase)
  published
    procedure Test_Split_Capture_Output_and_ErrorText;
  end;

implementation

procedure TTestCase_Pipeline_Split_Capture.Test_Split_Capture_Output_and_ErrorText;
var
  P: IPipeline;
  OutText, ErrText: string;
begin
  {$IFDEF WINDOWS}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo OUT & echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .Start;
  {$ELSE}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo OUT; echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .Start;
  {$ENDIF}

  CheckTrue(P.WaitForExit(3000), 'Pipeline should finish');
  OutText := P.Output;
  ErrText := P.ErrorText;
  AssertTrue('OUT should appear in Output', Pos('OUT', OutText) > 0);
  AssertTrue('ERR should appear in ErrorText', Pos('ERR', ErrText) > 0);
end;

initialization
  RegisterTest(TTestCase_Pipeline_Split_Capture);
end.

