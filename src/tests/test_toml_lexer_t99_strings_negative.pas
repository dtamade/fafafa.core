unit test_toml_lexer_t99_strings_negative;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml.lexer.t99;

procedure RegisterTomlLexerT99StringNegativeTests;

implementation

type
  TTomlLexerT99StringNegCase = class(TTestCase)
  private
    function FirstErrorToken(const Input: RawByteString; out Tok: TTomlToken): Boolean;
  published
    procedure Test_Multiline_Basic_Unterminated;
    procedure Test_Literal_Multiline_Unterminated;
    procedure Test_Unicode_Escape_Invalid;
    procedure Test_Unicode_Escape_TooShort4;
    procedure Test_Unicode_Escape_TooShort8;
    procedure Test_Unicode_Escape_OutOfRange;
    procedure Test_Unicode_Escape_Surrogate;
    procedure Test_Multiline_Continuation_Invalid;
  end;

function TTomlLexerT99StringNegCase.FirstErrorToken(const Input: RawByteString; out Tok: TTomlToken): Boolean;
var
  L: TTomlLexer;
begin
  InitLexer(L, Input);
  Result := False;
  while NextToken(L, Tok) do
  begin
    if Tok.Kind = ttError then Exit(True);
    if Tok.Kind = ttEOF then Exit(False);
  end;
end;

procedure TTomlLexerT99StringNegCase.Test_Multiline_Basic_Unterminated;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString('"""hello');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('stringml_unterminated', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Literal_Multiline_Unterminated;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString(#39 + #39 + #39 + 'abc');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('literalml_unterminated', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Unicode_Escape_Invalid;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString('"\u0G12"');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('unicode_escape_invalid', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Unicode_Escape_TooShort4;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString('"\u0A"');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('unicode_escape_invalid', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Unicode_Escape_TooShort8;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString('"\U00010F"');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('unicode_escape_invalid', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Unicode_Escape_OutOfRange;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString('"\U110000"');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('unicode_escape_invalid', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Unicode_Escape_Surrogate;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  Inp := RawByteString('"\uD800"');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
  AssertEquals('unicode_escape_invalid', String(Tok.Text));
end;

procedure TTomlLexerT99StringNegCase.Test_Multiline_Continuation_Invalid;
var Inp: RawByteString; Tok: TTomlToken; Ok: Boolean;
begin
  // 行尾反斜杠后面不是换行：非法
  Inp := RawByteString('"""a\x"""');
  Ok := FirstErrorToken(Inp, Tok);
  AssertTrue(Ok);
end;

procedure RegisterTomlLexerT99StringNegativeTests;
begin
  RegisterTest('toml-lexer-t99-strings-negative', TTomlLexerT99StringNegCase);
end;

end.

