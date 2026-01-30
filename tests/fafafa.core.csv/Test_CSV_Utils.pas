unit Test_CSV_Utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

// Generate unique temporary file name to avoid file locking issues
function GetUniqueTempFileName(const Prefix: string): string;

// Create temporary CSV file with content and return filename
function CreateTempCSVFile(const Prefix, Content: string): string;

// Safe cleanup of temporary file
procedure CleanupTempFile(const FileName: string);

// Utilities for tests: minimize huge failure messages for large strings/bytes
function BytesChecksum(const Rbs: RawByteString): UInt32;
function FormatShortBytesMismatch(const Expected, Actual: RawByteString; const LabelName: string): string;

implementation

function GetUniqueTempFileName(const Prefix: string): string;
begin
  Result := Format('%s_%d_%d.csv', [Prefix, GetTickCount64, Random(10000)]);
end;

function CreateTempCSVFile(const Prefix, Content: string): string;
var
  FS: TFileStream;
  R: RawByteString;
begin
  Result := GetUniqueTempFileName(Prefix);
  FS := TFileStream.Create(Result, fmCreate);
  try
    // Write bytes verbatim (UTF-8) to preserve exact newlines inside quoted fields
    R := UTF8Encode(Content);
    SetCodePage(R, CP_UTF8, False);
    if Length(R) > 0 then
      FS.WriteBuffer(Pointer(R)^, Length(R));
  finally
    FS.Free;
  end;
end;

procedure CleanupTempFile(const FileName: string);
begin
  if FileExists(FileName) then
  begin
    try
      DeleteFile(FileName);
    except
      // Ignore cleanup errors - file might be locked by another process
    end;
  end;
end;

function BytesChecksum(const Rbs: RawByteString): UInt32;
var
  i: SizeInt;
  s: UInt32;
begin
  s := 0;
  for i := 1 to Length(Rbs) do
    s := ((s shl 5) or (s shr 27)) xor Byte(Rbs[i]);
  Result := s;
end;

function FormatShortBytesMismatch(const Expected, Actual: RawByteString; const LabelName: string): string;
var
  le, la: SizeInt;
  se, sa: UInt32;
begin
  le := Length(Expected);
  la := Length(Actual);
  if le <> la then
    Exit(Format('%s length mismatch: expected=%d actual=%d', [LabelName, le, la]));
  se := BytesChecksum(Expected);
  sa := BytesChecksum(Actual);
  if se <> sa then
    Exit(Format('%s content mismatch: checksum exp=%u act=%u', [LabelName, se, sa]));
  Result := Format('%s mismatch: unknown reason', [LabelName]);
end;

initialization
  Randomize;

end.
