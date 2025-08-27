unit test_toml_writer_snapshots_arrays;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterSnapshotArrayTests;

implementation

type
  TTomlWriterSnapshotArrayCase = class(TTestCase)
  private
    function NEOL(const S: String): String;
  published
    procedure Test_Snapshot_Arrays_Compact_Pretty_Sorted;
  end;

function TTomlWriterSnapshotArrayCase.NEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterSnapshotArrayCase.Test_Snapshot_Arrays_Compact_Pretty_Sorted;
var
  Txt: RawByteString; Doc: ITomlDocument; Err: TTomlError; S, Exp, LE: String;
begin
  LE := LineEnding;
  Txt := '[app]'+#10+
         'ints = [1,2,3]'+#10+
         'floats = [1.0, 2.5]'+#10+
         'bools = [true,false,true]'+#10+
         'strings = ["a","b"]'+#10;
  Err.Clear; AssertTrue(Parse(Txt, Doc, Err));
  S := String(ToToml(Doc, [twfPretty, twfSortKeys]));
  // keys 应按字母序：bools, floats, ints, strings；数组元素以 ", " 分隔
  Exp := '[app]'+LE+
         'bools=[true, false, true]'+LE+
         'floats=[1.0, 2.5]'+LE+
         'ints=[1, 2, 3]'+LE+
         'strings=["a", "b"]';
  AssertEquals(NEOL(Exp), NEOL(S));
end;

procedure RegisterTomlWriterSnapshotArrayTests;
begin
  RegisterTest('toml-writer-snapshots-arrays', TTomlWriterSnapshotArrayCase);
end;

end.

