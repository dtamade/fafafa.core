unit test_toml_writer_multiline;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterMultilineTests;

implementation

type
  TTomlWriterMultilineCase = class(TTestCase)
  published
    procedure Test_Writer_Multiline_String_Emits_Triple_Quotes;
  end;

procedure TTomlWriterMultilineCase.Test_Writer_Multiline_String_Emits_Triple_Quotes;
var
  B: ITomlBuilder; D: ITomlDocument; S: String;
begin
  B := NewDoc;
  B.BeginTable('app').PutStr('desc', 'hello' + LineEnding + 'world').EndTable;
  D := B.Build;
  S := String(ToToml(D, []));
  AssertTrue(Pos('desc = """hello' + LineEnding + 'world"""', S) > 0);
end;

procedure RegisterTomlWriterMultilineTests;
begin
  RegisterTest('toml-writer-multiline', TTomlWriterMultilineCase);
end;

end.

