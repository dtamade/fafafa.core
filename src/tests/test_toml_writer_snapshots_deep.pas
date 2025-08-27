unit test_toml_writer_snapshots_deep;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterSnapshotDeepTests;

implementation

type
  TTomlWriterSnapshotDeepCase = class(TTestCase)
  private
    function NEOL(const S: String): String;
  published
    procedure Test_Snapshot_Deep_Nested_Pretty_Sorted_Spaced;
  end;

function TTomlWriterSnapshotDeepCase.NEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterSnapshotDeepCase.Test_Snapshot_Deep_Nested_Pretty_Sorted_Spaced;
var
  Txt: RawByteString; Doc: ITomlDocument; Err: TTomlError; S, Exp, LE: String;
begin
  LE := LineEnding;
  Txt := '[a]'+#10+
         'x = 1'+#10+
         '[a.b]'+#10+
         'y = 2.5'+#10+
         '[[a.b.c]]'+#10+
         'z = "ok"'+#10+
         '[[a.b.c]]'+#10+
         'z = "no"'+#10;
  Err.Clear; AssertTrue(Parse(Txt, Doc, Err));
  S := String(ToToml(Doc, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[a]'+LE+'x = 1' + LE+LE +
         '[a.b]'+LE+'y = 2.5' + LE+LE +
         '[[a.b.c]]'+LE+'z = "ok"' + LE+LE +
         '[[a.b.c]]'+LE+'z = "no"';
  AssertEquals(NEOL(Exp), NEOL(S));
end;

procedure RegisterTomlWriterSnapshotDeepTests;
begin
  RegisterTest('toml-writer-snapshots-deep', TTomlWriterSnapshotDeepCase);
end;

end.

