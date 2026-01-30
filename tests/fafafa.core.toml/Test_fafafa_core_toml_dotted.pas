{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_dotted;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Dotted = class(TTestCase)
  published
    procedure Test_Parse_DottedKeys_Smoke;
  end;

implementation

procedure TTestCase_Dotted.Test_Parse_DottedKeys_Smoke;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = "x"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc.Root.Contains('a'));
end;

initialization
  RegisterTest(TTestCase_Dotted);
end.

