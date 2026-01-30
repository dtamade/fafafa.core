{$CODEPAGE UTF8}
unit test_capture_all_convenience;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_CaptureAll_Convenience = class(TTestCase)
  published
    procedure Test_CaptureAll_Enables_All_Redirects_And_Drain;
  end;

implementation

procedure TTestCase_CaptureAll_Convenience.Test_CaptureAll_Enables_All_Redirects_And_Drain;
var
  B: IProcessBuilder;
  C: IChild;
  OutBuf, ErrBuf: string;
  S: TStringStream;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder
        .Command('cmd.exe')
        .Args(['/c','(echo OUT & echo ERR 1>&2)'])
        .CaptureAll;
  {$ELSE}
  B := NewProcessBuilder
        .Command('/bin/sh')
        .Args(['-c','(echo OUT; echo ERR 1>&2)'])
        .CaptureAll;
  {$ENDIF}

  // Start then manually read from both streams
  C := B.Start;
  CheckTrue(C.WaitForExit(5000), 'Process should exit');

  OutBuf := '';
  ErrBuf := '';

  if Assigned(C.StandardOutput) then
  begin
    S := TStringStream.Create('');
    try
      S.CopyFrom(C.StandardOutput, 0);
      OutBuf := S.DataString;
    finally
      S.Free;
    end;
  end;

  if Assigned(C.StandardError) then
  begin
    S := TStringStream.Create('');
    try
      S.CopyFrom(C.StandardError, 0);
      ErrBuf := S.DataString;
    finally
      S.Free;
    end;
  end;

  // Should have data in at least one of them; commonly both
  CheckTrue((Pos('OUT', OutBuf) > 0) or (Pos('OUT', ErrBuf) > 0), 'Either OUT should be present');
  CheckTrue((Pos('ERR', OutBuf) > 0) or (Pos('ERR', ErrBuf) > 0), 'Either ERR should be present');
end;

initialization
  RegisterTest(TTestCase_CaptureAll_Convenience);
end.

