unit fafafa.core.simd.cpuinfo.arm;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_ARM_AVAILABLE}

uses
  SysUtils, StrUtils,
  fafafa.core.simd.cpuinfo.base;

type
  TARMProcessorInfo = record
    Architecture: string;
    InstructionSet: string;
    CoreType: string;
  end;

function DetectARMFeatures: TARMFeatures;
procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);
function IsNEONAvailable: Boolean;
function IsAdvSIMDAvailable: Boolean;
function IsSVEAvailable: Boolean;
function GetARMProcessorInfo: TARMProcessorInfo;

procedure MergeARMFeaturesFromLinuxHWCAP(var aFeatures: TARMFeatures; const aHWCAP, aHWCAP2: QWord);
function ParseARMProcessorInfoFromCpuInfo(const aCpuInfo: string; var aInstructionSet, aCoreType: string): Boolean;

{$IFDEF UNIX}
function ReadProcCpuInfoSafe: string;
function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
function ParseARMVendorFromCpuInfo(const cpuInfo: string; var vendor, model: string): Boolean;
{$ENDIF}

implementation

{$IFDEF UNIX}
uses
  BaseUnix;
{$ENDIF}

function NormalizeARMFieldValueLocal(const aValue: string): string;
begin
  Result := Trim(aValue);
  if Length(Result) >= 2 then
    if ((Result[1] = '"') and (Result[Length(Result)] = '"')) or
       ((Result[1] = '''') and (Result[Length(Result)] = '''')) then
      Result := Copy(Result, 2, Length(Result) - 2);
end;

function SplitARMKeyValueLineLocal(const aLine: string; var aKey, aValue: string): Boolean;
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
  aValue := NormalizeARMFieldValueLocal(Copy(aLine, LSeparatorPos + 1, MaxInt));
end;

function NormalizeARMInstructionSetLocal(const aValue: string): string;
var
  LValue: string;
begin
  LValue := LowerCase(Trim(aValue));
  if LValue = '' then
    Exit('');

  if (LValue = '9') or (Pos('armv9', LValue) > 0) then
    Exit('ARMv9-A');
  if (LValue = '8') or (Pos('armv8', LValue) > 0) or (Pos('arm64', LValue) > 0) or (Pos('aarch64', LValue) > 0) then
    Exit('ARMv8-A');
  if (LValue = '7') or (Pos('armv7', LValue) > 0) then
    Exit('ARMv7-A');
  if (LValue = '6') or (Pos('armv6', LValue) > 0) then
    Exit('ARMv6');

  Result := '';
end;

function NormalizeARMCoreTypeLocal(const aValue: string): string;
var
  LValue: string;
begin
  LValue := LowerCase(Trim(aValue));
  if LValue = '' then
    Exit('');

  if Pos('cortex-a', LValue) > 0 then
    Exit('Cortex-A');
  if Pos('cortex-r', LValue) > 0 then
    Exit('Cortex-R');
  if Pos('cortex-m', LValue) > 0 then
    Exit('Cortex-M');
  if Pos('neoverse', LValue) > 0 then
    Exit('Neoverse');
  if Pos('kryo', LValue) > 0 then
    Exit('Kryo');

  Result := '';
end;

function IsARMFeatureLikeKeyLocal(const aKey: string): Boolean;
begin
  Result := (aKey = 'features') or
            (aKey = 'flags') or
            (aKey = 'cpu features') or
            (aKey = 'cpu feature') or
            (aKey = 'cpu feature(s)') or
            (aKey = 'extensions') or
            (aKey = 'isa extension(s)') or
            (aKey = 'isa_ext') or
            (aKey = 'capabilities') or
            (aKey = 'caps') or
            (aKey = 'caps2');
end;

function TryExtractARMFeatureValueWithoutSeparatorLocal(const aLine: string; out aValue: string): Boolean;
var
  LLine: string;

  function MatchPrefix(const aPrefix: string): Boolean;
  begin
    Result := (Copy(LLine, 1, Length(aPrefix)) = aPrefix) and
              (Length(LLine) > Length(aPrefix)) and
              (LLine[Length(aPrefix) + 1] in [' ', #9]);
    if Result then
      aValue := Trim(Copy(LLine, Length(aPrefix) + 1, MaxInt));
  end;
begin
  aValue := '';
  LLine := LowerCase(Trim(aLine));
  if LLine = '' then
    Exit(False);

  Result := MatchPrefix('cpu feature(s)') or
            MatchPrefix('cpu features') or
            MatchPrefix('isa extension(s)') or
            MatchPrefix('cpu feature') or
            MatchPrefix('capabilities') or
            MatchPrefix('extensions') or
            MatchPrefix('isa_ext') or
            MatchPrefix('features') or
            MatchPrefix('flags') or
            MatchPrefix('caps2') or
            MatchPrefix('caps');
end;

procedure ApplyARMFeatureTokenLocal(var aFeatures: TARMFeatures; const aToken: string);
var
  LToken: string;
begin
  LToken := LowerCase(Trim(aToken));
  if LToken = '' then
    Exit;

  if (LToken = 'neon') or (Pos('asimd', LToken) = 1) then
  begin
    aFeatures.HasNEON := True;
    aFeatures.HasAdvSIMD := True;
  end;

  if (LToken = 'fp') or (Pos('vfp', LToken) = 1) or (LToken = 'fphp') or (Pos('asimdhp', LToken) = 1) then
    aFeatures.HasFP := True;

  if (LToken = 'sve') or ((Pos('sve', LToken) = 1) and (Length(LToken) > 3) and (LToken[4] in ['0'..'9'])) then
    aFeatures.HasSVE := True;

  if (LToken = 'aes') or
     (LToken = 'aesce') or
     (LToken = 'pmull') or
     (LToken = 'pmull2') or
     (LToken = 'sha1') or
     (LToken = 'sha2') or
     (LToken = 'sha256') or
     (LToken = 'sha512') or
     (LToken = 'sha3') or
     (LToken = 'sm3') or
     (LToken = 'sm4') then
    aFeatures.HasCrypto := True;
end;

procedure ParseARMFeatureTextLocal(var aFeatures: TARMFeatures; const aText: string);
var
  LNormalized: string;
  LTokens: TStringArray;
  LToken: string;
begin
  LNormalized := LowerCase(Trim(aText));
  if LNormalized = '' then
    Exit;

  LNormalized := StringReplace(LNormalized, ',', ' ', [rfReplaceAll]);
  LNormalized := StringReplace(LNormalized, ';', ' ', [rfReplaceAll]);
  LNormalized := StringReplace(LNormalized, #9, ' ', [rfReplaceAll]);
  LTokens := LNormalized.Split([' ']);
  for LToken in LTokens do
    ApplyARMFeatureTokenLocal(aFeatures, NormalizeARMFieldValueLocal(LToken));
end;

function TryParseARMQWordLocal(const aText: string; out aValue: QWord): Boolean;
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

function IsARMNumericProcessorIndexLocal(const aValue: string): Boolean;
var
  LIgnored: QWord;
begin
  Result := TryParseARMQWordLocal(aValue, LIgnored);
end;

procedure MergeARMFeaturesFromLinuxHWCAP(var aFeatures: TARMFeatures; const aHWCAP, aHWCAP2: QWord);
begin
  {$IFDEF LINUX}
  {$IFDEF CPUAARCH64}
  if (aHWCAP and (QWord(1) shl 0)) <> 0 then
    aFeatures.HasFP := True;
  if (aHWCAP and (QWord(1) shl 1)) <> 0 then
  begin
    aFeatures.HasNEON := True;
    aFeatures.HasAdvSIMD := True;
  end;
  if (aHWCAP and (QWord(1) shl 22)) <> 0 then
    aFeatures.HasSVE := True;
  if (aHWCAP and ((QWord(1) shl 3) or (QWord(1) shl 4) or (QWord(1) shl 5) or (QWord(1) shl 6))) <> 0 then
    aFeatures.HasCrypto := True;
  {$ELSE}
  if (aHWCAP and (QWord(1) shl 6)) <> 0 then
    aFeatures.HasFP := True;
  if (aHWCAP and (QWord(1) shl 12)) <> 0 then
  begin
    aFeatures.HasNEON := True;
    aFeatures.HasAdvSIMD := True;
  end;
  if (aHWCAP2 and ((QWord(1) shl 0) or (QWord(1) shl 1) or (QWord(1) shl 2) or (QWord(1) shl 3))) <> 0 then
    aFeatures.HasCrypto := True;
  {$ENDIF}
  {$ELSE}
  if (aHWCAP <> 0) or (aHWCAP2 <> 0) then
    ;
  {$ENDIF}
end;

function ParseARMProcessorInfoFromCpuInfo(const aCpuInfo: string; var aInstructionSet, aCoreType: string): Boolean;
var
  LLines: TStringArray;
  LLine: string;
  LTrimmedLine: string;
  LKey: string;
  LValue: string;
  LInstructionCandidate: string;
  LCoreCandidate: string;
  LInstructionPriority: Integer;
  LCorePriority: Integer;
begin
  aInstructionSet := '';
  aCoreType := '';
  if aCpuInfo = '' then
    Exit(False);

  LInstructionPriority := -1;
  LCorePriority := -1;
  LLines := aCpuInfo.Split([#10, #13]);
  for LLine in LLines do
  begin
    LTrimmedLine := Trim(LLine);
    if (LTrimmedLine = '') or (not SplitARMKeyValueLineLocal(LTrimmedLine, LKey, LValue)) or (LValue = '') then
      Continue;

    if (LKey = 'isa') or (LKey = 'arch') then
    begin
      LInstructionCandidate := NormalizeARMInstructionSetLocal(LValue);
      if (LInstructionCandidate <> '') and (LInstructionPriority < 3) then
      begin
        aInstructionSet := LInstructionCandidate;
        LInstructionPriority := 3;
      end;
    end
    else if LKey = 'cpu architecture' then
    begin
      LInstructionCandidate := NormalizeARMInstructionSetLocal(LValue);
      if (LInstructionCandidate <> '') and (LInstructionPriority < 2) then
      begin
        aInstructionSet := LInstructionCandidate;
        LInstructionPriority := 2;
      end;
    end
    else if (LKey = 'model name') or (LKey = 'cpu model') then
    begin
      LInstructionCandidate := NormalizeARMInstructionSetLocal(LValue);
      if (LInstructionCandidate <> '') and (LInstructionPriority < 1) then
      begin
        aInstructionSet := LInstructionCandidate;
        LInstructionPriority := 1;
      end;
    end
    else if (LKey = 'processor') and (not IsARMNumericProcessorIndexLocal(LValue)) then
    begin
      LInstructionCandidate := NormalizeARMInstructionSetLocal(LValue);
      if (LInstructionCandidate <> '') and (LInstructionPriority < 0) then
      begin
        aInstructionSet := LInstructionCandidate;
        LInstructionPriority := 0;
      end;
    end;

    if (LKey = 'uarch') then
    begin
      LCoreCandidate := NormalizeARMCoreTypeLocal(LValue);
      if (LCoreCandidate <> '') and (LCorePriority < 3) then
      begin
        aCoreType := LCoreCandidate;
        LCorePriority := 3;
      end;
    end
    else if (LKey = 'model name') or (LKey = 'cpu model') then
    begin
      LCoreCandidate := NormalizeARMCoreTypeLocal(LValue);
      if (LCoreCandidate <> '') and (LCorePriority < 2) then
      begin
        aCoreType := LCoreCandidate;
        LCorePriority := 2;
      end;
    end
    else if (LKey = 'processor') and (not IsARMNumericProcessorIndexLocal(LValue)) then
    begin
      LCoreCandidate := NormalizeARMCoreTypeLocal(LValue);
      if (LCoreCandidate <> '') and (LCorePriority < 1) then
      begin
        aCoreType := LCoreCandidate;
        LCorePriority := 1;
      end;
    end;
  end;

  Result := (aInstructionSet <> '') or (aCoreType <> '');
end;

{$IFDEF UNIX}
function ReadProcCpuInfoSafe: string;
var
  LFile: TextFile;
  LLine: string;
  LCpuText: string;
  LFileOpened: Boolean;
begin
  LCpuText := '';
  LFileOpened := False;

  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(LFile, '/proc/cpuinfo');
      Reset(LFile);
      LFileOpened := True;
      while not EOF(LFile) do
      begin
        ReadLn(LFile, LLine);
        LCpuText := LCpuText + LLine + LineEnding;
      end;
    end;
  except
    LCpuText := '';
  end;

  if LFileOpened then
  begin
    try
      CloseFile(LFile);
    except
    end;
  end;

  Result := LCpuText;
end;

function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
var
  LLines: TStringArray;
  LLine: string;
  LTrimmedLine: string;
  LKey: string;
  LValue: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  if cpuInfo = '' then
    Exit;

  LLines := cpuInfo.Split([#10, #13]);
  for LLine in LLines do
  begin
    LTrimmedLine := Trim(LLine);
    if LTrimmedLine = '' then
      Continue;

    if SplitARMKeyValueLineLocal(LTrimmedLine, LKey, LValue) then
    begin
      if IsARMFeatureLikeKeyLocal(LKey) then
        ParseARMFeatureTextLocal(Result, LValue);
      Continue;
    end;

    if TryExtractARMFeatureValueWithoutSeparatorLocal(LTrimmedLine, LValue) then
      ParseARMFeatureTextLocal(Result, LValue);
  end;
end;

function ParseARMVendorFromCpuInfo(const cpuInfo: string; var vendor, model: string): Boolean;
var
  LLines: TStringArray;
  LLine: string;
  LTrimmedLine: string;
  LKey: string;
  LValue: string;
  LVendorPriority: Integer;
  LModelPriority: Integer;
  LCandidatePriority: Integer;
begin
  Result := False;
  vendor := '';
  model := '';
  if cpuInfo = '' then
    Exit;

  LVendorPriority := -1;
  LModelPriority := -1;
  LLines := cpuInfo.Split([#10, #13]);
  for LLine in LLines do
  begin
    LTrimmedLine := Trim(LLine);
    if (LTrimmedLine = '') or (not SplitARMKeyValueLineLocal(LTrimmedLine, LKey, LValue)) or (LValue = '') then
      Continue;

    if (LKey = 'cpu implementer') or (LKey = 'vendor') or (LKey = 'hardware') then
    begin
      if LKey = 'hardware' then
        LCandidatePriority := 2
      else
        LCandidatePriority := 3;

      if LCandidatePriority > LVendorPriority then
      begin
        vendor := LValue;
        LVendorPriority := LCandidatePriority;
      end;
    end;

    if (LKey = 'cpu model') or (LKey = 'model name') then
      LCandidatePriority := 3
    else if LKey = 'cpu part' then
      LCandidatePriority := 2
    else if (LKey = 'processor') and (not IsARMNumericProcessorIndexLocal(LValue)) then
      LCandidatePriority := 1
    else
      LCandidatePriority := -1;

    if LCandidatePriority > LModelPriority then
    begin
      model := LValue;
      LModelPriority := LCandidatePriority;
    end;
  end;

  Result := (vendor <> '') or (model <> '');
end;
{$ENDIF}

function DetectARMFeatures: TARMFeatures;
{$IFDEF UNIX}
var
  LCpuInfoText: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(Result), 0);

  try
    {$IFDEF CPUAARCH64}
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;

    {$IFDEF UNIX}
    LCpuInfoText := ReadProcCpuInfoSafe;
    if LCpuInfoText <> '' then
    begin
      Result := ParseARMFeaturesFromCpuInfo(LCpuInfoText);
      Result.HasNEON := True;
      Result.HasAdvSIMD := True;
      Result.HasFP := True;
    end;
    {$ENDIF}
    {$ELSE}
    {$IFDEF UNIX}
    LCpuInfoText := ReadProcCpuInfoSafe;
    if LCpuInfoText <> '' then
      Result := ParseARMFeaturesFromCpuInfo(LCpuInfoText);
    {$ELSE}
    Result.HasNEON := False;
    Result.HasAdvSIMD := False;
    Result.HasFP := False;
    Result.HasSVE := False;
    Result.HasCrypto := False;
    {$ENDIF}
    {$ENDIF}
  except
    FillChar(Result, SizeOf(Result), 0);
    {$IFDEF CPUAARCH64}
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;
    {$ENDIF}
  end;
end;

procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);
{$IFDEF UNIX}
var
  LCpuInfoText: string;
  LVendor: string;
  LModel: string;
{$ENDIF}
begin
  cpuInfo.Vendor := 'ARM';
  cpuInfo.Model := 'Unknown ARM Processor';

  try
    {$IFDEF UNIX}
    LCpuInfoText := ReadProcCpuInfoSafe;
    if LCpuInfoText <> '' then
      if ParseARMVendorFromCpuInfo(LCpuInfoText, LVendor, LModel) then
      begin
        if LVendor <> '' then
          cpuInfo.Vendor := LVendor;
        if LModel <> '' then
          cpuInfo.Model := LModel;
      end;
    {$ENDIF}

    if Pos('0x41', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'ARM'
    else if Pos('0x51', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'Qualcomm'
    else if Pos('0x53', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'Samsung'
    else if Pos('0x61', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'Apple';
  except
  end;
end;

function IsNEONAvailable: Boolean;
var
  LFeatures: TARMFeatures;
begin
  LFeatures := DetectARMFeatures;
  Result := LFeatures.HasNEON;
end;

function IsAdvSIMDAvailable: Boolean;
var
  LFeatures: TARMFeatures;
begin
  LFeatures := DetectARMFeatures;
  Result := LFeatures.HasAdvSIMD;
end;

function IsSVEAvailable: Boolean;
var
  LFeatures: TARMFeatures;
begin
  LFeatures := DetectARMFeatures;
  Result := LFeatures.HasSVE;
end;

function GetARMProcessorInfo: TARMProcessorInfo;
{$IFDEF UNIX}
var
  LCpuInfoText: string;
  LInstructionSet: string;
  LCoreType: string;
{$ENDIF}
begin
  Result.Architecture := '';
  Result.InstructionSet := '';
  Result.CoreType := '';

  try
    {$IFDEF CPUAARCH64}
    Result.Architecture := 'AArch64';
    Result.InstructionSet := 'ARMv8-A';
    {$ELSE}
    Result.Architecture := 'AArch32';
    Result.InstructionSet := 'ARMv7-A';
    {$ENDIF}

    {$IFDEF UNIX}
    LCpuInfoText := ReadProcCpuInfoSafe;
    if LCpuInfoText <> '' then
    begin
      LInstructionSet := '';
      LCoreType := '';
      if ParseARMProcessorInfoFromCpuInfo(LCpuInfoText, LInstructionSet, LCoreType) then
      begin
        if LInstructionSet <> '' then
          Result.InstructionSet := LInstructionSet;
        if LCoreType <> '' then
          Result.CoreType := LCoreType;
      end;
    end;
    {$ENDIF}

    if Result.CoreType = '' then
      Result.CoreType := 'Unknown';
  except
    Result.Architecture := 'Unknown';
    Result.InstructionSet := 'Unknown';
    Result.CoreType := 'Unknown';
  end;
end;

{$ELSE}

implementation

function DetectARMFeatures: TARMFeatures;
begin
  FillChar(Result, SizeOf(TARMFeatures), 0);
end;

procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);
begin
  cpuInfo.Vendor := 'Non-ARM';
  cpuInfo.Model := 'Non-ARM Processor';
end;

function IsNEONAvailable: Boolean;
begin
  Result := False;
end;

function IsAdvSIMDAvailable: Boolean;
begin
  Result := False;
end;

function IsSVEAvailable: Boolean;
begin
  Result := False;
end;

function GetARMProcessorInfo: TARMProcessorInfo;
begin
  FillChar(Result, SizeOf(TARMProcessorInfo), 0);
  Result.Architecture := 'Non-ARM';
  Result.InstructionSet := 'Non-ARM';
  Result.CoreType := 'Non-ARM';
end;

{$IFDEF UNIX}
function ReadProcCpuInfoSafe: string;
begin
  Result := '';
end;

procedure MergeARMFeaturesFromLinuxHWCAP(var aFeatures: TARMFeatures; const aHWCAP, aHWCAP2: QWord);
begin
  if (aHWCAP <> 0) or (aHWCAP2 <> 0) then
    ;
  FillChar(aFeatures, SizeOf(aFeatures), 0);
end;

function ParseARMProcessorInfoFromCpuInfo(const aCpuInfo: string; var aInstructionSet, aCoreType: string): Boolean;
begin
  aInstructionSet := '';
  aCoreType := '';
  Result := False;
end;

function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
begin
  FillChar(Result, SizeOf(TARMFeatures), 0);
end;

function ParseARMVendorFromCpuInfo(const cpuInfo: string; var vendor, model: string): Boolean;
begin
  vendor := '';
  model := '';
  Result := False;
end;
{$ENDIF}

{$ENDIF}

end.
