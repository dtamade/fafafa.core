unit test_toml_string_number_underscores_invalid;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlNumberUnderscoreInvalidTests;

implementation

type
  TTomlNumberUnderscoreInvalidCase = class(TTestCase)
  published
    procedure Test_Int_Underscore_Start_End_Invalid;
    procedure Test_Int_Underscore_Double_Invalid;
    procedure Test_Float_Underscore_After_Dot_Invalid;
    procedure Test_Float_Underscore_Exp_Invalid;
  end;

procedure TTomlNumberUnderscoreInvalidCase.Test_Int_Underscore_Start_End_Invalid;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  Txt := 'a = _1'; Err.Clear; AssertFalse(Parse(Txt, Doc, Err)); AssertTrue(Err.HasError);
  Txt := 'a = 1_'; Err.Clear; AssertFalse(Parse(Txt, Doc, Err)); AssertTrue(Err.HasError);
end;

procedure TTomlNumberUnderscoreInvalidCase.Test_Int_Underscore_Double_Invalid;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  Txt := 'a = 1__2'; Err.Clear; AssertFalse(Parse(Txt, Doc, Err)); AssertTrue(Err.HasError);
end;

procedure TTomlNumberUnderscoreInvalidCase.Test_Float_Underscore_After_Dot_Invalid;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  Txt := 'a = 1._2'; Err.Clear; AssertFalse(Parse(Txt, Doc, Err)); AssertTrue(Err.HasError);
end;

procedure TTomlNumberUnderscoreInvalidCase.Test_Float_Underscore_Exp_Invalid;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  Txt := 'a = 1e_10'; Err.Clear; AssertFalse(Parse(Txt, Doc, Err)); AssertTrue(Err.HasError);
  // 正例：科学计数法无下划线，确保仍能读为浮点而非误判
  Txt := 'a = 1e10'; Err.Clear; AssertTrue(Parse(Txt, Doc, Err));
end;

procedure RegisterTomlNumberUnderscoreInvalidTests;
begin
  RegisterTest('toml-number-underscores-invalid', TTomlNumberUnderscoreInvalidCase);
end;

end.

