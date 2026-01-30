{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_pretty_no_sort;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Snapshot_Pretty_NoSort = class(TTestCase)
  published
    procedure Test_Writer_Full_Snapshot_Pretty_Spaces_NoSort;
  end;

implementation

procedure TTestCase_Writer_Snapshot_Pretty_NoSort.Test_Writer_Full_Snapshot_Pretty_Spaces_NoSort;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S, Expected: String;
begin
  LErr.Clear;
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

  S := String(ToToml(LDoc, [twfSpacesAroundEquals, twfPretty]));

  // 无 Sort：按插入顺序输出根级子表：[svc] 在 [misc] 之前；Pretty 插入空行
  Expected :=
    'app_version = "1.2.3"' + LineEnding +
    'name = "demo"' + LineEnding +
    LineEnding +
    '[svc]' + LineEnding +
    'enabled = true' + LineEnding +
    LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id = 1' + LineEnding +
    LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role = "primary"' + LineEnding +
    LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id = 2' + LineEnding +
    LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role = "replica"' + LineEnding +
    LineEnding +
    '[svc.db]' + LineEnding +
    'host = "localhost"' + LineEnding +
    'port = 3306' + LineEnding +
    LineEnding +
    '[misc]' + LineEnding +
    'note = "ok"';

  AssertEquals('Snapshot(pretty no sort) mismatch', Expected, S);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_Pretty_NoSort);
end.

