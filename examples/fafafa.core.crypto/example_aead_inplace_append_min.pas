{$CODEPAGE UTF8}
program example_aead_inplace_append_min;

{$mode objfpc}{$H+}

{*
  Minimal AEAD demo (Append + In-Place)
  - Logs to console and to bin/run.log (same directory as executable)
  - Includes basic success path only; see file_encryption.lpr for negative case (bad password)
*}

uses
  SysUtils,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces;


procedure Log(const S: string);
var
  L: Text;
  P: string;
begin
  P := ExtractFilePath(ParamStr(0)) + 'run.log';
  AssignFile(L, P);
  {$I-}
  if FileExists(P) then
    Append(L)
  else
    Rewrite(L);
  {$I+}
  WriteLn(L, S);
  CloseFile(L);
end;

procedure PrintAndLog(const S: string);
begin
  WriteLn(S);
  Log(S);
end;

procedure DemoAppend;
var AEAD: IAEADCipher; Ex: IAEADCipherEx; Key, Nonce, AAD, PT, CT: TBytes; Dst: TBytes; n: Integer;
begin
  AEAD := CreateAES256GCM; // 门面工厂
  SetLength(Key, 32); FillChar(Key[0], 32, 1); AEAD.SetKey(Key);
  Nonce := GenerateNonce12;
  SetLength(AAD, 3); FillChar(AAD[0], 3, 7);
  SetLength(PT, 5); FillChar(PT[0], 5, 9);
  if not Supports(AEAD, IAEADCipherEx, Ex) then raise Exception.Create('IAEADCipherEx not supported');
  SetLength(Dst, 0);
  n := Ex.SealAppend(Dst, Nonce, AAD, PT);
  PrintAndLog('Append: CT+Tag len=' + IntToStr(n));
  CT := Copy(Dst, 0, Length(Dst));
  SetLength(Dst, 0);
  n := Ex.OpenAppend(Dst, Nonce, AAD, CT);
  PrintAndLog('Append: PT len=' + IntToStr(n) + ' ok=' + BoolToStr(n=Length(PT), True));
end;

procedure DemoInPlace;
var AEAD: IAEADCipher; Ex2: IAEADCipherEx2; Key, Nonce, AAD, Data: TBytes; n: Integer;
begin
  AEAD := CreateAES256GCM; // 门面工厂
  SetLength(Key, 32); FillChar(Key[0], 32, 2); AEAD.SetKey(Key);
  Nonce := GenerateNonce12;
  SetLength(AAD, 2); FillChar(AAD[0], 2, 5);
  SetLength(Data, 12); FillChar(Data[0], 12, 6); // 初始写入明文（示例）
  if not Supports(AEAD, IAEADCipherEx2, Ex2) then raise Exception.Create('IAEADCipherEx2 not supported');
  n := Ex2.SealInPlace(Data, Nonce, AAD);
  PrintAndLog('InPlace: CT+Tag len=' + IntToStr(n));
  n := Ex2.OpenInPlace(Data, Nonce, AAD);
  PrintAndLog('InPlace: PT len=' + IntToStr(n));
end;

begin
  try
    PrintAndLog('=== AEAD minimal demo start ===');
    DemoAppend;
    DemoInPlace;
    PrintAndLog('=== AEAD minimal demo done ===');
  except
    on E: Exception do begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
    end;
  end;
end.

