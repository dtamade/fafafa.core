{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_no_pretty;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Snapshot_NoPretty = class(TTestCase)
  published
    procedure Test_Writer_Full_Snapshot_Sort_Spaces_NoPretty;
  end;

implementation

procedure TTestCase_Writer_Snapshot_NoPretty.Test_Writer_Full_Snapshot_Sort_Spaces_NoPretty;
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

  S := String(ToToml(LDoc, [twfSortKeys, twfSpacesAroundEquals]));

  Expected :=
    'app_version = "1.2.3"' + LineEnding +
    'name = "demo"' + LineEnding +
    '[misc]' + LineEnding +
    'note = "ok"' + LineEnding +
    '[svc]' + LineEnding +
    'enabled = true' + LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id = 1' + LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role = "primary"' + LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id = 2' + LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role = "replica"' + LineEnding +
    '[svc.db]' + LineEnding +
    'host = "localhost"' + LineEnding +
    'port = 3306';

  AssertEquals('Snapshot(no pretty) mismatch', Expected, S);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_NoPretty);
end.

