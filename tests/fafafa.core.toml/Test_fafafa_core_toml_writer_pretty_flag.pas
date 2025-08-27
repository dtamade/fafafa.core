{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_pretty_flag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Pretty = class(TTestCase)
  published
    procedure Test_Writer_Pretty_BlankLines_Between_TopSections;
  end;

implementation

procedure TTestCase_Writer_Pretty.Test_Writer_Pretty_BlankLines_Between_TopSections;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  P1, P2: SizeInt;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('foo = 1' + LineEnding + 'a.b.c = 2'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, [twfPretty]));
  // 期望：根级标量块与第一个表头之间留一个空行
  P1 := Pos('foo', S);
  P2 := Pos('[''a'']', StringReplace(S, '[a]', '[''' + 'a' + ''']', [])); // 规避 [] 与正则冲突
  AssertTrue((P1 > 0) and (P2 > 0));
  AssertTrue(Pos(LineEnding + LineEnding + '[a]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Pretty);
end.

