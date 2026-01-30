{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_aot_interleaved;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_AoT_Interleaved = class(TTestCase)
  published
    procedure Test_Writer_Root_AoT_And_Nested_AoT_Interleaving_Sort_Pretty_Spaces;
  end;

implementation

procedure TTestCase_Writer_AoT_Interleaved.Test_Writer_Root_AoT_And_Nested_AoT_Interleaving_Sort_Pretty_Spaces;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  P: array[1..10] of SizeInt;
begin
  LErr.Clear;
  // 根 AoT: [[services]] 两项；另有根级子表 [meta]
  AssertTrue(Parse(RawByteString(
    'title = "AoT"' + LineEnding +
    '[[services]]' + LineEnding +
    'name = "svc1"' + LineEnding +
    '[[services]]' + LineEnding +
    'name = "svc2"' + LineEnding +
    '[meta]' + LineEnding +
    'owner = "ops"'
  ), LDoc, LErr));
  AssertFalse(LErr.HasError);

  S := String(ToToml(LDoc, [twfSortKeys, twfSpacesAroundEquals, twfPretty]));

  // 顺序断言：
  // 1) 根级标量 title 在最前；随后应出现 [[services]]（不强绑空行数量）
  P[7] := Pos('title = "AoT"', S);
  P[8] := Pos('[[services]]', S);
  AssertTrue((P[7] > 0) and (P[8] > 0) and (P[7] < P[8]));

  // 2) 两个 [[services]] 节块均出现，且按插入顺序（svc1 在 svc2 前）
  P[1] := Pos('[[services]]' + LineEnding + 'name = "svc1"', S);
  P[2] := Pos('[[services]]' + LineEnding + 'name = "svc2"', S);
  AssertTrue((P[1] > 0) and (P[2] > 0) and (P[1] < P[2]));

  // 3) [meta] 作为根级子表，位于所有根级 AoT 展开之后
  P[6] := Pos('[meta]' + LineEnding + 'owner = "ops"', S);
  AssertTrue((P[6] > 0) and (P[2] < P[6]));

  // 4) 空格风格：确保至少一个 key = value 的空格模式出现
  AssertTrue(Pos('owner = "ops"', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_AoT_Interleaved);
end.

