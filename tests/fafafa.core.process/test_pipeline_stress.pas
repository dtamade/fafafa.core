unit test_pipeline_stress;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process, fafafa.core.pipeline;

type
  TTestPipelineStress = class(TTestCase)
  published
    procedure LargeOutput_ShouldNotDeadlock_AndFinish;
    procedure LongChain_ShouldPropagate_AndFinish;
  end;

implementation

procedure TTestPipelineStress.LargeOutput_ShouldNotDeadlock_AndFinish;
var
  P: IPipeline;
  waited: Boolean;
begin
  {$IFDEF WINDOWS}
  // 约 2MB 输出（20k 行，每行 ~100 字符）
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c',
      'for /L %i in (1,1,5000) do @echo 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','0123']))
    .CaptureOutput
    .Start;
  {$ELSE}
  // shell 生成较大输出
  P := NewPipeline
    .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','yes 0123456789abcdef | head -n 100000']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['0123']))
    .CaptureOutput
    .Start;
  {$ENDIF}

  waited := P.WaitForExit(30000);
  AssertTrue('large output pipeline should finish within timeout', waited);
  AssertTrue('should success', P.Success);
  AssertTrue('output should contain marker', Pos('01234567', P.Output) > 0);
end;

procedure TTestPipelineStress.LongChain_ShouldPropagate_AndFinish;
var
  P: IPipeline;
  waited: Boolean;
begin
  {$IFDEF WINDOWS}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','hello world']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','hello']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','world']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','or']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','ld']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','w']))
    .CaptureOutput
    .Start;
  {$ELSE}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('/bin/echo').Args(['hello world']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['hello']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['world']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['or']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['ld']))
    .Add(NewProcessBuilder.Command('/bin/grep').Args(['w']))
    .CaptureOutput
    .Start;
  {$ENDIF}

  waited := P.WaitForExit(15000);
  AssertTrue('long chain should finish', waited);
  AssertTrue('should success', P.Success);
  AssertTrue('output should equal hello world', Pos('hello world', P.Output) > 0);
end;

initialization
  {$IFDEF RUN_STRESS}
  RegisterTest(TTestPipelineStress);
  {$ENDIF}

end.

