program example_crypto_gcm_tag12;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.crypto;

var
  GCM: IAEADCipher;
  Key, Nonce, AAD, PT, CT: TBytes;

begin
  try
    GCM := CreateAES256GCM;
    SetLength(Key, 32);
    FillChar(Key[0], 32, 0);
    GCM.SetKey(Key);
    GCM.SetTagLength(12);

    SetLength(Nonce, 12);
    FillChar(Nonce[0], 12, 1);

    SetLength(AAD, 0);
    PT := TEncoding.UTF8.GetBytes('tag12');

    CT := GCM.Seal(Nonce, AAD, PT);
    PT := GCM.Open(Nonce, AAD, CT);
    WriteLn('TagLen=12 Roundtrip OK: ', TEncoding.UTF8.GetString(PT));
  except
    on E: Exception do begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

