{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_dotted2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Dotted2 = class(TTestCase)
  published
    procedure Test_Parse_DottedKeys_KeyCount;
  end;

implementation

procedure TTestCase_Dotted2.Test_Parse_DottedKeys_KeyCount;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  LRoot: ITomlTable;
  LKey0: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = "x"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  LRoot := LDoc.Root;
  AssertNotNull(LRoot);
  AssertTrue(LRoot.KeyCount > 0);
  LKey0 := LRoot.KeyAt(0);
  AssertEquals('a', LKey0);
end;

initialization
  RegisterTest(TTestCase_Dotted2);
end.

