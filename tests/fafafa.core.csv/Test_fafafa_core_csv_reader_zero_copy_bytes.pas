{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_zero_copy_bytes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_ZeroCopyBytes = class(TTestCase)
  published
    procedure Test_TryGetFieldBytes_Basic_UTF8;
    procedure Test_TryGetFieldBytes_IndexOutOfRange;
  end;

implementation

procedure TTestCase_Reader_ZeroCopyBytes.Test_TryGetFieldBytes_Basic_UTF8;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; F: TextFile;
  B: RawByteString;
begin
  Tmp := 'tmp_zerobytes_basic.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'a,你'); CloseFile(F);
  D := DefaultRFC4180;
  R := OpenCSVReader(Tmp, D);
  try
    AssertTrue(R.ReadNext(Rec));
    AssertTrue(Rec.TryGetFieldBytes(0, B));
    AssertEquals('a', string(B));
    AssertTrue(Rec.TryGetFieldBytes(1, B));
    // 第二列是 Unicode 字符，转换后的 UTF-8 应该非空
    AssertTrue(Length(B) > 0);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TTestCase_Reader_ZeroCopyBytes.Test_TryGetFieldBytes_IndexOutOfRange;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; F: TextFile;
  B: RawByteString;
begin
  Tmp := 'tmp_zerobytes_oob.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'x'); CloseFile(F);
  D := DefaultRFC4180;
  R := OpenCSVReader(Tmp, D);
  try
    AssertTrue(R.ReadNext(Rec));
    AssertFalse(Rec.TryGetFieldBytes(1, B));
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_ZeroCopyBytes);

end.

