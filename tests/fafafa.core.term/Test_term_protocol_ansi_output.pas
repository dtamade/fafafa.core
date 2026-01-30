{$CODEPAGE UTF8}
unit Test_term_protocol_ansi_output;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term, fafafa.core.term.ansi;

type
  TTestCase_ProtocolAnsiOutput = class(TTestCase)
  published
    procedure Test_Focus_Enable_Disable_Writes_ANSI;
    procedure Test_Paste_Enable_Disable_Writes_ANSI;
    procedure Test_Sync_Enable_Disable_Writes_ANSI;
    procedure Test_No_ANSI_Compat_No_Write;
  end;

implementation

var
  gBuf: RawByteString;

procedure ClearBuf; inline;
begin
  gBuf := '';
end;

procedure FakeWrite(aTerm: pterm_t; const aData: pchar; aLen: Integer);
begin
  if (aLen > 0) and (aData <> nil) then
    gBuf := gBuf + Copy(AnsiString(aData), 1, aLen);
end;

function NewFakeAnsiTerm: pterm_t;
begin
  New(Result);
  FillChar(Result^, SizeOf(term_t), 0);
  Result^.name := 'fake-ansi';
  Result^.compatibles := [tc_ansi];
  Result^.write := @FakeWrite;
end;

function NewFakeNoAnsiTerm: pterm_t;
begin
  New(Result);
  FillChar(Result^, SizeOf(term_t), 0);
  Result^.name := 'fake-noansi';
  Result^.compatibles := [];
  Result^.write := @FakeWrite; // should not be called for these APIs
end;

procedure FreeFakeTerm(var T: pterm_t);
begin
  if T <> nil then begin Dispose(T); T := nil; end;
end;

procedure TTestCase_ProtocolAnsiOutput.Test_Focus_Enable_Disable_Writes_ANSI;
var T: pterm_t;
begin
  T := NewFakeAnsiTerm;
  try
    ClearBuf;
    fpcunit.TAssert.AssertTrue(term_focus_enable(T, True));
    fpcunit.TAssert.AssertEquals(UTF8Encode(ANSI_FOCUS_ENABLE), UTF8Encode(string(gBuf)));

    ClearBuf;
    fpcunit.TAssert.AssertTrue(term_focus_enable(T, False));
    fpcunit.TAssert.AssertEquals(UTF8Encode(ANSI_FOCUS_DISABLE), UTF8Encode(string(gBuf)));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure TTestCase_ProtocolAnsiOutput.Test_Paste_Enable_Disable_Writes_ANSI;
var T: pterm_t;
begin
  T := NewFakeAnsiTerm;
  try
    ClearBuf;
    fpcunit.TAssert.AssertTrue(term_paste_bracket_enable(T, True));
    fpcunit.TAssert.AssertEquals(UTF8Encode(ANSI_BRACKETED_PASTE_ENABLE), UTF8Encode(string(gBuf)));

    ClearBuf;
    fpcunit.TAssert.AssertTrue(term_paste_bracket_enable(T, False));
    fpcunit.TAssert.AssertEquals(UTF8Encode(ANSI_BRACKETED_PASTE_DISABLE), UTF8Encode(string(gBuf)));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure TTestCase_ProtocolAnsiOutput.Test_Sync_Enable_Disable_Writes_ANSI;
var T: pterm_t;
begin
  T := NewFakeAnsiTerm;
  try
    ClearBuf;
    fpcunit.TAssert.AssertTrue(term_sync_update_enable(T, True));
    fpcunit.TAssert.AssertEquals(UTF8Encode(ANSI_SYNC_UPDATE_ENABLE), UTF8Encode(string(gBuf)));

    ClearBuf;
    fpcunit.TAssert.AssertTrue(term_sync_update_enable(T, False));
    fpcunit.TAssert.AssertEquals(UTF8Encode(ANSI_SYNC_UPDATE_DISABLE), UTF8Encode(string(gBuf)));
  finally
    FreeFakeTerm(T);
  end;
end;

procedure TTestCase_ProtocolAnsiOutput.Test_No_ANSI_Compat_No_Write;
var T: pterm_t;
begin
  T := NewFakeNoAnsiTerm;
  try
    ClearBuf;
    fpcunit.TAssert.AssertFalse(term_focus_enable(T, True));
    fpcunit.TAssert.AssertEquals('', string(gBuf));

    ClearBuf;
    fpcunit.TAssert.AssertFalse(term_paste_bracket_enable(T, True));
    fpcunit.TAssert.AssertEquals('', string(gBuf));

    ClearBuf;
    fpcunit.TAssert.AssertFalse(term_sync_update_enable(T, True));
    fpcunit.TAssert.AssertEquals('', string(gBuf));
  finally
    FreeFakeTerm(T);
  end;
end;

initialization
  RegisterTest(TTestCase_ProtocolAnsiOutput);
end.

