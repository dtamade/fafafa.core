unit test_toml_writer_aot_nested_complex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterAotNestedComplexTests;

implementation

type
  TTomlWriterAotNestedComplexCase = class(TTestCase)
  private
    function NEOL(const S: String): String;
  published
    procedure Test_AoT_Item_Contains_Array_And_Subtable_Pretty_Sorted_Spaced;
    procedure Test_AoT_Item_Contains_Array_And_Subtable_Compact;
  end;

function TTomlWriterAotNestedComplexCase.NEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterAotNestedComplexCase.Test_AoT_Item_Contains_Array_And_Subtable_Pretty_Sorted_Spaced;
var
  Txt: RawByteString; Doc: ITomlDocument; Err: TTomlError; S, Exp, LE: String;
begin
  LE := LineEnding;
  // 第二个 fruit 项内包含子表 [fruit.info] 与数组 prices，数组内含浮点（1 → 1.0）
  Txt := '[[fruit]]' + #10 +
         'name = "apple"' + #10 +
         'tags = ["fresh","sweet"]' + #10 +
         '[[fruit]]' + #10 +
         'name = "banana"' + #10 +
         'tags = ["ripe"]' + #10 +
         '' + #10 +
         '[fruit.info]' + #10 +
         'origin = "earth"' + #10 +
         'prices = [1.0, 2.5]' + #10;
  Err.Clear; AssertTrue(Parse(Txt, Doc, Err));
  S := String(ToToml(Doc, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[[fruit]]' + LE +
         'name = "apple"' + LE +
         'tags = ["fresh", "sweet"]' + LE + LE +
         '[[fruit]]' + LE +
         'name = "banana"' + LE +
         'tags = ["ripe"]' + LE + LE +
         '[fruit.info]' + LE +
         'origin = "earth"' + LE +
         'prices = [1.0, 2.5]';
  AssertEquals(NEOL(Exp), NEOL(S));
end;

procedure TTomlWriterAotNestedComplexCase.Test_AoT_Item_Contains_Array_And_Subtable_Compact;
var
  Txt: RawByteString; Doc: ITomlDocument; Err: TTomlError; S, Exp: String;
begin
  // 同一输入，使用默认紧凑模式（无空格，无排序，无空行）
  Txt := '[[fruit]]' + #10 +
         'name = "apple"' + #10 +
         'tags = ["fresh","sweet"]' + #10 +
         '[[fruit]]' + #10 +
         'name = "banana"' + #10 +
         'tags = ["ripe"]' + #10 +
         '' + #10 +
         '[fruit.info]' + #10 +
         'origin = "earth"' + #10 +
         'prices = [1.0,2.5]' + #10;
  Err.Clear; if not Parse(Txt, Doc, Err) then Fail('Parse failed: ' + Err.ToString);
  S := String(ToToml(Doc, []));
  // 紧凑输出：无空格、保持插入顺序；数组浮点仍需 1 → 1.0
  Exp := '[[fruit]]' + #10 +
         'name="apple"' + #10 +
         'tags=["fresh", "sweet"]' + #10 +
         '[[fruit]]' + #10 +
         'name="banana"' + #10 +
         'tags=["ripe"]' + #10 +
         '[fruit.info]' + #10 +
         'origin="earth"' + #10 +
         'prices=[1.0, 2.5]';
  AssertEquals(NEOL(Exp), NEOL(S));
end;

procedure RegisterTomlWriterAotNestedComplexTests;
begin
  RegisterTest('toml-writer-aot-nested-complex', TTomlWriterAotNestedComplexCase);
end;

end.

