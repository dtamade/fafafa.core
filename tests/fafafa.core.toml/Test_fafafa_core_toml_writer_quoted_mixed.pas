{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_quoted_mixed;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Quoted_Mixed = class(TTestCase)
  published
    procedure Test_Writer_QuotedKeys_With_Mixed_Structures_Sort_Pretty_Spaces;
  end;

implementation

procedure TTestCase_Writer_Quoted_Mixed.Test_Writer_QuotedKeys_With_Mixed_Structures_Sort_Pretty_Spaces;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  P1, P2, P3: SizeInt;
begin
  LErr.Clear;
  // 包含 quoted 键（带空格与引号）+ 子表 + AoT
  AssertTrue(Parse(RawByteString(
    'title = "Q"' + LineEnding +
    '["root table"]' + LineEnding +
    '"a b" = 1' + LineEnding +
    '"q\"t" = "v"' + LineEnding +
    '[[items]]' + LineEnding +
    'name = "i1"' + LineEnding +
    '[[items]]' + LineEnding +
    'name = "i2"' + LineEnding +
    '["root table"."sub table"]' + LineEnding +
    'x = true'
  ), LDoc, LErr));
  AssertFalse(LErr.HasError);

  S := String(ToToml(LDoc, [twfSortKeys, twfSpacesAroundEquals, twfPretty]));

  // 1) 根级标量在前，并有 Pretty 空行
  AssertTrue(Pos('title = "Q"' + LineEnding + LineEnding, S) > 0);

  // 2) quoted 表头与 quoted 键存在，并按空格风格输出
  P1 := Pos('["root table"]', S);
  AssertTrue(P1 > 0);
  AssertTrue(Pos('"a b" = 1', S) > 0);
  AssertTrue(Pos('"q\"t" = "v"', S) > 0);

  // 3) AoT 展开，两个 [[items]] 都存在
  P2 := Pos('[[items]]' + LineEnding + 'name = "i1"', S);
  P3 := Pos('[[items]]' + LineEnding + 'name = "i2"', S);
  AssertTrue((P2 > 0) and (P3 > 0) and (P2 < P3));

  // 4) 子表 ["root table"."sub table"] 正常输出（quoted 路径）
  AssertTrue(Pos('["root table"."sub table"]' + LineEnding + 'x = true', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Quoted_Mixed);
end.

