{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_parse_router_fallback;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Parse_Router_Fallback = class(TTestCase)
  published
    procedure Test_Default_Parse_Falls_Back_To_V1_For_Unicode_String;
    procedure Test_Default_Parse_Falls_Back_To_V1_For_Unicode_Key;
    procedure Test_Default_Parse_Keeps_Invalid_Unicode_Failure;
  end;

implementation

procedure TTestCase_Parse_Router_Fallback.Test_Default_Parse_Falls_Back_To_V1_For_Unicode_String;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  LText: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('s = "a\u0061b"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  LText := String(ToToml(LDoc, []));
  AssertTrue(Pos('s = "aab"', LText) > 0);
end;

procedure TTestCase_Parse_Router_Fallback.Test_Default_Parse_Falls_Back_To_V1_For_Unicode_Key;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('"\u0061" = 1'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc.Root.Contains('a'));
end;

procedure TTestCase_Parse_Router_Fallback.Test_Default_Parse_Keeps_Invalid_Unicode_Failure;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertFalse(Parse(RawByteString('s = "\u12G4"'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

initialization
  RegisterTest(TTestCase_Parse_Router_Fallback);
end.
