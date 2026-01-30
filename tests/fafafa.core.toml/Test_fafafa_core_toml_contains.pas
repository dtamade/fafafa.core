{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_contains;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Contains = class(TTestCase)
  published
    procedure Test_Parse_Contains_Key;
  end;

implementation

procedure TTestCase_Contains.Test_Parse_Contains_Key;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a = 1'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc.Root.Contains('a'));
end;

initialization
  RegisterTest(TTestCase_Contains);
end.

