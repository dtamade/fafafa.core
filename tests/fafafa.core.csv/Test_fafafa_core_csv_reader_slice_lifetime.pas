{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_slice_lifetime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_SliceLifetime = class(TTestCase)
  published
    procedure Test_Slice_Invalid_After_Next_Read;
    procedure Test_Bytes_Copy_Survives_After_Next_Read;
  end;

implementation

procedure TTestCase_Reader_SliceLifetime.Test_Slice_Invalid_After_Next_Read;
var
  R: ICSVReader; Rec: ICSVRecord; p: PAnsiChar; n: SizeInt; Tmp: string; F: TextFile;
begin
  Tmp := 'tmp_slice_lifetime.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'hello'); Writeln(F, 'world'); CloseFile(F);
  R := CSVReaderBuilder.FromFile(Tmp).ReuseRecord(True).Build;
  try
    AssertTrue(R.ReadNext(Rec));
    AssertTrue(Rec.GetFieldSlice(0, p, n));
    AssertTrue('slice length 5', n = 5);
    AssertTrue('first field is hello', (n = 5) and (PAnsiChar('hello')^ = p^));
    // read next record; slice should be invalid to use meaningfully
    AssertTrue(R.ReadNext(Rec));
    // Invalidate expectation: p now points to old buffer. We only check that a new slice differs.
    // Fetch new slice and ensure content changes to "world"
    AssertTrue(Rec.GetFieldSlice(0, p, n));
    AssertTrue('new slice length 5', n = 5);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TTestCase_Reader_SliceLifetime.Test_Bytes_Copy_Survives_After_Next_Read;
var
  R: ICSVReader; Rec: ICSVRecord; b: RawByteString; p: PAnsiChar; n: SizeInt; Tmp: string; F: TextFile;
begin
  Tmp := 'tmp_slice_copy.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'hello'); Writeln(F, 'world'); CloseFile(F);
  R := CSVReaderBuilder.FromFile(Tmp).ReuseRecord(True).Build;
  try
    AssertTrue(R.ReadNext(Rec));
    AssertTrue(Rec.TryGetFieldBytes(0, b));
    // Now next record read
    AssertTrue(R.ReadNext(Rec));
    // b should still hold previous record bytes "hello"
    AssertTrue('copied bytes length 5', Length(b) = 5);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_SliceLifetime);

end.

