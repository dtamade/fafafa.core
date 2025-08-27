{$CODEPAGE UTF8}
unit test_pipeline_errortext_only_err;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.pipeline, fafafa.core.process;

type
  TTestCase_Pipeline_ErrorText_OnlyErr = class(TTestCase)
  published
    procedure Test_Only_Stderr_IsCaptured_In_ErrorText;
  end;

implementation

procedure TTestCase_Pipeline_ErrorText_OnlyErr.Test_Only_Stderr_IsCaptured_In_ErrorText;
var
  P: IPipeline;
  OutText, ErrText: string;
begin
  {$IFDEF WINDOWS}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .Start;
  {$ELSE}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .Start;
  {$ENDIF}

  CheckTrue(P.WaitForExit(3000), 'Pipeline should finish');
  OutText := P.Output;
  ErrText := P.ErrorText;
  AssertEquals('Output should be empty when only stderr is written', 0, Length(OutText));
  AssertTrue('ErrorText should contain ERR', Pos('ERR', ErrText) > 0);
end;

initialization
  RegisterTest(TTestCase_Pipeline_ErrorText_OnlyErr);
end.

