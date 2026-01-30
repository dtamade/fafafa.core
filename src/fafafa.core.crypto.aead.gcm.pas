{
  fafafa.core.crypto.aead.gcm - AES-256-GCM IAEADCipher implementation (skeleton)

  NOTE:
  - This is a skeleton only; will be filled after AES core/CTR/GHASH are ready.
}
unit fafafa.core.crypto.aead.gcm;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.crypto.interfaces;

type
  TBytes = fafafa.core.crypto.interfaces.TBytes;

  TAESGCM = class(TInterfacedObject, IAEADCipher, IAEADCipherEx, IAEADCipherEx2)
  private
    FKey: TBytes;
    FKeySet: Boolean;
    FTagLen: Integer;
  public
    constructor Create; virtual;
    // IAEADCipher
    function GetName: string;
    function GetKeySize: Integer;
    function NonceSize: Integer;      // 96-bit recommended
    function Overhead: Integer;       // tag length
    procedure SetKey(const AKey: TBytes);
    procedure SetTagLength(ATagLenBytes: Integer);
    function Seal(const ANonce, AAD, APlaintext: TBytes): TBytes;
    function Open(const ANonce, AAD, ACiphertext: TBytes): TBytes;
    procedure Burn;
    // IAEADCipherEx (append-style)
    function SealAppend(var ADst: TBytes; const ANonce, AAD, APlaintext: TBytes): Integer;
    function OpenAppend(var ADst: TBytes; const ANonce, AAD, ACiphertext: TBytes): Integer;
    // IAEADCipherEx2 (in-place style)
    function SealInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
    function OpenInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
  end;

function CreateAES256GCM_Impl: IAEADCipher; // internal factory for future switch

implementation

uses
  Classes, SysUtils, fafafa.core.crypto,
  fafafa.core.crypto.cipher.aes,
  fafafa.core.crypto.cipher.aes.ctr,
  fafafa.core.crypto.aead.gcm.ghash;

// === Diagnostics (tests-only via env flag) ===
var
  GDiagInited: Boolean = False;
  GDiagEnabled: Boolean = False;
  GDiagVerbose: Boolean = True;
  GDiagPath: string = '';
  GLastTestName: string = '';

function _Hash64FNV1a(const S: string): QWord;
const
  FNV_OFFSET_BASIS_64: QWord = QWord($CBF29CE484222325);
  FNV_PRIME_64: QWord = QWord($00000100000001B3);
var
  i: Integer;
  h: QWord;
  c: Byte;
begin
  h := FNV_OFFSET_BASIS_64; // 64-bit FNV offset basis
  for i := 1 to Length(S) do
  begin
    // use only low 8 bits to be explicit; Delphi/FreePascal char = Unicode
    c := Byte(Ord(S[i]) and $FF);
    h := h xor c;
    h := h * FNV_PRIME_64; // wrap-around in QWord
  end;
  Result := h;
end;


procedure DiagInit;
var
  BaseDir: string;
  Prev: string;
begin
  if GDiagInited then Exit;
  GDiagInited := True;
  GDiagEnabled := SameText(SysUtils.GetEnvironmentVariable('FAFAFA_CORE_AEAD_DIAG'), '1');
  {$IFDEF DEBUG}
  // Do NOT auto-enable diagnostics by default; must be opt-in via env
  // if not GDiagEnabled then GDiagEnabled := True;
  {$ENDIF}
  if GDiagEnabled then
  begin
    // init verbosity from env once
    GDiagVerbose := not SameText(SysUtils.GetEnvironmentVariable('FAFAFA_CORE_AEAD_DIAG_VERBOSE'), '0');
    // Place logs alongside test reports: <tests dir>/reports/aead_diag.log
    // Resolve based on executable location: <tests dir>/bin/tests_crypto.exe
    // so BaseDir = ..\reports relative to ParamStr(0)
    BaseDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + 'reports');
    try
      if not DirectoryExists(BaseDir) then
        SysUtils.ForceDirectories(BaseDir);
      GDiagPath := IncludeTrailingPathDelimiter(BaseDir) + 'aead_diag.log';
      // simple rotation: aead_diag.log -> aead_diag.prev.log
      if FileExists(GDiagPath) then
      begin
        Prev := IncludeTrailingPathDelimiter(BaseDir) + 'aead_diag.prev.log';
        try
          if FileExists(Prev) then
            SysUtils.DeleteFile(Prev);
          SysUtils.RenameFile(GDiagPath, Prev);
        except
          // ignore rotation errors
        end;
      end;
      // truncate file at start of run and write run header
      with TStringList.Create do
      try
        Add(Format('[%s] diag start', [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now)]));
        Add(Format('Run: Exe=%s', [ParamStr(0)]));
        {$IFDEF FAFAFA_FORCE_NO_ANON}
        Add('Mode: anon=OFF');
        {$ELSE}
        Add('Mode: anon=ON');
        {$ENDIF}
        Add(Format('ReportsDir: %s', [ExtractFilePath(GDiagPath)]));
        Add(Format('DiagEnv: FAFAFA_CORE_AEAD_DIAG=%s', [SysUtils.GetEnvironmentVariable('FAFAFA_CORE_AEAD_DIAG')]));
        Add(Format('DiagEnv: FAFAFA_CORE_AEAD_DIAG_VERBOSE=%s', [SysUtils.GetEnvironmentVariable('FAFAFA_CORE_AEAD_DIAG_VERBOSE')]));
        SaveToFile(GDiagPath);
      finally
        Free;
      end;
    except
      on E: Exception do ;
    end;
  end;
end;

procedure DiagDump(const ATitle: string; const AData: TBytes);
var
  S: TStringList;
  LTest, LTitle: string;
begin
  if not GDiagInited then DiagInit;
  if not GDiagEnabled then Exit;
  try
    S := TStringList.Create;
    try
      if FileExists(GDiagPath) then
        S.LoadFromFile(GDiagPath);
      LTest := SysUtils.GetEnvironmentVariable('FAFAFA_CURRENT_TEST');
      if GDiagVerbose and (LTest <> '') and (LTest <> GLastTestName) then
      begin
        S.Add('===');
        S.Add(Format('Case: %s (leaf=%s) (id=%0.16x)', [
          LTest,
          ExtractFileName(StringReplace(LTest, '/', DirectorySeparator, [rfReplaceAll])),
          _Hash64FNV1a(LTest)
        ]));
        GLastTestName := LTest;
      end;
      if LTest <> '' then LTitle := ATitle + ' [' + LTest + ']' else LTitle := ATitle;
      S.Add(Format('[%s] %s: %s', [
        FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
        LTitle,
        fafafa.core.crypto.BytesToHex(AData)
      ]));
      S.SaveToFile(GDiagPath);
    finally
      S.Free;
    end;
  except
    on E: Exception do ;
  end;
end;

procedure DiagDumpKV(const ATitle: string; const AKey, ANonce, AAAD, APT, ACT, ATag: TBytes);
var
  S: TStringList;
  LTest, LTitle: string;
begin
  if not GDiagInited then DiagInit;
  if not GDiagEnabled then Exit;
  try
    S := TStringList.Create;
    try
      if FileExists(GDiagPath) then
        S.LoadFromFile(GDiagPath);
      LTest := SysUtils.GetEnvironmentVariable('FAFAFA_CURRENT_TEST');
      if GDiagVerbose and (LTest <> '') and (LTest <> GLastTestName) then
      begin
        S.Add('===');
        S.Add(Format('Case: %s (leaf=%s) (id=%0.16x)', [
          LTest,
          ExtractFileName(StringReplace(LTest, '/', DirectorySeparator, [rfReplaceAll])),
          _Hash64FNV1a(LTest)
        ]));
        GLastTestName := LTest;
      end;
      S.Add('---');
      if LTest <> '' then LTitle := ATitle + ' [' + LTest + ']' else LTitle := ATitle;
      S.Add(Format('[%s] %s', [
        FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
        LTitle
      ]));
      S.Add('Key   = ' + fafafa.core.crypto.BytesToHex(AKey));
      S.Add('Nonce = ' + fafafa.core.crypto.BytesToHex(ANonce));
      S.Add(Format('AAD(len=%d)= %s', [Length(AAAD), fafafa.core.crypto.BytesToHex(AAAD)]));
      S.Add(Format('PT(len=%d) = %s', [Length(APT), fafafa.core.crypto.BytesToHex(APT)]));
      if Length(ACT) > 0 then
        S.Add(Format('CT(len=%d) = %s', [Length(ACT), fafafa.core.crypto.BytesToHex(ACT)]));
      if Length(ATag) > 0 then
        S.Add('TAG   = ' + fafafa.core.crypto.BytesToHex(ATag));
      S.SaveToFile(GDiagPath);
    finally
      S.Free;
    end;
  except
    on E: Exception do ;
  end;
end;

constructor TAESGCM.Create;
begin
  inherited Create;
  FKeySet := False;
  FTagLen := 16;
  SetLength(FKey, 0);
end;

procedure TAESGCM.SetTagLength(ATagLenBytes: Integer);
begin
  // NIST allows tag lengths {4..16} bytes, common: 12, 16
  if (ATagLenBytes < 4) or (ATagLenBytes > 16) then
    raise EInvalidArgument.Create('GCM tag length must be between 4 and 16 bytes');
  FTagLen := ATagLenBytes;
end;

function TAESGCM.GetName: string;
begin
  Result := 'AES-256-GCM';
end;

function TAESGCM.GetKeySize: Integer;
begin
  Result := 32;
end;

function TAESGCM.NonceSize: Integer;
begin
  Result := 12; // 96-bit
end;

function TAESGCM.Overhead: Integer;
begin
  Result := FTagLen;
end;

procedure TAESGCM.SetKey(const AKey: TBytes);
begin
  if Length(AKey) <> 32 then
    raise EInvalidKey.Create('AES-256-GCM expects 32-byte key');
  SetLength(FKey, 32);
  Move(AKey[0], FKey[0], 32);
  FKeySet := True;
end;

function TAESGCM.Seal(const ANonce, AAD, APlaintext: TBytes): TBytes;
var
  AES: ISymmetricCipher;
  H, S, EJ0, C: TBytes;
  CTR: IAESCTR;
  J0Block: array[0..15] of Byte;
  ZeroBlock: TBytes;
  GH: IGHash;
  OutLen, CLen: Integer;
  TagTrunc: TBytes;
begin
  {$hints off}
  // Initialize result and managed locals to silence compiler warnings
  Result := nil; H := nil; S := nil; EJ0 := nil; C := nil; SetLength(ZeroBlock, 0); SetLength(TagTrunc, 0);
  // also zero J0Block proactively for static analyzers, and ensure ZeroBlock/TagTrunc are empty
  FillChar(J0Block, SizeOf(J0Block), 0);
  SetLength(ZeroBlock, 0); SetLength(TagTrunc, 0);
  if not FKeySet then
    raise EInvalidOperation.Create('AES-256-GCM key not set');
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('AES-256-GCM requires 12-byte nonce (96-bit)');

  DiagInit;

  // 1) AES-ECB context for subkey and J0 encryption
  AES := CreateAES256;
  AES.SetKey(FKey);

  // H = AES_K(0^128)
  SetLength(ZeroBlock, 16);
  FillChar(ZeroBlock[0], 16, 0);
  H := AES.Encrypt(ZeroBlock);
  DiagDump('H', H);
  // secure zero the temporary ZeroBlock buffer
  SecureZeroBytes(ZeroBlock);
  SetLength(ZeroBlock, 0);

  // J0 = Nonce || 0^31 || 1
  FillChar(J0Block, SizeOf(J0Block), 0);
  Move(ANonce[0], J0Block[0], 12);
  J0Block[12] := 0; J0Block[13] := 0; J0Block[14] := 0; J0Block[15] := 1;
  SetLength(EJ0, 16); Move(J0Block[0], EJ0[0], 16);
  DiagDump('J0', EJ0);

  // 2) Encrypt: C = P XOR E_K(inc32(J0)) -> for 96-bit IV, first counter block = inc32(J0) = 2
  CTR := CreateAESCTR(32);
  CTR.SetKey(FKey);
  // GCM uses J0 for tag (E_K(J0)), and inc32(J0) as the first keystream block for payload
  CTR.SetNonceAndCounter(ANonce, 2);
  C := CTR.Process(APlaintext);
  DiagDump('C', C);

  // 3) GHASH over AAD || C and lengths
  GH := CreateGHash;
  GH.Init(H);
  {$IFNDEF DEBUG}
  // Warm up tables once (pure backend) to reduce cold-start latency for short messages
  GH.WarmUp;
  {$ENDIF}
  if Length(AAD) > 0 then GH.Update(AAD);
  if Length(C) > 0 then GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));
  DiagDump('S', S);

  // 4) Tag = E_K(J0) XOR S
  EJ0 := AES.Encrypt(EJ0);
  DiagDump('EJ0', EJ0);
  SetLength(TagTrunc, FTagLen);
  for OutLen := 0 to FTagLen - 1 do
    TagTrunc[OutLen] := EJ0[OutLen] xor S[OutLen];
  DiagDump('Tag', TagTrunc);

  // Build output: C || Tag[0..FTagLen-1]
  SetLength(Result, Length(C) + FTagLen);
  // ciphertext
  CLen := Length(C);
  if CLen > 0 then Move(C[0], Result[0], CLen);
  // tag (truncated)
  for OutLen := 0 to FTagLen - 1 do
    Result[CLen + OutLen] := TagTrunc[OutLen];

  // security: explicit zeroization of sensitive temporaries
  SecureZeroBytes(EJ0);
  SecureZeroBytes(H);
  SecureZeroBytes(S);
  SecureZeroBytes(TagTrunc);
  if CLen > 0 then SecureZeroBytes(C);
  FillChar(J0Block, SizeOf(J0Block), 0);
  GH.Reset;
  {$hints on}
end;

function TAESGCM.Open(const ANonce, AAD, ACiphertext: TBytes): TBytes;
var
  AES: ISymmetricCipher;
  H, S, EJ0, C, PT: TBytes;
  CTR: IAESCTR;
  J0Block: array[0..15] of Byte;
  ZeroBlock: TBytes;
  GH: IGHash;
  InLen, CLen: Integer;
  GivenTag, CalcTag: TBytes;
  i: Integer;
begin
  {$hints off}
  // Initialize result and managed locals
  Result := nil; H := nil; S := nil; EJ0 := nil; C := nil; PT := nil; SetLength(ZeroBlock, 0); SetLength(GivenTag, 0); SetLength(CalcTag, 0);
  FillChar(J0Block, SizeOf(J0Block), 0);
  if not FKeySet then
    raise EInvalidOperation.Create('AES-256-GCM key not set');
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('AES-256-GCM requires 12-byte nonce (96-bit)');
  InLen := Length(ACiphertext);
  if InLen < FTagLen then
    raise EInvalidData.Create('ciphertext too short');

  CLen := InLen - FTagLen;
  SetLength(C, CLen);
  if CLen > 0 then Move(ACiphertext[0], C[0], CLen);
  SetLength(GivenTag, FTagLen);
  Move(ACiphertext[CLen], GivenTag[0], FTagLen);

  // AES for H and EJ0
  AES := CreateAES256;
  AES.SetKey(FKey);

  SetLength(ZeroBlock, 16);
  FillChar(ZeroBlock[0], 16, 0);
  H := AES.Encrypt(ZeroBlock);
  DiagDump('H', H);
  SecureZeroBytes(ZeroBlock);
  SetLength(ZeroBlock, 0);

  FillChar(J0Block, SizeOf(J0Block), 0);
  Move(ANonce[0], J0Block[0], 12);
  J0Block[12] := 0; J0Block[13] := 0; J0Block[14] := 0; J0Block[15] := 1;

  GH := CreateGHash;
  GH.Init(H);
  {$IFNDEF DEBUG}
  // Warm up tables once (pure backend) to reduce cold-start latency for short messages
  GH.WarmUp;
  {$ENDIF}
  if Length(AAD) > 0 then GH.Update(AAD);
  if CLen > 0 then GH.Update(C);
  S := GH.Finalize(Length(AAD), CLen);
  DiagDump('S', S);

  SetLength(EJ0, 16); Move(J0Block[0], EJ0[0], 16);
  DiagDump('J0', EJ0);
  EJ0 := AES.Encrypt(EJ0);
  DiagDump('EJ0', EJ0);
  SetLength(CalcTag, FTagLen);
  for i := 0 to FTagLen - 1 do
    CalcTag[i] := EJ0[i] xor S[i];
  DiagDump('Tag', CalcTag);

  if not SecureCompare(CalcTag, GivenTag) then
  begin
    DiagDump('GivenTag', GivenTag);
    // security: clear sensitive buffers before raising
    SecureZeroBytes(CalcTag);
    SecureZeroBytes(GivenTag);
    SecureZeroBytes(EJ0);
    SecureZeroBytes(H);
    SecureZeroBytes(S);
    if CLen > 0 then SecureZeroBytes(C);
    FillChar(J0Block, SizeOf(J0Block), 0);
    GH.Reset;
    raise EInvalidData.Create('authentication tag mismatch');
  end;

  // Decrypt via CTR with initial counter = 2 (see Seal)
  CTR := CreateAESCTR(32);
  CTR.SetKey(FKey);
  CTR.SetNonceAndCounter(ANonce, 2);
  PT := CTR.Process(C);

  // security: clear sensitive buffers post-auth
  SecureZeroBytes(CalcTag);
  SecureZeroBytes(GivenTag);
  SecureZeroBytes(EJ0);
  SecureZeroBytes(H);
  SecureZeroBytes(S);
  if CLen > 0 then SecureZeroBytes(C);
  FillChar(J0Block, SizeOf(J0Block), 0);
  GH.Reset;

  Result := PT;
end;

procedure TAESGCM.Burn;
begin
  if Length(FKey) > 0 then
  begin
    FillChar(FKey[0], Length(FKey), 0);
    SetLength(FKey, 0);
  end;
  FKeySet := False;
  {$hints on}
end;

function TAESGCM.SealAppend(var ADst: TBytes; const ANonce, AAD, APlaintext: TBytes): Integer;
var
  AES: ISymmetricCipher;
  CTR: IAESCTR;
  GH: IGHash;
  H, S, EJ0, C, TagTrunc: TBytes;
  J0Block: array[0..15] of Byte;
  OldLen, L, CLen, I: Integer;
begin
  Result := 0;
  if not FKeySet then
    raise EInvalidOperation.Create('AES-256-GCM key not set');
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('AES-256-GCM requires 12-byte nonce (96-bit)');

  // 1) AES core and H/EJ0 precompute
  AES := CreateAES256; AES.SetKey(FKey);
  SetLength(H, 16); H := AES.Encrypt(TBytes.Create(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));
  FillChar(J0Block, SizeOf(J0Block), 0);
  Move(ANonce[0], J0Block[0], 12);
  J0Block[12] := 0; J0Block[13] := 0; J0Block[14] := 0; J0Block[15] := 1;
  SetLength(EJ0, 16); Move(J0Block[0], EJ0[0], 16);

  // 2) CTR encrypt PT -> C
  CTR := CreateAESCTR(32); CTR.SetKey(FKey); CTR.SetNonceAndCounter(ANonce, 2);
  C := CTR.Process(APlaintext);

  // 3) GHASH(AAD || C)
  GH := CreateGHash; GH.Init(H);
  {$IFNDEF DEBUG} GH.WarmUp; {$ENDIF}
  if Length(AAD) > 0 then GH.Update(AAD);
  if Length(C) > 0 then GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));

  // 4) Tag = E_K(J0) XOR S (truncated)
  EJ0 := AES.Encrypt(EJ0);
  SetLength(TagTrunc, FTagLen);
  for I := 0 to FTagLen - 1 do
    TagTrunc[I] := EJ0[I] xor S[I];

  // 5) Append C || Tag to ADst
  CLen := Length(C);
  OldLen := Length(ADst);
  SetLength(ADst, OldLen + CLen + FTagLen);
  if CLen > 0 then Move(C[0], ADst[OldLen], CLen);
  if FTagLen > 0 then Move(TagTrunc[0], ADst[OldLen + CLen], FTagLen);
  Result := CLen + FTagLen;

  // 6) Cleanup
  SecureZeroBytes(H); SecureZeroBytes(S); SecureZeroBytes(EJ0); SecureZeroBytes(TagTrunc);
  if Length(C) > 0 then SecureZeroBytes(C);
  FillChar(J0Block, SizeOf(J0Block), 0);
  GH.Reset;
end;

function TAESGCM.OpenAppend(var ADst: TBytes; const ANonce, AAD, ACiphertext: TBytes): Integer;
var
  AES: ISymmetricCipher;
  CTR: IAESCTR;
  GH: IGHash;
  H, S, EJ0, C, GivenTag, CalcTag, PT: TBytes;
  J0Block: array[0..15] of Byte;
  L, CLen, OldLen, I: Integer;
begin
  Result := 0;
  if not FKeySet then
    raise EInvalidOperation.Create('AES-256-GCM key not set');
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('AES-256-GCM requires 12-byte nonce (96-bit)');
  L := Length(ACiphertext);
  if L < FTagLen then
    raise EInvalidData.Create('ciphertext too short');

  CLen := L - FTagLen;
  SetLength(C, CLen); if CLen > 0 then Move(ACiphertext[0], C[0], CLen);
  SetLength(GivenTag, FTagLen); Move(ACiphertext[CLen], GivenTag[0], FTagLen);

  AES := CreateAES256; AES.SetKey(FKey);
  SetLength(H, 16); H := AES.Encrypt(TBytes.Create(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));
  FillChar(J0Block, SizeOf(J0Block), 0);
  Move(ANonce[0], J0Block[0], 12);
  J0Block[12] := 0; J0Block[13] := 0; J0Block[14] := 0; J0Block[15] := 1;

  GH := CreateGHash; GH.Init(H);
  {$IFNDEF DEBUG} GH.WarmUp; {$ENDIF}
  if Length(AAD) > 0 then GH.Update(AAD);
  if CLen > 0 then GH.Update(C);
  S := GH.Finalize(Length(AAD), CLen);

  SetLength(EJ0, 16); Move(J0Block[0], EJ0[0], 16);
  EJ0 := AES.Encrypt(EJ0);
  SetLength(CalcTag, FTagLen);
  for I := 0 to FTagLen - 1 do
    CalcTag[I] := EJ0[I] xor S[I];

  if not SecureCompare(CalcTag, GivenTag) then
    raise EInvalidData.Create('authentication tag mismatch');

  CTR := CreateAESCTR(32); CTR.SetKey(FKey); CTR.SetNonceAndCounter(ANonce, 2);
  PT := CTR.Process(C);

  OldLen := Length(ADst);
  SetLength(ADst, OldLen + Length(PT));
  if Length(PT) > 0 then Move(PT[0], ADst[OldLen], Length(PT));
  Result := Length(PT);

  SecureZeroBytes(H); SecureZeroBytes(S); SecureZeroBytes(EJ0);
  SecureZeroBytes(GivenTag); SecureZeroBytes(CalcTag);
  if CLen > 0 then SecureZeroBytes(C);
  FillChar(J0Block, SizeOf(J0Block), 0);
  GH.Reset;
end;

function TAESGCM.SealInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
var
  AES: ISymmetricCipher;
  CTR: IAESCTR;
  GH: IGHash;
  H, S, EJ0, C, TagTrunc: TBytes;
  J0Block: array[0..15] of Byte;
  L, I: Integer;
begin
  if not FKeySet then
    raise EInvalidOperation.Create('AES-256-GCM key not set');
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('AES-256-GCM requires 12-byte nonce (96-bit)');

  AES := CreateAES256; AES.SetKey(FKey);
  SetLength(H, 16); H := AES.Encrypt(TBytes.Create(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));
  FillChar(J0Block, SizeOf(J0Block), 0);
  Move(ANonce[0], J0Block[0], 12);
  J0Block[12] := 0; J0Block[13] := 0; J0Block[14] := 0; J0Block[15] := 1;

  CTR := CreateAESCTR(32); CTR.SetKey(FKey); CTR.SetNonceAndCounter(ANonce, 2);
  C := CTR.Process(AData);

  GH := CreateGHash; GH.Init(H);
  {$IFNDEF DEBUG} GH.WarmUp; {$ENDIF}
  if Length(AAD) > 0 then GH.Update(AAD);
  if Length(C) > 0 then GH.Update(C);
  S := GH.Finalize(Length(AAD), Length(C));

  SetLength(EJ0, 16); Move(J0Block[0], EJ0[0], 16);
  EJ0 := AES.Encrypt(EJ0);
  SetLength(TagTrunc, FTagLen);
  for I := 0 to FTagLen - 1 do
    TagTrunc[I] := EJ0[I] xor S[I];

  L := Length(C);
  SetLength(AData, L + FTagLen);
  if L > 0 then Move(C[0], AData[0], L);
  if FTagLen > 0 then Move(TagTrunc[0], AData[L], FTagLen);
  Result := L + FTagLen;

  SecureZeroBytes(H); SecureZeroBytes(S); SecureZeroBytes(EJ0); SecureZeroBytes(TagTrunc);
  if L > 0 then SecureZeroBytes(C);
  FillChar(J0Block, SizeOf(J0Block), 0);
  GH.Reset;
end;

function TAESGCM.OpenInPlace(var AData: TBytes; const ANonce, AAD: TBytes): Integer;
var
  AES: ISymmetricCipher;
  CTR: IAESCTR;
  GH: IGHash;
  H, S, EJ0, C, GivenTag, CalcTag, PT: TBytes;
  J0Block: array[0..15] of Byte;
  L, CLen, I: Integer;
begin
  if not FKeySet then
    raise EInvalidOperation.Create('AES-256-GCM key not set');
  if Length(ANonce) <> 12 then
    raise EInvalidArgument.Create('AES-256-GCM requires 12-byte nonce (96-bit)');
  L := Length(AData);
  if L < FTagLen then
    raise EInvalidData.Create('ciphertext too short');

  CLen := L - FTagLen;
  SetLength(C, CLen); if CLen > 0 then Move(AData[0], C[0], CLen);
  SetLength(GivenTag, FTagLen); Move(AData[CLen], GivenTag[0], FTagLen);

  AES := CreateAES256; AES.SetKey(FKey);
  SetLength(H, 16); H := AES.Encrypt(TBytes.Create(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));
  FillChar(J0Block, SizeOf(J0Block), 0);
  Move(ANonce[0], J0Block[0], 12);
  J0Block[12] := 0; J0Block[13] := 0; J0Block[14] := 0; J0Block[15] := 1;

  GH := CreateGHash; GH.Init(H);
  {$IFNDEF DEBUG} GH.WarmUp; {$ENDIF}
  // GHASH order must be: AAD first, then C (spec: GHASH(H, A || C))
  if Length(AAD) > 0 then GH.Update(AAD);
  if CLen > 0 then GH.Update(C);
  S := GH.Finalize(Length(AAD), CLen);

  SetLength(EJ0, 16); Move(J0Block[0], EJ0[0], 16);
  EJ0 := AES.Encrypt(EJ0);
  SetLength(CalcTag, FTagLen);
  for I := 0 to FTagLen - 1 do
    CalcTag[I] := EJ0[I] xor S[I];

  if not SecureCompare(CalcTag, GivenTag) then
    raise EInvalidData.Create('authentication tag mismatch');

  CTR := CreateAESCTR(32); CTR.SetKey(FKey); CTR.SetNonceAndCounter(ANonce, 2);
  PT := CTR.Process(C);
  SetLength(AData, Length(PT));
  if Length(PT) > 0 then Move(PT[0], AData[0], Length(PT));
  Result := Length(PT);

  SecureZeroBytes(H); SecureZeroBytes(S); SecureZeroBytes(EJ0);
  SecureZeroBytes(GivenTag); SecureZeroBytes(CalcTag);
  if CLen > 0 then SecureZeroBytes(C);
  FillChar(J0Block, SizeOf(J0Block), 0);
  GH.Reset;
end;



function CreateAES256GCM_Impl: IAEADCipher;
begin
  Result := TAESGCM.Create;
end;

end.

