{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshots_deep;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Snapshots_Deep = class(TTestCase)
  published
    procedure Test_Writer_Deep_Nested_AoT_Subtables_Sorted_Pretty;
  end;

implementation

procedure TTestCase_Writer_Snapshots_Deep.Test_Writer_Deep_Nested_AoT_Subtables_Sorted_Pretty;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  P1,P2,P3,P4,P5: SizeInt;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString(
    'title = "TOML"' + LineEnding +
    'a.b.c = 1' + LineEnding +
    'a.b.d = 2' + LineEnding +
    'a.arr = [1, 2, 3]' + LineEnding +
    '[[a.t]]' + LineEnding +
    'name = "n1"' + LineEnding +
    '[[a.t]]' + LineEnding +
    'name = "n2"' + LineEnding +
    'z = 0' + LineEnding +
    'y = 9'
  ), LDoc, LErr));
  AssertFalse(LErr.HasError);

  // SortKeys + Pretty 输出：
  // 1) 根级标量按字典序：title, y, z
  // 2) AoT [[a.t]] 展开并在子表前
  // 3) 子表 [a] 与其子表 [a.b] 递归输出
  S := String(ToToml(LDoc, [twfSortKeys, twfPretty]));

  // 基础顺序断言（不绑定全部文本，仅检查关键片段顺序）
  P1 := Pos('title = "TOML"', S);
  P2 := Pos('y = 9', S);
  P3 := Pos('z = 0', S);
  AssertTrue((P1 > 0) and (P2 > 0) and (P3 > 0) and (P1 < P2) and (P2 < P3));

  // AoT 展开在 [a] 之前
  P1 := Pos('[[a.t]]', S);
  P2 := Pos('[a]', S);
  // Writer 的规则是“每个表内部：标量 → AoT → 子表”。因此 [a] 会先于 [[a.t]] 出现（在 a 的上下文中）。
  AssertTrue((P1 > 0) and (P2 > 0) and (P2 < P1));

  // [a] 在 [a.b] 之前
  P3 := Pos('[a.b]', S);
  AssertTrue((P3 > 0) and (P2 < P3));

  // [a.b] 下包含 c 和 d（按 SortKeys 输出）
  P4 := Pos('c = 1', S);
  P5 := Pos('d = 2', S);
  AssertTrue((P4 > 0) and (P5 > 0) and (P4 < P5));
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshots_Deep);
end.

