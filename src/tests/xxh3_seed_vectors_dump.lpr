program xxh3_seed_vectors_dump;
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

procedure Dump(const Name: string; const Data: TBytes; Seed: QWord);
var H: TBytes;
begin
  H := XXH3_64Hash(Data, Seed);
  WriteLn(Name, '=', UpperCase(BytesToHex(H)));
end;

begin
  Dump('EMPTY,seed=0123456789ABCDEF', nil, QWord($0123456789ABCDEF));
  Dump('00,seed=1', BytesOfHex('00'), 1);
  Dump('0..7,seed=F00DF00DF00DF00D', BytesOfHex('0001020304050607'), QWord($F00DF00DF00DF00D));
  Dump('0..15,seed=AAAAAAAAAAAAAAAA', BytesOfHex('000102030405060708090A0B0C0D0E0F'), QWord($AAAAAAAAAAAAAAAA));
  Dump('A*4096,seed=0123456789ABCDEF', RepeatByte($41, 4096), QWord($0123456789ABCDEF));
end.

