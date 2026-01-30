{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_reuse_record;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_ReuseRecord = class(TTestCase)
  published
    procedure Test_ReuseRecord_Same_Instance;
    procedure Test_NoReuseRecord_Different_Instance;
  end;

implementation

procedure TTestCase_Reader_ReuseRecord.Test_ReuseRecord_Same_Instance;
var
  D: TCSVDialect; R: ICSVReader; Rec1, Rec2: ICSVRecord; Tmp: string; F: TextFile;
begin
  Tmp := 'tmp_reuse_on.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'a'); Writeln(F, 'b'); CloseFile(F);
  D := DefaultRFC4180;
  R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).ReuseRecord(True).Build;
  try
    AssertTrue(R.ReadNext(Rec1));
    AssertTrue(R.ReadNext(Rec2));
    AssertTrue('When reuse enabled, interfaces may reference same instance', Pointer(Rec1) = Pointer(Rec2));
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TTestCase_Reader_ReuseRecord.Test_NoReuseRecord_Different_Instance;
var
  D: TCSVDialect; R: ICSVReader; Rec1, Rec2: ICSVRecord; Tmp: string; F: TextFile;
begin
  Tmp := 'tmp_reuse_off.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'a'); Writeln(F, 'b'); CloseFile(F);
  D := DefaultRFC4180;
  R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).ReuseRecord(False).Build;
  try
    AssertTrue(R.ReadNext(Rec1));
    AssertTrue(R.ReadNext(Rec2));
    AssertTrue('When reuse disabled, different instances should be returned', Pointer(Rec1) <> Pointer(Rec2));
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_ReuseRecord);

end.

