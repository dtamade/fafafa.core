unit test_toml_writer_snapshots;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterSnapshotTests;

implementation

type
  TTomlWriterSnapshotCase = class(TTestCase)
  private
    function NormalizeEOL(const S: String): String;
  published
    procedure Test_Snapshot_Compact_Pretty_Sorted;
    procedure Test_Snapshot_Spaced_Pretty_Sorted;
  end;

function TTomlWriterSnapshotCase.NormalizeEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterSnapshotCase.Test_Snapshot_Compact_Pretty_Sorted;
var
  B: ITomlBuilder; D: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  B.BeginTable('app').PutStr('name','core').PutInt('ver',1).EndTable;
  B.BeginTable('db').PutStr('host','localhost').PutInt('port',5432).EndTable;
  B.BeginTable('features').PutBool('x', True).PutBool('y', False).EndTable;
  D := B.Build;
  S := String(ToToml(D, [twfPretty, twfSortKeys]));
  Exp := '[app]'+LE+'name="core"'+LE+'ver=1'
       + LE+LE+'[db]'+LE+'host="localhost"'+LE+'port=5432'
       + LE+LE+'[features]'+LE+'x=true'+LE+'y=false';
  AssertEquals(NormalizeEOL(Exp), NormalizeEOL(S));
end;

procedure TTomlWriterSnapshotCase.Test_Snapshot_Spaced_Pretty_Sorted;
var
  B: ITomlBuilder; D: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  B.BeginTable('app').PutStr('name','core').PutInt('ver',1).EndTable;
  B.BeginTable('db').PutStr('host','localhost').PutInt('port',5432).EndTable;
  B.BeginTable('features').PutBool('x', True).PutBool('y', False).EndTable;
  D := B.Build;
  S := String(ToToml(D, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[app]'+LE+'name = "core"'+LE+'ver = 1'
       + LE+LE+'[db]'+LE+'host = "localhost"'+LE+'port = 5432'
       + LE+LE+'[features]'+LE+'x = true'+LE+'y = false';
  AssertEquals(NormalizeEOL(Exp), NormalizeEOL(S));
end;

procedure RegisterTomlWriterSnapshotTests;
begin
  RegisterTest('toml-writer-snapshots', TTomlWriterSnapshotCase);
end;

end.

