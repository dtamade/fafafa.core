{$CODEPAGE UTF8}
unit test_checked_exit_only;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_CheckedExitOnly = class(TTestCase)
  published
    procedure StatusChecked_ShouldRaise_OnNonZero;
    procedure OutputChecked_ShouldRaise_OnNonZero;
  end;

implementation

procedure TTestCase_CheckedExitOnly.StatusChecked_ShouldRaise_OnNonZero;
var
  B: IProcessBuilder;
  RaisedErr: Boolean = False;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','cmd','/c','exit','7']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','exit 7']);
  {$ENDIF}
  try
    B.StatusChecked;
  except
    on E: EProcessExitError do begin RaisedErr := True; AssertEquals(7, E.ExitCode); end;
  end;
  AssertTrue('EProcessExitError expected on non-zero exit', RaisedErr);
end;

procedure TTestCase_CheckedExitOnly.OutputChecked_ShouldRaise_OnNonZero;
var
  B: IProcessBuilder;
  RaisedErr: Boolean = False;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','cmd','/c','exit','9']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','exit 9']);
  {$ENDIF}
  try
    B.OutputChecked;
  except
    on E: EProcessExitError do begin RaisedErr := True; AssertEquals(9, E.ExitCode); end;
  end;
  AssertTrue('EProcessExitError expected on non-zero exit', RaisedErr);
end;

initialization
  RegisterTest(TTestCase_CheckedExitOnly);
end.

