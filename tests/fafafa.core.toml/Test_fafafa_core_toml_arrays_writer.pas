{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_arrays_writer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Arrays_Writer = class(TTestCase)
  published
    procedure Test_Write_Int_Array_Smoke;
  end;

implementation

procedure TTestCase_Toml_Arrays_Writer.Test_Write_Int_Array_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
  S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('nums = [1, 2, 3]'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  AssertTrue(Pos('nums = [1, 2, 3]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Toml_Arrays_Writer);
end.

