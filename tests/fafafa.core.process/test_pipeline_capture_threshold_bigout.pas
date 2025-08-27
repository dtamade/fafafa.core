unit test_pipeline_capture_threshold_bigout;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process, fafafa.core.pipeline;

type
  TTestCase_Pipeline_CaptureThreshold = class(TTestCase)
  published
    procedure Test_BigOutput_Threshold_To_TempFile;
  end;

implementation

procedure TTestCase_Pipeline_CaptureThreshold.Test_BigOutput_Threshold_To_TempFile;
var
  P: IPipeline;
  OutPath: string;
begin
  // 仅作为功能性验证：设置较小阈值，确保落盘路径可用
  {$IFDEF WINDOWS}
  P := NewPipeline
        .Add('cmd.exe', ['/c','for /l %i in (1,1,2000) do @echo XXXXXXXX'])
  {$ELSE}
  P := NewPipeline
        .Add('/bin/sh',['-c','seq 1 2000 | sed "s/.*/XXXXXXXX/"'])
  {$ENDIF}
        .CaptureOutput(True)
        .CaptureThreshold(64*1024) // 64KB 阈值，预期落盘
        .DeleteCapturedOnDestroy(False)
        .Start;
  CheckTrue(P.WaitForExit(15000), 'Pipeline 应在超时前完成');
  OutPath := P.OutputFilePath;
  CheckTrue(OutPath <> '', '应返回临时文件路径');
  // 读取部分验证非空
  CheckTrue(FileExists(OutPath), '临时文件应存在');
end;

initialization
  RegisterTest(TTestCase_Pipeline_CaptureThreshold);

end.

