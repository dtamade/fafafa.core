unit fafafa.core.simd.cpuinfo.riscv;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_RISCV_AVAILABLE}

uses
  fafafa.core.simd.cpuinfo.base;

type
  TRISCVProcessorInfo = record
    Architecture: string;
    ISA: string;
    XLEN: Integer;
  end;

function DetectRISCVFeatures: TRISCVFeatures;
procedure DetectRISCVVendorAndModel(var cpuInfo: TCPUInfo);
function GetRISCVProcessorInfo: TRISCVProcessorInfo;
function ExtractBestRISCVISAFromCpuInfo(const aCpuInfo: string; var aISA: string; var aFeatures: TRISCVFeatures): Boolean;
procedure MergeRISCVFeaturesFromLinuxHWCAP(var aFeatures: TRISCVFeatures; const aHWCAP, aHWCAP2: QWord);
function ParseRISCVVendorModelFromCpuInfo(const aCpuInfo: string; var aVendor, aModel: string): Boolean;
function ParseRISCVFeaturesFromCpuInfo(const cpuInfo: string): TRISCVFeatures;

{$ENDIF}

implementation

{$IFDEF SIMD_RISCV_AVAILABLE}

uses
  SysUtils
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF};

function NormalizeRISCVFieldValueLocal(const aValue: string): string;
begin
  Result := Trim(aValue);
  if Length(Result) >= 2 then
    if ((Result[1] = '"') and (Result[Length(Result)] = '"')) or
       ((Result[1] = '''') and (Result[Length(Result)] = '''')) then
      Result := Copy(Result, 2, Length(Result) - 2);
end;

function SplitRISCVKeyValueLineLocal(const aLine: string; var aKey, aValue: string): Boolean;
var
  LColonPos: Integer;
  LEqualPos: Integer;
  LSeparatorPos: Integer;
begin
  aKey := '';
  aValue := '';
  LColonPos := Pos(':', aLine);
  LEqualPos := Pos('=', aLine);
  if (LColonPos > 0) and ((LEqualPos = 0) or (LColonPos < LEqualPos)) then
    LSeparatorPos := LColonPos
  else
    LSeparatorPos := LEqualPos;
  Result := LSeparatorPos > 0;
  if not Result then
    Exit;

  aKey := Trim(LowerCase(Copy(aLine, 1, LSeparatorPos - 1)));
  aValue := NormalizeRISCVFieldValueLocal(Copy(aLine, LSeparatorPos + 1, MaxInt));
end;

function TryParseRISCVQWordLocal(const aText: string; out aValue: QWord): Boolean;
var
  LText: string;
  LCode: Integer;
begin
  aValue := 0;
  LText := LowerCase(Trim(aText));
  LText := StringReplace(LText, '_', '', [rfReplaceAll]);
  if (LText = '') or (LText[1] = '-') then
    Exit(False);
  if Copy(LText, 1, 2) = '0x' then
    LText := '$' + Copy(LText, 3, MaxInt);
  Val(LText, aValue, LCode);
  Result := LCode = 0;
end;

function IsRISCVNumericProcessorIndexLocal(const aValue: string): Boolean;
var
  LIgnored: QWord;
begin
  Result := TryParseRISCVQWordLocal(aValue, LIgnored);
end;

procedure IncludeRISCVCompactExtensionLocal(var aFeatures: TRISCVFeatures; const aExtension: Char);
begin
  case aExtension of
    'g':
      begin
        aFeatures.HasM := True;
        aFeatures.HasA := True;
        aFeatures.HasF := True;
        aFeatures.HasD := True;
      end;
    'm': aFeatures.HasM := True;
    'a': aFeatures.HasA := True;
    'f': aFeatures.HasF := True;
    'd': aFeatures.HasD := True;
    'c': aFeatures.HasC := True;
    'v': aFeatures.HasV := True;
  end;
end;

function RISCVTokenImpliesVectorLocal(const aToken: string): Boolean;
begin
  if Pos('zve', aToken) = 1 then
    Exit((Length(aToken) > 3) and (aToken[4] in ['0'..'9']));
  if Pos('zvl', aToken) = 1 then
    Exit((Length(aToken) > 3) and (aToken[4] in ['0'..'9']));
  if Pos('zv', aToken) = 1 then
    Exit((Length(aToken) > 2) and (aToken[3] in ['a'..'z']));
  Result := False;
end;

function IsRISCVAlphaNumTokenLocal(const aToken: string): Boolean;
var
  LIndex: Integer;
begin
  Result := aToken <> '';
  if not Result then
    Exit;
  for LIndex := 1 to Length(aToken) do
    if not (aToken[LIndex] in ['a'..'z', '0'..'9']) then
      Exit(False);
end;

function HasRISCVVersionSuffixLocal(const aSuffix: string): Boolean;
var
  LIndex: Integer;
begin
  if aSuffix = '' then
    Exit(False);

  Result := False;
  for LIndex := 1 to Length(aSuffix) do
  begin
    if aSuffix[LIndex] = 'p' then
      Result := True
    else if not (aSuffix[LIndex] in ['0'..'9', '.']) then
      Exit(False);
  end;
end;

function TryParseRISCVSingleLetterExtensionTokenLocal(const aToken: string; var aFeatures: TRISCVFeatures): Boolean;
var
  LExtension: Char;
  LSuffix: string;
begin
  Result := False;
  if aToken = '' then
    Exit;

  LExtension := aToken[1];
  if not (LExtension in ['g', 'm', 'a', 'f', 'd', 'c', 'v']) then
    Exit;

  LSuffix := Copy(aToken, 2, MaxInt);
  if (LSuffix <> '') and (not HasRISCVVersionSuffixLocal(LSuffix)) then
    Exit;

  IncludeRISCVCompactExtensionLocal(aFeatures, LExtension);
  Result := True;
end;

function TryParseRISCVISATokensLocal(
  const aText: string;
  const aAllowExtensionOnly: Boolean;
  const aRejectUnknownTokens: Boolean;
  out aFeatures: TRISCVFeatures;
  out aHasBase: Boolean
): Boolean;
var
  LText: string;
  LTokens: TStringArray;
  LToken: string;
  LRest: string;
  LIndex: Integer;
  LRecognized: Boolean;
begin
  FillChar(aFeatures, SizeOf(aFeatures), 0);
  aHasBase := False;
  Result := False;
  LText := NormalizeRISCVFieldValueLocal(LowerCase(Trim(aText)));
  if LText = '' then
    Exit;

  LText := StringReplace(LText, ',', ' ', [rfReplaceAll]);
  LText := StringReplace(LText, ';', ' ', [rfReplaceAll]);
  LText := StringReplace(LText, #9, ' ', [rfReplaceAll]);
  LText := StringReplace(LText, '_', ' ', [rfReplaceAll]);
  LTokens := LText.Split([' ']);
  for LToken in LTokens do
  begin
    if LToken = '' then
      Continue;

    LRecognized := False;

    if (Pos('rv64', LToken) = 1) or (Pos('rv32', LToken) = 1) then
    begin
      if Pos('rv64', LToken) = 1 then
      begin
        aFeatures.HasRV64I := True;
        aFeatures.HasRV32I := False;
      end
      else
      begin
        aFeatures.HasRV32I := True;
        aFeatures.HasRV64I := False;
      end;
      aHasBase := True;
      LRest := Copy(LToken, 5, MaxInt);
      for LIndex := 1 to Length(LRest) do
        if LRest[LIndex] in ['i', 'g', 'm', 'a', 'f', 'd', 'c', 'v'] then
          IncludeRISCVCompactExtensionLocal(aFeatures, LRest[LIndex]);
      LRecognized := True;
    end
    else if TryParseRISCVSingleLetterExtensionTokenLocal(LToken, aFeatures) then
      LRecognized := True
    else if RISCVTokenImpliesVectorLocal(LToken) and IsRISCVAlphaNumTokenLocal(LToken) then
    begin
      aFeatures.HasV := True;
      LRecognized := True;
    end;

    if LRecognized then
    begin
      Result := True;
      Continue;
    end;

    if aRejectUnknownTokens then
      Exit(False);
  end;

  if not Result then
    Exit(False);
  if aHasBase then
    Exit(True);
  Result := aAllowExtensionOnly;
end;

procedure NormalizeRISCVBaselineForTargetLocal(var aFeatures: TRISCVFeatures);
begin
  {$IFDEF CPURISCV64}
  aFeatures.HasRV64I := True;
  aFeatures.HasRV32I := False;
  {$ELSEIF DEFINED(CPURISCV32)}
  aFeatures.HasRV32I := True;
  aFeatures.HasRV64I := False;
  {$ENDIF}
end;

function BuildCanonicalRISCVISALocal(const aFeatures: TRISCVFeatures): string;
begin
  if aFeatures.HasRV64I then
    Result := 'rv64i'
  else if aFeatures.HasRV32I then
    Result := 'rv32i'
  else
    Exit('');

  if aFeatures.HasM then
    Result := Result + 'm';
  if aFeatures.HasA then
    Result := Result + 'a';
  if aFeatures.HasF then
    Result := Result + 'f';
  if aFeatures.HasD then
    Result := Result + 'd';
  if aFeatures.HasC then
    Result := Result + 'c';
  if aFeatures.HasV then
    Result := Result + 'v';
end;

function TryDecodeRISCVMISAValueLocal(const aText: string; out aFeatures: TRISCVFeatures): Boolean;
var
  LMisa: QWord;
  LMXL: QWord;
begin
  FillChar(aFeatures, SizeOf(aFeatures), 0);
  if not TryParseRISCVQWordLocal(aText, LMisa) then
    Exit(False);

  if (LMisa and QWord($C000000000000000)) <> 0 then
  begin
    LMXL := (LMisa shr 62) and QWord(3);
    if LMXL = 2 then
      aFeatures.HasRV64I := True
    else if LMXL = 1 then
      aFeatures.HasRV32I := True;
  end
  else if (LMisa and QWord($C0000000)) <> 0 then
  begin
    LMXL := (LMisa shr 30) and QWord(3);
    if LMXL = 1 then
      aFeatures.HasRV32I := True
    else if LMXL = 2 then
      aFeatures.HasRV64I := True;
  end;

  aFeatures.HasM := (LMisa and (QWord(1) shl (Ord('M') - Ord('A')))) <> 0;
  aFeatures.HasA := (LMisa and (QWord(1) shl (Ord('A') - Ord('A')))) <> 0;
  aFeatures.HasF := (LMisa and (QWord(1) shl (Ord('F') - Ord('A')))) <> 0;
  aFeatures.HasD := (LMisa and (QWord(1) shl (Ord('D') - Ord('A')))) <> 0;
  aFeatures.HasC := (LMisa and (QWord(1) shl (Ord('C') - Ord('A')))) <> 0;
  aFeatures.HasV := (LMisa and (QWord(1) shl (Ord('V') - Ord('A')))) <> 0;
  Result := aFeatures.HasRV32I or aFeatures.HasRV64I;
end;

procedure MergeRISCVFeatureFlagsLocal(var aTarget: TRISCVFeatures; const aSource: TRISCVFeatures);
begin
  aTarget.HasRV32I := aTarget.HasRV32I or aSource.HasRV32I;
  aTarget.HasRV64I := aTarget.HasRV64I or aSource.HasRV64I;
  aTarget.HasM := aTarget.HasM or aSource.HasM;
  aTarget.HasA := aTarget.HasA or aSource.HasA;
  aTarget.HasF := aTarget.HasF or aSource.HasF;
  aTarget.HasD := aTarget.HasD or aSource.HasD;
  aTarget.HasC := aTarget.HasC or aSource.HasC;
  aTarget.HasV := aTarget.HasV or aSource.HasV;
  if aTarget.LinuxHWCAP = 0 then
    aTarget.LinuxHWCAP := aSource.LinuxHWCAP;
  if aTarget.LinuxHWCAP2 = 0 then
    aTarget.LinuxHWCAP2 := aSource.LinuxHWCAP2;
end;

function IsRISCVNumericMISAKeyLocal(const aKey: string): Boolean;
begin
  Result := (aKey = 'misa') or
            (aKey = 'csr misa') or
            (aKey = 'riscv,misa') or
            (aKey = 'misa register') or
            (aKey = 'misa csr');
end;

function TryGetRISCVISAKeyModeLocal(const aKey: string; out aAllowExtensionOnly, aRejectUnknownTokens: Boolean; out aPriority: Integer): Boolean;
begin
  aAllowExtensionOnly := False;
  aRejectUnknownTokens := False;
  aPriority := -1;

  if aKey = 'riscv,isa' then
    aPriority := 40
  else if (aKey = 'isa') or (aKey = 'isa string') or (aKey = 'hart isa') or
          (aKey = 'march') or (aKey = 'riscv,march') or (aKey = 'riscv march') then
    aPriority := 30
  else if (aKey = 'isa extensions') or (aKey = 'riscv isa extensions') or
          (aKey = 'riscv,isa extensions') or (aKey = 'riscv_isa_ext') or
          (aKey = 'isa_ext') then
  begin
    aPriority := 20;
    aAllowExtensionOnly := True;
  end
  else if (aKey = 'extensions') or (aKey = 'riscv extensions') then
  begin
    aPriority := 10;
    aAllowExtensionOnly := True;
    aRejectUnknownTokens := True;
  end;

  Result := aPriority >= 0;
end;

procedure MergeRISCVFeaturesFromLinuxHWCAP(var aFeatures: TRISCVFeatures; const aHWCAP, aHWCAP2: QWord);
begin
  aFeatures.LinuxHWCAP := aHWCAP;
  aFeatures.LinuxHWCAP2 := aHWCAP2;

  if (aHWCAP and (QWord(1) shl (Ord('I') - Ord('A')))) <> 0 then
    NormalizeRISCVBaselineForTargetLocal(aFeatures);
  if (aHWCAP and (QWord(1) shl (Ord('M') - Ord('A')))) <> 0 then
    aFeatures.HasM := True;
  if (aHWCAP and (QWord(1) shl (Ord('A') - Ord('A')))) <> 0 then
    aFeatures.HasA := True;
  if (aHWCAP and (QWord(1) shl (Ord('F') - Ord('A')))) <> 0 then
    aFeatures.HasF := True;
  if (aHWCAP and (QWord(1) shl (Ord('D') - Ord('A')))) <> 0 then
    aFeatures.HasD := True;
  if (aHWCAP and (QWord(1) shl (Ord('C') - Ord('A')))) <> 0 then
    aFeatures.HasC := True;
  if (aHWCAP and (QWord(1) shl (Ord('V') - Ord('A')))) <> 0 then
    aFeatures.HasV := True;
end;

function ParseRISCVVendorModelFromCpuInfo(const aCpuInfo: string; var aVendor, aModel: string): Boolean;
var
  LLines: TStringArray;
  LLine: string;
  LTrimmedLine: string;
  LKey: string;
  LValue: string;
  LVendorPriority: Integer;
  LModelPriority: Integer;
begin
  aVendor := '';
  aModel := '';
  if aCpuInfo = '' then
    Exit(False);

  LVendorPriority := -1;
  LModelPriority := -1;
  LLines := aCpuInfo.Split([#10, #13]);
  for LLine in LLines do
  begin
    LTrimmedLine := Trim(LLine);
    if (LTrimmedLine = '') or (not SplitRISCVKeyValueLineLocal(LTrimmedLine, LKey, LValue)) or (LValue = '') then
      Continue;

    if ((LKey = 'vendor_id') or (LKey = 'vendor')) and (LVendorPriority < 3) then
    begin
      aVendor := LValue;
      LVendorPriority := 3;
    end
    else if (LKey = 'soc') and (LVendorPriority < 2) then
    begin
      aVendor := LValue;
      LVendorPriority := 2;
    end;

    if ((LKey = 'model name') or (LKey = 'cpu model')) and (LModelPriority < 3) then
    begin
      aModel := LValue;
      LModelPriority := 3;
    end
    else if (LKey = 'uarch') and (LModelPriority < 2) then
    begin
      aModel := LValue;
      LModelPriority := 2;
    end
    else if (LKey = 'model') and (LModelPriority < 1) then
    begin
      aModel := LValue;
      LModelPriority := 1;
    end
    else if (LKey = 'processor') and (LModelPriority < 0) and (not IsRISCVNumericProcessorIndexLocal(LValue)) then
    begin
      aModel := LValue;
      LModelPriority := 0;
    end;
  end;

  Result := (aVendor <> '') or (aModel <> '');
end;

function ExtractBestRISCVISAFromCpuInfo(const aCpuInfo: string; var aISA: string; var aFeatures: TRISCVFeatures): Boolean;
var
  LLines: TStringArray;
  LLine: string;
  LTrimmedLine: string;
  LKey: string;
  LValue: string;
  LCandidate: TRISCVFeatures;
  LMisaFeatures: TRISCVFeatures;
  LBaseCandidate: TRISCVFeatures;
  LExtOnlyCandidate: TRISCVFeatures;
  LFinalFeatures: TRISCVFeatures;
  LHasBase: Boolean;
  LHasMisa: Boolean;
  LHasBaseCandidate: Boolean;
  LHasExtOnlyCandidate: Boolean;
  LAllowExtensionOnly: Boolean;
  LRejectUnknownTokens: Boolean;
  LPriority: Integer;
  LBestBasePriority: Integer;
  LBestExtPriority: Integer;
begin
  aISA := '';
  FillChar(aFeatures, SizeOf(aFeatures), 0);
  FillChar(LMisaFeatures, SizeOf(LMisaFeatures), 0);
  FillChar(LBaseCandidate, SizeOf(LBaseCandidate), 0);
  FillChar(LExtOnlyCandidate, SizeOf(LExtOnlyCandidate), 0);
  LHasMisa := False;
  LHasBaseCandidate := False;
  LHasExtOnlyCandidate := False;
  LBestBasePriority := -1;
  LBestExtPriority := -1;

  LLines := aCpuInfo.Split([#10, #13]);
  for LLine in LLines do
  begin
    LTrimmedLine := Trim(LLine);
    if (LTrimmedLine = '') or (not SplitRISCVKeyValueLineLocal(LTrimmedLine, LKey, LValue)) or (LValue = '') then
      Continue;

    if IsRISCVNumericMISAKeyLocal(LKey) then
    begin
      if TryDecodeRISCVMISAValueLocal(LValue, LMisaFeatures) then
        LHasMisa := True;
      Continue;
    end;

    if not TryGetRISCVISAKeyModeLocal(LKey, LAllowExtensionOnly, LRejectUnknownTokens, LPriority) then
      Continue;

    if not TryParseRISCVISATokensLocal(LValue, LAllowExtensionOnly, LRejectUnknownTokens, LCandidate, LHasBase) then
      Continue;

    if LHasBase then
    begin
      if LPriority > LBestBasePriority then
      begin
        LBaseCandidate := LCandidate;
        LBestBasePriority := LPriority;
        LHasBaseCandidate := True;
      end;
    end
    else if LPriority > LBestExtPriority then
    begin
      LExtOnlyCandidate := LCandidate;
      LBestExtPriority := LPriority;
      LHasExtOnlyCandidate := True;
    end;
  end;

  FillChar(LFinalFeatures, SizeOf(LFinalFeatures), 0);
  if LHasBaseCandidate then
  begin
    LFinalFeatures := LBaseCandidate;
    if LHasMisa then
    begin
      LFinalFeatures.HasM := LFinalFeatures.HasM or LMisaFeatures.HasM;
      LFinalFeatures.HasA := LFinalFeatures.HasA or LMisaFeatures.HasA;
      LFinalFeatures.HasF := LFinalFeatures.HasF or LMisaFeatures.HasF;
      LFinalFeatures.HasD := LFinalFeatures.HasD or LMisaFeatures.HasD;
      LFinalFeatures.HasC := LFinalFeatures.HasC or LMisaFeatures.HasC;
      LFinalFeatures.HasV := LFinalFeatures.HasV or LMisaFeatures.HasV;
      if (LBaseCandidate.HasRV32I <> LMisaFeatures.HasRV32I) or (LBaseCandidate.HasRV64I <> LMisaFeatures.HasRV64I) then
        NormalizeRISCVBaselineForTargetLocal(LFinalFeatures);
    end;
  end
  else if LHasExtOnlyCandidate and LHasMisa then
  begin
    LFinalFeatures := LMisaFeatures;
    LFinalFeatures.HasM := LFinalFeatures.HasM or LExtOnlyCandidate.HasM;
    LFinalFeatures.HasA := LFinalFeatures.HasA or LExtOnlyCandidate.HasA;
    LFinalFeatures.HasF := LFinalFeatures.HasF or LExtOnlyCandidate.HasF;
    LFinalFeatures.HasD := LFinalFeatures.HasD or LExtOnlyCandidate.HasD;
    LFinalFeatures.HasC := LFinalFeatures.HasC or LExtOnlyCandidate.HasC;
    LFinalFeatures.HasV := LFinalFeatures.HasV or LExtOnlyCandidate.HasV;
  end
  else if LHasMisa then
    LFinalFeatures := LMisaFeatures
  else
    Exit(False);

  aISA := BuildCanonicalRISCVISALocal(LFinalFeatures);
  if aISA = '' then
    Exit(False);
  aFeatures := LFinalFeatures;
  Result := True;
end;

function DetectRISCVFeatures: TRISCVFeatures;
{$IFDEF UNIX}
var
  LCpuInfoContent: string;
  LFile: TextFile;
  LLine: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);

  {$IFDEF UNIX}
  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(LFile, '/proc/cpuinfo');
      Reset(LFile);
      LCpuInfoContent := '';
      while not Eof(LFile) do
      begin
        ReadLn(LFile, LLine);
        LCpuInfoContent := LCpuInfoContent + LLine + #10;
      end;
      CloseFile(LFile);
      Result := ParseRISCVFeaturesFromCpuInfo(LCpuInfoContent);
    end;
  except
  end;
  {$ENDIF}

  if not (Result.HasRV32I or Result.HasRV64I) then
    NormalizeRISCVBaselineForTargetLocal(Result);
end;

procedure DetectRISCVVendorAndModel(var cpuInfo: TCPUInfo);
{$IFDEF UNIX}
var
  LFile: TextFile;
  LLine: string;
  LCpuInfoContent: string;
{$ENDIF}
begin
  cpuInfo.Vendor := 'RISC-V';
  cpuInfo.Model := 'RISC-V Processor';

  {$IFDEF UNIX}
  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(LFile, '/proc/cpuinfo');
      Reset(LFile);
      LCpuInfoContent := '';
      while not Eof(LFile) do
      begin
        ReadLn(LFile, LLine);
        LCpuInfoContent := LCpuInfoContent + LLine + #10;
      end;
      CloseFile(LFile);
      ParseRISCVVendorModelFromCpuInfo(LCpuInfoContent, cpuInfo.Vendor, cpuInfo.Model);
    end;
  except
  end;
  {$ENDIF}
end;

function GetRISCVProcessorInfo: TRISCVProcessorInfo;
{$IFDEF UNIX}
var
  LCpuInfoContent: string;
  LFile: TextFile;
  LLine: string;
  LISA: string;
  LFeatures: TRISCVFeatures;
{$ENDIF}
begin
  Result.Architecture := '';
  Result.ISA := '';
  Result.XLEN := 0;

  {$IFDEF CPURISCV64}
  Result.Architecture := 'RV64';
  Result.XLEN := 64;
  Result.ISA := 'rv64i';
  {$ELSE}
  Result.Architecture := 'RV32';
  Result.XLEN := 32;
  Result.ISA := 'rv32i';
  {$ENDIF}

  {$IFDEF UNIX}
  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(LFile, '/proc/cpuinfo');
      Reset(LFile);
      LCpuInfoContent := '';
      while not Eof(LFile) do
      begin
        ReadLn(LFile, LLine);
        LCpuInfoContent := LCpuInfoContent + LLine + #10;
      end;
      CloseFile(LFile);

      LISA := '';
      FillChar(LFeatures, SizeOf(LFeatures), 0);
      if ExtractBestRISCVISAFromCpuInfo(LCpuInfoContent, LISA, LFeatures) then
      begin
        Result.ISA := LISA;
        if LFeatures.HasRV64I then
        begin
          Result.Architecture := 'RV64';
          Result.XLEN := 64;
        end
        else if LFeatures.HasRV32I then
        begin
          Result.Architecture := 'RV32';
          Result.XLEN := 32;
        end;
      end;
    end;
  except
  end;
  {$ENDIF}
end;

function ParseRISCVFeaturesFromCpuInfo(const cpuInfo: string): TRISCVFeatures;
var
  LLines: TStringArray;
  LLine: string;
  LTrimmedLine: string;
  LKey: string;
  LValue: string;
  LCandidate: TRISCVFeatures;
  LMisaFeatures: TRISCVFeatures;
  LHasBase: Boolean;
  LHasMisa: Boolean;
  LAllowExtensionOnly: Boolean;
  LRejectUnknownTokens: Boolean;
  LPriority: Integer;
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
  FillChar(LMisaFeatures, SizeOf(TRISCVFeatures), 0);
  LHasMisa := False;
  if cpuInfo = '' then
    Exit;

  LLines := cpuInfo.Split([#10, #13]);
  for LLine in LLines do
  begin
    LTrimmedLine := Trim(LLine);
    if (LTrimmedLine = '') or (not SplitRISCVKeyValueLineLocal(LTrimmedLine, LKey, LValue)) or (LValue = '') then
      Continue;

    if IsRISCVNumericMISAKeyLocal(LKey) then
    begin
      if TryDecodeRISCVMISAValueLocal(LValue, LCandidate) then
      begin
        MergeRISCVFeatureFlagsLocal(LMisaFeatures, LCandidate);
        LHasMisa := True;
      end;
      Continue;
    end;

    if not TryGetRISCVISAKeyModeLocal(LKey, LAllowExtensionOnly, LRejectUnknownTokens, LPriority) then
      Continue;

    if TryParseRISCVISATokensLocal(LValue, LAllowExtensionOnly, LRejectUnknownTokens, LCandidate, LHasBase) then
      MergeRISCVFeatureFlagsLocal(Result, LCandidate);
  end;

  if LHasMisa then
    MergeRISCVFeatureFlagsLocal(Result, LMisaFeatures);

  if Result.HasRV32I and Result.HasRV64I then
    NormalizeRISCVBaselineForTargetLocal(Result);
end;

{$ELSE}

function DetectRISCVFeatures: TRISCVFeatures;
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
end;

procedure DetectRISCVVendorAndModel(var cpuInfo: TCPUInfo);
begin
  cpuInfo.Vendor := 'Non-RISC-V';
  cpuInfo.Model := 'Non-RISC-V Processor';
end;

function GetRISCVProcessorInfo: TRISCVProcessorInfo;
begin
  FillChar(Result, SizeOf(TRISCVProcessorInfo), 0);
  Result.Architecture := 'Non-RISC-V';
  Result.ISA := 'Non-RISC-V';
  Result.XLEN := 0;
end;

function ExtractBestRISCVISAFromCpuInfo(const aCpuInfo: string; var aISA: string; var aFeatures: TRISCVFeatures): Boolean;
begin
  aISA := '';
  FillChar(aFeatures, SizeOf(aFeatures), 0);
  Result := False;
end;

procedure MergeRISCVFeaturesFromLinuxHWCAP(var aFeatures: TRISCVFeatures; const aHWCAP, aHWCAP2: QWord);
begin
  if (aHWCAP <> 0) or (aHWCAP2 <> 0) then
    ;
  FillChar(aFeatures, SizeOf(aFeatures), 0);
end;

function ParseRISCVVendorModelFromCpuInfo(const aCpuInfo: string; var aVendor, aModel: string): Boolean;
begin
  aVendor := '';
  aModel := '';
  Result := False;
end;

function ParseRISCVFeaturesFromCpuInfo(const cpuInfo: string): TRISCVFeatures;
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
end;

{$ENDIF}

end.
