unit test_toml_writer_flags;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterFlagTests;

implementation

type
  TTomlWriterFlagCase = class(TTestCase)
  published
    procedure Test_SpacesAroundEquals_Flag_Switch;
    procedure Test_SortKeys_Flag_Sorted;
  end;

procedure TTomlWriterFlagCase.Test_SpacesAroundEquals_Flag_Switch;
var
  B: ITomlBuilder; D: ITomlDocument; S: String;
begin
  B := NewDoc; B.BeginTable('').PutStr('b', 'x').PutInt('a', 1);
  D := B.Build;
  // 默认紧凑（无空格）
  S := String(ToToml(D, []));
  AssertTrue(Pos('b="x"', S) > 0);
  AssertTrue(Pos('a=1', S) > 0);
  // 开启 flag 才带空格
  S := String(ToToml(D, [twfSpacesAroundEquals]));
  AssertTrue(Pos('b = "x"', S) > 0);
  AssertTrue(Pos('a = 1', S) > 0);
end;

procedure TTomlWriterFlagCase.Test_SortKeys_Flag_Sorted;
var
  B: ITomlBuilder; D: ITomlDocument; S: String; p_b, p_a: SizeInt;
begin
  B := NewDoc; B.BeginTable('').PutInt('b', 2).PutInt('a', 1);
  D := B.Build;
  S := String(ToToml(D, [twfSortKeys]));
  p_a := Pos(LineEnding+'a', LineEnding+S);
  p_b := Pos(LineEnding+'b', LineEnding+S);
  AssertTrue(p_a < p_b);
end;

procedure RegisterTomlWriterFlagTests;
begin
  RegisterTest('toml-writer-flags', TTomlWriterFlagCase);
end;

end.

