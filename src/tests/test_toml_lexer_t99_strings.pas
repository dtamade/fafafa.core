unit test_toml_lexer_t99_strings;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml.lexer.t99;

procedure RegisterTomlLexerT99StringTests;

implementation

type
  TTomlLexerT99StringCase = class(TTestCase)
  private
    function NormEOL(const S: String): String;
    function FirstStringToken(const Input: RawByteString; out TokKind: TTomlTokenKind): String;
  published
    procedure Test_Basic_Multiline_Trim_First_Newline;
    procedure Test_Basic_Multiline_With_Escapes;
    procedure Test_Literal_Multiline_No_Escape;
    procedure Test_Basic_Multiline_Line_Continuation;
  end;

function TTomlLexerT99StringCase.NormEOL(const S: String): String;
begin
  Result := StringReplace(StringReplace(S, #13#10, #10, [rfReplaceAll]), #13, #10, [rfReplaceAll]);
end;

function TTomlLexerT99StringCase.FirstStringToken(const Input: RawByteString; out TokKind: TTomlTokenKind): String;
var
  L: TTomlLexer; Tok: TTomlToken;
begin
  Result := '';
  TokKind := ttEOF;
  InitLexer(L, Input);
  while NextToken(L, Tok) do
  begin
    if (Tok.Kind = ttString) or (Tok.Kind = ttLiteralString) then
    begin
      TokKind := Tok.Kind;
      Result := String(Tok.Text);
      Exit;
    end;
    if Tok.Kind = ttEOF then Exit;
  end;
end;

procedure TTomlLexerT99StringCase.Test_Basic_Multiline_Trim_First_Newline;
var
  K: TTomlTokenKind; S: String; Inp: RawByteString;
begin
  Inp := RawByteString('"""' + LineEnding + 'hello' + LineEnding + 'world"""');
  S := FirstStringToken(Inp, K);
  AssertEquals(Ord(ttString), Ord(K));
  AssertEquals(NormEOL('hello' + LineEnding + 'world'), NormEOL(S));
end;

procedure TTomlLexerT99StringCase.Test_Basic_Multiline_With_Escapes;
var K: TTomlTokenKind; S: String; Inp: RawByteString;
begin
  Inp := RawByteString('"""hello\nworld\t!"""');
  S := FirstStringToken(Inp, K);
  AssertEquals(Ord(ttString), Ord(K));
  AssertEquals(NormEOL('hello' + LineEnding + 'world' + #9 + '!'), NormEOL(S));
end;

procedure TTomlLexerT99StringCase.Test_Literal_Multiline_No_Escape;
var K: TTomlTokenKind; S: String; Inp: RawByteString;
begin
  Inp := RawByteString('"""' + LineEnding + 'C:\\a\\b\\n' + LineEnding + 'x"""');
  S := FirstStringToken(Inp, K);
  AssertEquals(Ord(ttLiteralString), Ord(K));
  AssertEquals(NormEOL('C:\\a\\b\\n' + LineEnding + 'x'), NormEOL(S));
end;

procedure TTomlLexerT99StringCase.Test_Basic_Multiline_Line_Continuation;
var K: TTomlTokenKind; S: String; Inp: RawByteString;
begin
  // 行尾反斜杠 + 行终止：拼接相邻行并修剪下一行起始空白
  Inp := RawByteString('"""hello\  ' + LineEnding + '   world"""');
  S := FirstStringToken(Inp, K);
  AssertEquals(Ord(ttString), Ord(K));
  AssertEquals('helloworld', S);
end;

procedure RegisterTomlLexerT99StringTests;
begin
  RegisterTest('toml-lexer-t99-strings', TTomlLexerT99StringCase);
end;

end.

