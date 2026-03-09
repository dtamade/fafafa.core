{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_tight_todo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  // Writer 默认快照（带空格等号）语义用例
  // 说明：默认输出为 key = value；开启 twfTightEquals 后输出为 key=value。
  TTestCase_Writer_Snapshot_DefaultSpacing = class(TTestCase)
  published
    procedure Test_Writer_Full_Snapshot_Default_Spaces_And_Tight_Differs;
  end;

implementation

procedure TTestCase_Writer_Snapshot_DefaultSpacing.Test_Writer_Full_Snapshot_Default_Spaces_And_Tight_Differs;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  LDefault: String;
  LTight: String;
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

  LDefault := String(ToToml(LDoc, []));
  LTight := String(ToToml(LDoc, [twfTightEquals]));

  AssertTrue('Default writer output should contain spaced equals', Pos(' = ', LDefault) > 0);
  AssertTrue('Default snapshot should keep spaced app_version assignment', Pos('app_version = "1.2.3"', LDefault) > 0);

  AssertTrue('Tight output should contain compact assignment for app_version', Pos('app_version="1.2.3"', LTight) > 0);
  AssertEquals('Tight output should not keep spaced app_version assignment', 0, Pos('app_version = "1.2.3"', LTight));

  AssertTrue('Default output and tight output should differ', LDefault <> LTight);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_DefaultSpacing);
end.

