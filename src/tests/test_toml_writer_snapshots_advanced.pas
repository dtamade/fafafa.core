unit test_toml_writer_snapshots_advanced;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterSnapshotAdvancedTests;

implementation

type
  TTomlWriterSnapshotAdvancedCase = class(TTestCase)
  private
    function NormalizeEOL(const S: String): String;
  published
    procedure Test_Snapshot_Nested_Scalars_Compact;
    procedure Test_Snapshot_DateTime_Spaced_Pretty_Sorted;
  end;

function TTomlWriterSnapshotAdvancedCase.NormalizeEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterSnapshotAdvancedCase.Test_Snapshot_Nested_Scalars_Compact;
var
  B: ITomlBuilder; D: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  // 根表下：嵌套表与多类型标量
  B.BeginTable('root').PutStr('title','TOML Test').EndTable;
  B.BeginTable('root.sub').PutInt('a',1).PutFloat('b',2.5).PutBool('ok',True).EndTable;
  D := B.Build;
  S := String(ToToml(D, [twfPretty, twfSortKeys]));
  // 期望：紧凑等号，分节 + 排序
  Exp := '[root]'+LE+'title="TOML Test"'
       + LE+LE+'[root.sub]'+LE+'a=1'+LE+'b=2.5'+LE+'ok=true';
  AssertEquals(NormalizeEOL(Exp), NormalizeEOL(S));
end;

procedure TTomlWriterSnapshotAdvancedCase.Test_Snapshot_DateTime_Spaced_Pretty_Sorted;
var
  B: ITomlBuilder; D: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  B.BeginTable('t');
  // 以原文写入日期时间：目前日期时间以原文文本形式序列化
  B.PutStr('offset', '2021-03-17T12:00:00Z');
  B.PutStr('local', '2025-08-13T10:20:30');
  B.EndTable;
  D := B.Build;
  S := String(ToToml(D, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[t]'+LE+'local = "2025-08-13T10:20:30"'+LE+'offset = "2021-03-17T12:00:00Z"';
  AssertEquals(NormalizeEOL(Exp), NormalizeEOL(S));
end;

procedure RegisterTomlWriterSnapshotAdvancedTests;
begin
  RegisterTest('toml-writer-snapshots-advanced', TTomlWriterSnapshotAdvancedCase);
end;

end.

