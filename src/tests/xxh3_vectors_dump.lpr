program xxh3_vectors_dump;
{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.crypto;

function BytesOfHex(const S: string): TBytes;
begin
  Result := HexToBytes(S);
end;

function RepeatByte(B: Byte; N: Integer): TBytes;
var i: Integer;
begin
  SetLength(Result, N);
  for i := 0 to N-1 do Result[i] := B;
end;

procedure Dump(const Name: string; const Data: TBytes);
var H: TBytes;
begin
  H := XXH3_64Hash(Data, 0);
  WriteLn(Name, '=', UpperCase(BytesToHex(H)));
end;

var s: string;
begin
  // Defined sequences
  Dump('EMPTY', nil);
  Dump('00', BytesOfHex('00'));
  Dump('000102', BytesOfHex('000102'));
  Dump('00010203040506', BytesOfHex('00010203040506'));
  Dump('000102030405060708090A0B0C0D0E', BytesOfHex('000102030405060708090A0B0C0D0E'));
  Dump('0..31', BytesOfHex('000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F'));
  Dump('0..63', BytesOfHex('000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'));
  Dump('A*129', RepeatByte($41, 129));
  Dump('B*240', RepeatByte($42, 240));
  Dump('C*241', RepeatByte($43, 241));
  Dump('D*4096', RepeatByte($44, 4096));
end.

