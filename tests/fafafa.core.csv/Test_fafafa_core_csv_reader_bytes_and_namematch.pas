{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_bytes_and_namematch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Bytes_And_NameMatch = class(TTestCase)
  published
    procedure Test_BytesMode_AsArray_And_ByName_With_Trim_And_Quoted;
    procedure Test_NameMatchMode_Exact_Vs_AsciiCI;
  end;

implementation

procedure TTestCase_Reader_Bytes_And_NameMatch.Test_BytesMode_AsArray_And_ByName_With_Trim_And_Quoted;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; F: TextFile;
  S: string; ok: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.TrimSpaces := True;
  Tmp := 'tmp_bytes_trim.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F);
  // 第一列被引号包裹，应保留空格；第二列未引号，应 Trim；第三列正常
  Writeln(F, '"  a  ",  b  ,c');
  CloseFile(F);
  try
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).RecordKind(csvRecordBytes).Build;
    AssertTrue('Should read a record', R.ReadNext(Rec));
    // AsArray 触发一次性解码
    var arr := Rec.AsArray;
    AssertEquals('field0 quoted should preserve spaces', '  a  ', arr[0]);
    AssertEquals('field1 unquoted should be trimmed', 'b', arr[1]);
    AssertEquals('field2 normal', 'c', arr[2]);
    // TryGetByName 不应影响（无 Header），但也应稳定返回 false
    ok := Rec.TryGetByName('col', S);
    AssertFalse('no header -> TryGetByName should be false', ok);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TTestCase_Reader_Bytes_And_NameMatch.Test_NameMatchMode_Exact_Vs_AsciiCI;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; F: TextFile;
  S: string; ok: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := True;
  Tmp := 'tmp_namematch.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F);
  // Header: Foo,bar; Data: 1,2
  Writeln(F, 'Foo,bar');
  Writeln(F, '1,2');
  CloseFile(F);
  try
    // AsciiCI：大小写不敏感
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).Build;
    AssertTrue(R.ReadNext(Rec));
    ok := Rec.TryGetByName('foo', S);
    AssertTrue('AsciiCI should match lower case', ok);
    AssertEquals('1', S);
    // Exact：大小写敏感
    D.NameMatchMode := csvNameExact;
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).Build;
    AssertTrue(R.ReadNext(Rec));
    ok := Rec.TryGetByName('foo', S);
    AssertFalse('Exact should not match lower case', ok);
    ok := Rec.TryGetByName('Foo', S);
    AssertTrue('Exact should match exact case', ok);
    AssertEquals('1', S);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_Bytes_And_NameMatch);

end.

