program example_crypto_gcm_basic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.crypto;

var
  GCM: IAEADCipher;
  Key, Nonce, AAD, PT, CT: TBytes;

procedure PrintHex(const name: string; const b: TBytes);
var i: Integer; s: string;
begin
  s := '';
  for i:=0 to Length(b)-1 do s := s + LowerCase(IntToHex(b[i],2));
  WriteLn(name, ': ', s);
end;

begin
  try
    GCM := CreateAES256GCM;
    SetLength(Key, 32);
    FillChar(Key[0], 32, 0);
    GCM.SetKey(Key);
    GCM.SetTagLength(16);

    Nonce := ComposeGCMNonce12(1234, 1);
    AAD := TEncoding.UTF8.GetBytes('example aad');
    PT := TEncoding.UTF8.GetBytes('hello gcm');

    CT := GCM.Seal(Nonce, AAD, PT);
    PrintHex('CT||Tag', CT);

    PT := GCM.Open(Nonce, AAD, CT);
    WriteLn('Roundtrip OK: ', TEncoding.UTF8.GetString(PT));
  except
    on E: Exception do begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

