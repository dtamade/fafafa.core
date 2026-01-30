{$CODEPAGE UTF8}
unit test_combined_output;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_CombinedOutput = class(TTestCase)
  published
    procedure Test_StdErr_To_StdOut_Merge;
  end;

implementation

procedure TTestCase_CombinedOutput.Test_StdErr_To_StdOut_Merge;
var
  B: IProcessBuilder;
  S: string;
begin
  // 将 stderr 合流到 stdout，并捕获输出，验证两者同时出现
  {$IFDEF WINDOWS}
  B := NewProcessBuilder
        .Command('cmd.exe')
        .Args(['/c','(echo OUT & echo ERR 1>&2)'])
        .StdErrToStdOut
        .CaptureStdOut;
  {$ELSE}
  B := NewProcessBuilder
        .Command('/bin/sh')
        .Args(['-c','(echo OUT; echo ERR 1>&2)'])
        .StdErrToStdOut
        .CaptureStdOut;
  {$ENDIF}

  S := B.Output; // 便捷方法：内部 Build+Start+Wait 并读取 stdout
  AssertTrue('should contain OUT', Pos('OUT', S) > 0);
  AssertTrue('should contain ERR', Pos('ERR', S) > 0);
end;

initialization
  RegisterTest(TTestCase_CombinedOutput);
end.

