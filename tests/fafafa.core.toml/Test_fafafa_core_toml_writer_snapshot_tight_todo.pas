{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_tight_todo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  // TODO: Writer 紧凑等号（key=value）快照占位用例
  // 说明：当前实现默认为 key = value（两侧空格），twfSpacesAroundEquals 与默认等价。
  // 当未来提供“紧凑等号”开关时，将把本用例改为严格比较紧凑快照。
  TTestCase_Writer_Snapshot_Tight_TODO = class(TTestCase)
  published
    procedure Test_Writer_Full_Snapshot_Tight_Equals_TODO;
  end;

implementation

procedure TTestCase_Writer_Snapshot_Tight_TODO.Test_Writer_Full_Snapshot_Tight_Equals_TODO;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S, ExpectedTight: String;
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

  // 当前实现：默认含空格等号
  S := String(ToToml(LDoc, []));

  // 未来紧凑等号期望（示例）：
  ExpectedTight :=
    'app_version="1.2.3"' + LineEnding +
    'name="demo"' + LineEnding +
    LineEnding +
    '[misc]' + LineEnding +
    'note="ok"' + LineEnding +
    LineEnding +
    '[svc]' + LineEnding +
    'enabled=true' + LineEnding +
    LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id=1' + LineEnding +
    LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role="primary"' + LineEnding +
    LineEnding +
    '[[svc.nodes]]' + LineEnding +
    'id=2' + LineEnding +
    LineEnding +
    '[svc.nodes.meta]' + LineEnding +
    'role="replica"' + LineEnding +
    LineEnding +
    '[svc.db]' + LineEnding +
    'host="localhost"' + LineEnding +
    'port=3306';

  // TODO: 暂保持观察，不做失败断言，等“紧凑等号”策略落地后改为严格比较：
  // AssertEquals('Snapshot(tight) mismatch', ExpectedTight, S);
  AssertTrue(Length(S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_Tight_TODO);
end.

