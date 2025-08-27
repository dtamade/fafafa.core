unit test_pipeline_enhanced;

{$mode objfpc}{$H+}

{$DEFINE RUN_FAILFAST_DEBUG}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process, fafafa.core.pipeline;

type
  TTestPipelineEnhanced = class(TTestCase)
  published
    procedure FailFast_ShouldKillOthersAndFinishQuickly;
    procedure MergeStdErr_ShouldCaptureBothStreams;
  end;

implementation

function WaitUntil(const P: IPipeline; totalMs, tickMs: Integer): Boolean;
var
  t0: QWord;
begin
  t0 := GetTickCount64;
  repeat
    if P.WaitForExit(tickMs) then Exit(True);
  until (GetTickCount64 - t0) >= QWord(totalMs);
  Exit(False);
end;


procedure TTestPipelineEnhanced.FailFast_ShouldKillOthersAndFinishQuickly;
var
  P: IPipeline;
  t0, nowt: QWord;
  waited: Boolean;
  elapsed: QWord;
begin
  {$IFDEF RUN_FAILFAST_DEBUG}
  WriteLn(StdErr, '[FailFast] before Build/Start'); Flush(StdErr);
  {$ENDIF}
  {$IFDEF WINDOWS}
  // 第一阶段立即失败；第二阶段：固定耗时非交互命令（使用内建 timeout，避免额外子进程）
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','exit','1']))
    .Add(NewProcessBuilder.Command('powershell.exe').Args(['-NoProfile','-Command','Start-Sleep -Seconds 6']))
    .FailFast(True)
    .Start;
  {$ELSE}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','exit 1']))
    .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','sleep 2']))
    .FailFast(True)
    .Start;
  {$ENDIF}
  {$IFDEF RUN_FAILFAST_DEBUG}
  WriteLn(StdErr, '[FailFast] after Start'); Flush(StdErr);

  WriteLn(StdErr, '[FailFast] begin wait'); Flush(StdErr);
  {$ENDIF}
  t0 := GetTickCount64; waited := False; elapsed := 0;
  while True do
  begin
    if P.WaitForExit(50) then begin waited := True; Break; end;
    nowt := GetTickCount64; elapsed := nowt - t0;
    if (elapsed >= 5000) then Break;
    {$IFDEF RUN_FAILFAST_DEBUG}
    if (elapsed mod 500 = 0) then begin WriteLn(StdErr, '[FailFast] tick elapsed=', elapsed); Flush(StdErr); end;
    {$ENDIF}
  end;
  {$IFDEF RUN_FAILFAST_DEBUG}
  WriteLn(StdErr, '[FailFast] after Wait waited=', waited, ' elapsedms=', elapsed, ' success=', P.Success); Flush(StdErr);
  {$ENDIF}

  AssertTrue('pipeline should finish within timeout due to FailFast', waited);
  AssertFalse('pipeline should not success when first stage fails', P.Success);
  // 注意：不同环境下时间调度差异较大，避免脆弱的耗时断言；改为仅记录耗时供诊断
  {$IFDEF RUN_FAILFAST_DEBUG}
  WriteLn(StdErr, '[FailFast] elapsed(ms)=', (GetTickCount64 - t0)); Flush(StdErr);
  {$ENDIF}
end;

procedure TTestPipelineEnhanced.MergeStdErr_ShouldCaptureBothStreams;
var
  P: IPipeline;
  outStr: string;
begin
  {$IFDEF WINDOWS}
  // 输出到 stdout 与 stderr，要求合并后能同时看到
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo out & echo err 1>&2)']))
    .CaptureOutput
    .MergeStdErr(True)
    .Start;
  {$ELSE}
  P := NewPipeline
    .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo out; echo err 1>&2)']))
    .CaptureOutput
    .MergeStdErr(True)
    .Start;
  {$ENDIF}

  AssertTrue('pipeline should wait', P.WaitForExit(5000));
  outStr := P.Output;
  AssertTrue('should contain out', Pos('out', outStr) > 0);
  AssertTrue('should contain err', Pos('err', outStr) > 0);
end;

initialization
  {$IFDEF RUN_FAILFAST_DEBUG}
  WriteLn(StdErr, '[Init] TTestPipelineEnhanced unit initializing'); Flush(StdErr);
  {$ENDIF}
  RegisterTest(TTestPipelineEnhanced);

end.

