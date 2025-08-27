{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_tight_sort;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Snapshot_Tight_Sort = class(TTestCase)
  published
    procedure Test_Writer_Full_Snapshot_Tight_Equals_With_Sort;
  end;

implementation

procedure TTestCase_Writer_Snapshot_Tight_Sort.Test_Writer_Full_Snapshot_Tight_Equals_With_Sort;
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

  S := String(ToToml(LDoc, [twfTightEquals, twfSortKeys]));

  Expected :=
    'app_version="1.2.3"' + LineEnding +
    'name="demo"' + LineEnding +
    '[misc]' + LineEnding +
    'note="ok"' + LineEnding +
    '[svc]' + LineEnding +
    'enabled=true' + LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id=1' + LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role="primary"' + LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id=2' + LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role="replica"' + LineEnding +
    '[svc.db]' + LineEnding +
    'host="localhost"' + LineEnding +
    'port=3306';

  AssertEquals('Snapshot(tight+sort) mismatch', Expected, S);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_Tight_Sort);
end.

