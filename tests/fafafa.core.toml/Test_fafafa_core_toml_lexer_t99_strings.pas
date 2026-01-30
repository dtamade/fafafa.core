{$CODEPAGE UTF8}
{$DEFINE FAFAFA_TOML_BACKEND_T99_LEXER}  // unit-local enable for t99 lexer tests

{$IFDEF FAFAFA_TOML_BACKEND_T99_LEXER}
unit Test_fafafa_core_toml_lexer_t99_strings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml.lexer.t99;

type
  TTestCase_T99_Lexer_Strings = class(TTestCase)
  published
    procedure Test_Tokenize_BasicString_uXXXX_Positive;
    procedure Test_Tokenize_BasicString_UXXXXXXXX_Positive;
    procedure Test_Tokenize_BasicString_Invalid_u_Short;
    procedure Test_Tokenize_BasicString_Invalid_U_OutOfRange;
    procedure Test_ParseBasicString_API_Positive;
    procedure Test_ParseLiteralString_API_Positive;
  end;

implementation

procedure TTestCase_T99_Lexer_Strings.Test_Tokenize_BasicString_uXXXX_Positive;
var L: TTomlLexer; Tok: TTomlToken;
begin
  L.Init('"\u0061"');
  AssertTrue(NextToken(L, Tok));
  AssertEquals(Ord(ttString), Ord(Tok.Kind));
  AssertEquals('a', String(Tok.Text));
end;

procedure TTestCase_T99_Lexer_Strings.Test_Tokenize_BasicString_UXXXXXXXX_Positive;
var L: TTomlLexer; Tok: TTomlToken;
begin
  L.Init('"\U00000041"');
  AssertTrue(NextToken(L, Tok));
  AssertEquals(Ord(ttString), Ord(Tok.Kind));
  AssertEquals('A', String(Tok.Text));
end;

procedure TTestCase_T99_Lexer_Strings.Test_Tokenize_BasicString_Invalid_u_Short;
var L: TTomlLexer; Tok: TTomlToken;
begin
  L.Init('"a\u12"');
  AssertTrue(NextToken(L, Tok));
  AssertEquals(Ord(ttError), Ord(Tok.Kind));
end;

procedure TTestCase_T99_Lexer_Strings.Test_Tokenize_BasicString_Invalid_U_OutOfRange;
var L: TTomlLexer; Tok: TTomlToken;
begin
  L.Init('"a\U110000"');
  AssertTrue(NextToken(L, Tok));
  AssertEquals(Ord(ttError), Ord(Tok.Kind));
end;

procedure TTestCase_T99_Lexer_Strings.Test_ParseBasicString_API_Positive;
var P, PEnd: PChar; S: String;
    src: RawByteString;
begin
  src := '"hello\nworld"';
  P := PChar(src); PEnd := PChar(PtrUInt(P) + Length(src));
  AssertTrue(T99_ParseBasicString(P, PEnd, S));
  AssertEquals('hello'+LineEnding+'world', S);
end;

procedure TTestCase_T99_Lexer_Strings.Test_ParseLiteralString_API_Positive;
var P, PEnd: PChar; S: String;
    src: RawByteString;
begin
  src := '''abc''';
  P := PChar(src); PEnd := PChar(PtrUInt(P) + Length(src));
  AssertTrue(T99_ParseLiteralString(P, PEnd, S));
  AssertEquals('abc', S);
end;

initialization
  RegisterTest(TTestCase_T99_Lexer_Strings);
end.



{$ELSE}
unit Test_fafafa_core_toml_lexer_t99_strings;

{$mode objfpc}{$H+}

interface
implementation
end.
{$ENDIF}
