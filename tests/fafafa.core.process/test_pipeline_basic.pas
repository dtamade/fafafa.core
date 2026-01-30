unit test_pipeline_basic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process, fafafa.core.pipeline;

type
  TTestPipelineBasic = class(TTestCase)
  published
    procedure EchoThenFilter_ShouldSucceed;
    procedure ThreeStages_ShouldPropagateEOF;
  end;

implementation

procedure TTestPipelineBasic.EchoThenFilter_ShouldSucceed;
var
  P: IPipeline;
begin
  {$IFDEF WINDOWS}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','hello']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','hello']))
    .CaptureOutput
    .Start;
  {$ELSE}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('/bin/echo').Args(['hello']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['hello']))
    .CaptureOutput
    .Start;
  {$ENDIF}

  AssertTrue('pipeline should finish', P.WaitForExit(5000));
  AssertTrue('pipeline should success', P.Success);
  // 输出在不同平台/控制台会有换行差异，放宽为包含
  AssertTrue('output should contain hello', Pos('hello', P.Output) > 0);
end;

procedure TTestPipelineBasic.ThreeStages_ShouldPropagateEOF;
var
  P: IPipeline;
begin
  {$IFDEF WINDOWS}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','hello']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','hello']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','h']))
    .CaptureOutput
    .Start;
  {$ELSE}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('/bin/echo').Args(['hello']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['hello']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['h']))
    .CaptureOutput
    .Start;
  {$ENDIF}

  AssertTrue('pipeline should wait', P.WaitForExit);
  AssertTrue('pipeline should success', P.Success);
  AssertTrue('output should contain hello', Pos('hello', P.Output) > 0);
end;

initialization
  RegisterTest(TTestPipelineBasic);

end.

