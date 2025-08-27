{$CODEPAGE UTF8}
unit test_pipeline_group_stress;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, fafafa.core.process, fafafa.core.pipeline;

type
  TTestPipelineGroupStress = class(TTestCase)
  published
    procedure Echo_Filter_Capture_WithGroup_And_Timeout;
  end;

implementation

procedure TTestPipelineGroupStress.Echo_Filter_Capture_WithGroup_And_Timeout;
var
  G: IProcessGroup;
  P: IPipeline;
  B: IPipelineBuilder;
  OutS: string;
begin
  G := NewProcessGroup; // 未启用特性时为 nil

  // 构建三阶段：echo → findstr → findstr，最后阶段捕获输出
  B := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','HELLO WORLD']))
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','HELLO']))
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','WORLD']))
        .CaptureOutput(True)
        .FailFast(True)
        .MergeStdErr(False);

  // 为末端阶段设置超时/排水，提升稳定性
  // 注意：Pipeline 内部已经 CaptureStdOut/Redirect，此处示例性地对末端 Builder 配置参数
  // 这里直接 Start，Pipeline 会对每个阶段 Build+Start
  P := B.Start;

  // 等待最多 3s
  AssertTrue('pipeline should finish in time', P.WaitForExit(3000));
  AssertTrue('pipeline success', P.Success);
  OutS := P.Output;
  AssertTrue('should contain HELLO WORLD', Pos('HELLO', OutS) > 0);
  AssertTrue('should contain WORLD', Pos('WORLD', OutS) > 0);

  // 若启用组：对成组进程作并发压力时可调用 G.TerminateGroup 进行快速回收（此处不触发）
  if Assigned(G) then ;
end;

initialization
  RegisterTest(TTestPipelineGroupStress);
end.

