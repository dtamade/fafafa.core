{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_arrays_nested_writer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Arrays_Nested_Writer = class(TTestCase)
  published
    procedure Test_Write_Nested_Arrays_Smoke;
    procedure Test_Write_Nested_Arrays_Mixed_Scalars;
  end;

implementation

procedure TTestCase_Toml_Arrays_Nested_Writer.Test_Write_Nested_Arrays_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
  S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('m = [[1, 2], [3, 4]]'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  // debug dump
  ForceDirectories('tests/fafafa.core.toml/bin');
  with TStringList.Create do try Text := S; SaveToFile('tests/fafafa.core.toml/bin/_debug_nested_arrays_1.toml'); finally Free; end;
  AssertTrue(Pos('m = [[1, 2], [3, 4]]', S) > 0);
end;

procedure TTestCase_Toml_Arrays_Nested_Writer.Test_Write_Nested_Arrays_Mixed_Scalars;
var
  D: ITomlDocument;
  E: TTomlError;
  S: String;
begin
  E.Clear;
  AssertTrue(Parse(RawByteString('a = [[1, 2.0], [true, "x"]]'), D, E));
  AssertFalse(E.HasError);
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  // debug dump
  ForceDirectories('tests/fafafa.core.toml/bin');
  with TStringList.Create do try Text := S; SaveToFile('tests/fafafa.core.toml/bin/_debug_nested_arrays_2.toml'); finally Free; end;

  // 允许浮点标准化后含 .0；顺序与结构保持
  AssertTrue(Pos('a = [[1, 2.0], [true, "x"]]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Toml_Arrays_Nested_Writer);
end.

