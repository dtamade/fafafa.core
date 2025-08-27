{$CODEPAGE UTF8}
unit Test_term_output_buffering;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermOutputBuffering = class(TTestCase)
  private
    class var gBuf: RawByteString;
    class procedure ClearBuf; static;
    class procedure FakeWrite(aTerm: pterm_t; const aData: pchar; aLen: Integer); static;
    class function NewFakeTerm: pterm_t; static;
    class procedure FreeFakeTerm(var T: pterm_t); static;
  published
    procedure Test_Queue_Then_Flush_WritesOnce;
    procedure Test_Flush_Idempotent_When_Empty;
  end;

implementation

class procedure TTestCase_TermOutputBuffering.ClearBuf;
begin
  gBuf := '';
end;

class procedure TTestCase_TermOutputBuffering.FakeWrite(aTerm: pterm_t; const aData: pchar; aLen: Integer);
begin
  if (aLen > 0) and (aData <> nil) then
    gBuf := gBuf + Copy(AnsiString(aData), 1, aLen);
end;

class function TTestCase_TermOutputBuffering.NewFakeTerm: pterm_t;
begin
  New(Result);
  FillChar(Result^, SizeOf(term_t), 0);
  Result^.name := 'fake-out';
  Result^.compatibles := [tc_ansi];
  Result^.write := @FakeWrite;
end;

class procedure TTestCase_TermOutputBuffering.FreeFakeTerm(var T: pterm_t);
begin
  if T <> nil then begin Dispose(T); T := nil; end;
end;

procedure TTestCase_TermOutputBuffering.Test_Queue_Then_Flush_WritesOnce;
var T: pterm_t;
begin
  T := NewFakeTerm;
  try
    ClearBuf;
    term_set_default(T); // 使全局 term_write 走 FakeWrite
    term_queue('hello');
    term_queue(', world');
    CheckEquals('', string(gBuf), 'no write before flush');
    term_flush;
    CheckEquals('hello, world', string(gBuf), 'flush writes aggregated content');
  finally
    FreeFakeTerm(T);
    term_set_default(nil);
  end;
end;

procedure TTestCase_TermOutputBuffering.Test_Flush_Idempotent_When_Empty;
var T: pterm_t;
begin
  T := NewFakeTerm;
  try
    ClearBuf;
    term_set_default(T);
    term_flush; // empty flush
    CheckEquals('', string(gBuf));
    term_flush; // flush again, still empty
    CheckEquals('', string(gBuf));
  finally
    FreeFakeTerm(T);
    term_set_default(nil);
  end;
end;

initialization
  RegisterTest(TTestCase_TermOutputBuffering);
end.

