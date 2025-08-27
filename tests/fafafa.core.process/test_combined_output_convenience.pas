{$CODEPAGE UTF8}
unit test_combined_output_convenience;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_CombinedOutput_Convenience = class(TTestCase)
  published
    procedure Test_CombinedOutput_IsEquivalent_To_StdErrToStdOut_CaptureStdOut_Drain;
  end;

implementation

procedure TTestCase_CombinedOutput_Convenience.Test_CombinedOutput_IsEquivalent_To_StdErrToStdOut_CaptureStdOut_Drain;
var
  B1, B2: IProcessBuilder;
  S1, S2: string;
begin
  {$IFDEF WINDOWS}
  B1 := NewProcessBuilder
          .Command('cmd.exe')
          .Args(['/c','(echo OUT & echo ERR 1>&2)'])
          .StdErrToStdOut
          .CaptureStdOut
          .DrainOutput(True);
  B2 := NewProcessBuilder
          .Command('cmd.exe')
          .Args(['/c','(echo OUT & echo ERR 1>&2)'])
          .CombinedOutput;
  {$ELSE}
  B1 := NewProcessBuilder
          .Command('/bin/sh')
          .Args(['-c','(echo OUT; echo ERR 1>&2)'])
          .StdErrToStdOut
          .CaptureStdOut
          .DrainOutput(True);
  B2 := NewProcessBuilder
          .Command('/bin/sh')
          .Args(['-c','(echo OUT; echo ERR 1>&2)'])
          .CombinedOutput;
  {$ENDIF}

  S1 := B1.Output;
  S2 := B2.Output;
  AssertTrue('OUT should appear in S1', Pos('OUT', S1) > 0);
  AssertTrue('ERR should appear in S1', Pos('ERR', S1) > 0);
  AssertTrue('OUT should appear in S2', Pos('OUT', S2) > 0);
  AssertTrue('ERR should appear in S2', Pos('ERR', S2) > 0);
end;

initialization
  RegisterTest(TTestCase_CombinedOutput_Convenience);
end.

