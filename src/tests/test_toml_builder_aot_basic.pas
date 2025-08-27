unit test_toml_builder_aot_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlBuilderAotBasicTests;

implementation

type
  TTomlBuilderAotBasicCase = class(TTestCase)
  private
    function NEOL(const S: String): String;
  published
    procedure Test_Builder_EnsureArray_PushTable_And_Write;
  end;

function TTomlBuilderAotBasicCase.NEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlBuilderAotBasicCase.Test_Builder_EnsureArray_PushTable_And_Write;
var B: ITomlBuilder; Doc: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  B.EnsureArray('fruit').PushTable('fruit').PutStr('name','apple').EndTable;
  B.PushTable('fruit').PutStr('name','banana').EndTable;
  B.BeginTable('fruit.info').PutStr('origin','earth').EndTable;
  Doc := B.Build;
  S := String(ToToml(Doc, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[[fruit]]' + LE +
         'name = "apple"' + LE + LE +
         '[[fruit]]' + LE +
         'name = "banana"' + LE + LE +
         '[fruit.info]' + LE +
         'origin = "earth"';
  AssertEquals(NEOL(Exp), NEOL(S));
end;

procedure RegisterTomlBuilderAotBasicTests;
begin
  RegisterTest('toml-builder-aot-basic', TTomlBuilderAotBasicCase);
end;

end.

