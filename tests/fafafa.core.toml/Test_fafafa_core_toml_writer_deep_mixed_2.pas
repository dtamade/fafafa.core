{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_deep_mixed_2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Deep_Mixed_2 = class(TTestCase)
  published
    procedure Test_Writer_Deep_MultiLevel_AoT_And_Subtables_Sort_Pretty_Spaces;
  end;

implementation

procedure TTestCase_Writer_Deep_Mixed_2.Test_Writer_Deep_MultiLevel_AoT_And_Subtables_Sort_Pretty_Spaces;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  P: array[1..12] of SizeInt;
begin
  LErr.Clear;
  // 结构：
  // root: app_version, name
  // [svc] 标量 + 子表 [svc.db]
  // [[svc.nodes]] 两项 AoT；每项还包含一个子表 [svc.nodes.meta]
  // [misc] 同级子表
  AssertTrue(Parse(RawByteString(
    'app_version = "1.2.3"' + LineEnding +
    'name = "demo"' + LineEnding +
    '[svc]' + LineEnding +
    'enabled = true' + LineEnding +
    '[svc.db]' + LineEnding +
    'host = "localhost"' + LineEnding +
    'port = 3306' + LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id = 1' + LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role = "primary"' + LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id = 2' + LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role = "replica"' + LineEnding +
    '[misc]' + LineEnding +
    'note = "ok"'
  ), LDoc, LErr));
  AssertFalse(LErr.HasError);

  S := String(ToToml(LDoc, [twfSortKeys, twfSpacesAroundEquals, twfPretty]));

  // 1) 根级 SortKeys：app_version 在 name 前
  P[1] := Pos('app_version = "1.2.3"', S);
  P[2] := Pos('name = "demo"', S);
  AssertTrue((P[1] > 0) and (P[2] > 0) and (P[1] < P[2]));

  // 2) Pretty：最后一个根标量后有空行再到首个根级表头（SortKeys 下应为 [misc] 再到 [svc]）
  AssertTrue(Pos('name = "demo"' + LineEnding + LineEnding + '[misc]', S) > 0);

  // 3) [svc] 内：标量 enabled 先于 AoT 与子表
  P[3] := Pos('[svc]' + LineEnding + 'enabled = true', S);
  P[4] := Pos('[[svc.nodes]]', S);
  P[5] := Pos('[svc.db]', S);
  AssertTrue((P[3] > 0) and (P[4] > 0) and (P[5] > 0) and (P[3] < P[4]) and (P[4] < P[5]));

  // 4) [[svc.nodes]] 两项按插入顺序展开；每项的 meta 子表在其项内容之后
  // 第一项
  P[6] := Pos('[[svc.nodes]]' + LineEnding + 'id = 1', S);
  P[7] := Pos('[svc.nodes.meta]' + LineEnding + 'role = "primary"', S);
  AssertTrue((P[6] > 0) and (P[7] > 0) and (P[6] < P[7]));
  // 第二项
  P[8] := Pos('[[svc.nodes]]' + LineEnding + 'id = 2', S);
  P[9] := Pos('[svc.nodes.meta]' + LineEnding + 'role = "replica"', S);
  AssertTrue((P[8] > 0) and (P[9] > 0) and (P[8] < P[9]));

  // 5) [svc.db] 中键按 SortKeys：host 在 port 前
  P[10] := Pos('[svc.db]' + LineEnding + 'host = "localhost"', S);
  P[11] := Pos('port = 3306', S);
  AssertTrue((P[10] > 0) and (P[11] > 0) and (P[10] < P[11]));

  // 6) [misc] 在 [svc] 段落之后，并保持空格风格
  P[12] := Pos('[misc]' + LineEnding + 'note = "ok"', S);
  AssertTrue(P[12] > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Deep_Mixed_2);
end.

