{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_mixed_nested;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Mixed_Nested = class(TTestCase)
  published
    procedure Test_Writer_Mixed_Nested_Sort_Pretty_Spaces_Order;
  end;

implementation

procedure TTestCase_Writer_Mixed_Nested.Test_Writer_Mixed_Nested_Sort_Pretty_Spaces_Order;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  P: array[1..10] of SizeInt;
begin
  LErr.Clear;
  // 结构：
  // root: title, z
  // [app] 标量 + 子表 [app.db]
  // [[app.servers]] 两项 AoT
  // [meta] 同级子表
  AssertTrue(Parse(RawByteString(
    'title = "X"' + LineEnding +
    'z = 9' + LineEnding +
    '[app]' + LineEnding +
    'name = "demo"' + LineEnding +
    '[app.db]' + LineEnding +
    'host = "127.0.0.1"' + LineEnding +
    'port = 5432' + LineEnding +
    '[[app.servers]]' + LineEnding +
    'name = "s1"' + LineEnding +
    'ip = "10.0.0.1"' + LineEnding +
    '[[app.servers]]' + LineEnding +
    'name = "s2"' + LineEnding +
    'ip = "10.0.0.2"' + LineEnding +
    '[meta]' + LineEnding +
    'env = "prod"'
  ), LDoc, LErr));
  AssertFalse(LErr.HasError);

  S := String(ToToml(LDoc, [twfSortKeys, twfSpacesAroundEquals, twfPretty]));

  // 核心断言：
  // 1) 根级按 SortKeys：title 在 z 前
  P[1] := Pos('title = "X"', S);
  P[2] := Pos('z = 9', S);
  AssertTrue((P[1] > 0) and (P[2] > 0) and (P[1] < P[2]));

  // 2) [app] 段落晚于根标量，Pretty 模式在最后一个根标量后留一个空行
  AssertTrue(Pos('z = 9' + LineEnding + LineEnding + '[app]', S) > 0);

  // 3) [app] 内部：标量先于 AoT 与子表
  P[3] := Pos('[app]' + LineEnding + 'name = "demo"', S);
  P[4] := Pos('[[app.servers]]', S);
  P[5] := Pos('[app.db]', S);
  AssertTrue((P[3] > 0) and (P[4] > 0) and (P[5] > 0) and (P[3] < P[4]) and (P[4] < P[5]));

  // 4) [[app.servers]] 两项按插入顺序展开，且 key = value 有空格
  AssertTrue(Pos('[[app.servers]]' + LineEnding + 'ip = "10.0.0.1"', S) > 0);
  AssertTrue(Pos('[[app.servers]]' + LineEnding + 'ip = "10.0.0.2"', S) > 0);

  // 5) [app.db] 中键按 SortKeys：host 在 port 前
  P[6] := Pos('[app.db]' + LineEnding + 'host = "127.0.0.1"', S);
  P[7] := Pos('port = 5432', S);
  AssertTrue((P[6] > 0) and (P[7] > 0) and (P[6] < P[7]));

  // 6) [meta] 为根级子表，位于 [app] 段落之后；并保持空格风格
  P[8] := Pos('[meta]' + LineEnding + 'env = "prod"', S);
  AssertTrue(P[8] > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Mixed_Nested);
end.

