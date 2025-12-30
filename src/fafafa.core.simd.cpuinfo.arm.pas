unit fafafa.core.simd.cpuinfo.arm;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_ARM_AVAILABLE}

uses
  SysUtils, StrUtils,
  fafafa.core.simd.cpuinfo.base;

type
  // ARM processor information structure
  TARMProcessorInfo = record
    Architecture: string;
    InstructionSet: string;
    CoreType: string;
  end;

// === ARM CPU Detection Interface ===

// Detect all ARM features
function DetectARMFeatures: TARMFeatures;

// Detect ARM vendor and model information
procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);

// Check specific ARM feature availability
function IsNEONAvailable: Boolean;
function IsAdvSIMDAvailable: Boolean;
function IsSVEAvailable: Boolean;

// Get ARM processor information
function GetARMProcessorInfo: TARMProcessorInfo;

{$IFDEF UNIX}
// Linux-specific functions
function ReadProcCpuInfoSafe: string;
function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
function ParseARMVendorFromCpuInfo(const cpuInfo: string; var vendor, model: string): Boolean;
{$ENDIF}

implementation

{$IFDEF UNIX}
uses
  BaseUnix;
{$ENDIF}

// === Linux /proc/cpuinfo Parsing ===

{$IFDEF UNIX}
function ReadProcCpuInfoSafe: string;
var
  f: TextFile;
  line: string;
  cpuText: string;
  fileOpened: Boolean;
begin
  cpuText := '';
  fileOpened := False;
  
  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(f, '/proc/cpuinfo');
      Reset(f);
      fileOpened := True;
      
      while not EOF(f) do
      begin
        ReadLn(f, line);
        cpuText := cpuText + line + LineEnding;
      end;
    end;
  except
    // Ignore errors, return empty string
    cpuText := '';
  end;
  
  // Ensure file is closed even if exception occurs
  if fileOpened then
  begin
    try
      CloseFile(f);
    except
      // Ignore close errors
    end;
  end;
  
  Result := cpuText;
end;

function ParseARMFeaturesFromCpuInfo(const cpuInfo: string): TARMFeatures;
var
  lowerInfo: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  if cpuInfo = '' then
    Exit;
    
  lowerInfo := LowerCase(cpuInfo);
  
  // Look for feature flags in /proc/cpuinfo
  Result.HasNEON := (Pos('neon', lowerInfo) > 0) or (Pos('asimd', lowerInfo) > 0);
  Result.HasAdvSIMD := Result.HasNEON; // NEON and Advanced SIMD are the same on ARM
  Result.HasFP := (Pos('fp', lowerInfo) > 0) or (Pos('vfp', lowerInfo) > 0);
  Result.HasSVE := Pos('sve', lowerInfo) > 0;
  
  // Additional ARM features
  if Pos('aes', lowerInfo) > 0 then
    Result.HasCrypto := True;
    
  if Pos('sha1', lowerInfo) > 0 then
    Result.HasCrypto := True;
    
  if Pos('sha2', lowerInfo) > 0 then
    Result.HasCrypto := True;
end;

function ParseARMVendorFromCpuInfo(const cpuInfo: string; var vendor, model: string): Boolean;
var
  scanPos, nextPos, colonPos: Integer;
  line, key, value: string;
begin
  Result := False;
  vendor := '';
  model := '';
  
  if cpuInfo = '' then
    Exit;
    
  scanPos := 1;
  while scanPos <= Length(cpuInfo) do
  begin
    // Find next line (Pos does not support an offset; use PosEx)
    nextPos := PosEx(LineEnding, cpuInfo, scanPos);
    if nextPos = 0 then
      nextPos := Length(cpuInfo) + 1;
      
    line := Trim(Copy(cpuInfo, scanPos, nextPos - scanPos));
    scanPos := nextPos + 1;
    
    // Parse key:value pairs
    colonPos := Pos(':', line);
    if colonPos > 0 then
    begin
      key := Trim(LowerCase(Copy(line, 1, colonPos - 1)));
      value := Trim(Copy(line, colonPos + 1, Length(line)));
      
      if (key = 'cpu implementer') or (key = 'hardware') then
      begin
        if value <> '' then
        begin
          vendor := value;
          Result := True;
        end;
      end
      else if (key = 'cpu part') or (key = 'model name') or (key = 'processor') then
      begin
        if value <> '' then
        begin
          model := value;
          Result := True;
        end;
      end;
    end;
  end;
end;
{$ENDIF} // UNIX

// === ARM Feature Detection ===

function DetectARMFeatures: TARMFeatures;
{$IFDEF UNIX}
var
  cpuInfoText: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(Result), 0);
  
  try
    {$IFDEF CPUAARCH64}
    // On AArch64, NEON (Advanced SIMD) is mandatory per ARM architecture
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;
    
    {$IFDEF UNIX}
    // Try to detect additional features from /proc/cpuinfo
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
    begin
      Result := ParseARMFeaturesFromCpuInfo(cpuInfoText);
      // Ensure mandatory features are still set
      Result.HasNEON := True;
      Result.HasAdvSIMD := True;
      Result.HasFP := True;
    end;
    {$ENDIF}
    
    {$ELSE} // 32-bit ARM
    
    {$IFDEF UNIX}
    // On 32-bit ARM, NEON is optional, check /proc/cpuinfo
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
      Result := ParseARMFeaturesFromCpuInfo(cpuInfoText);
    {$ELSE}
    // On other platforms, conservative defaults
    Result.HasNEON := False;
    Result.HasAdvSIMD := False;
    Result.HasFP := False;
    Result.HasSVE := False;
    Result.HasCrypto := False;
    {$ENDIF}
    
    {$ENDIF} // CPUAARCH64
    
  except
    // If detection fails, use conservative defaults
    FillChar(Result, SizeOf(Result), 0);
    {$IFDEF CPUAARCH64}
    // Even on error, AArch64 guarantees these features
    Result.HasNEON := True;
    Result.HasAdvSIMD := True;
    Result.HasFP := True;
    {$ENDIF}
  end;
end;

procedure DetectARMVendorAndModel(var cpuInfo: TCPUInfo);
{$IFDEF UNIX}
var
  cpuInfoText: string;
  vendor, model: string;
{$ENDIF}
begin
  // Set default values
  cpuInfo.Vendor := 'ARM';
  cpuInfo.Model := 'Unknown ARM Processor';
  
  try
    {$IFDEF UNIX}
    // Try to get detailed info from /proc/cpuinfo
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
    begin
      if ParseARMVendorFromCpuInfo(cpuInfoText, vendor, model) then
      begin
        if vendor <> '' then
          cpuInfo.Vendor := vendor;
        if model <> '' then
          cpuInfo.Model := model;
      end;
    end;
    {$ENDIF}
    
    // Enhance vendor identification
    if Pos('0x41', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'ARM'
    else if Pos('0x51', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'Qualcomm'
    else if Pos('0x53', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'Samsung'
    else if Pos('0x61', cpuInfo.Vendor) > 0 then
      cpuInfo.Vendor := 'Apple';
      
  except
    // Keep default values on error
  end;
end;

// === Individual Feature Checks ===

function IsNEONAvailable: Boolean;
var
  features: TARMFeatures;
begin
  features := DetectARMFeatures;
  Result := features.HasNEON;
end;

function IsAdvSIMDAvailable: Boolean;
var
  features: TARMFeatures;
begin
  features := DetectARMFeatures;
  Result := features.HasAdvSIMD;
end;

function IsSVEAvailable: Boolean;
var
  features: TARMFeatures;
begin
  features := DetectARMFeatures;
  Result := features.HasSVE;
end;

// === ARM Processor Information ===

function GetARMProcessorInfo: TARMProcessorInfo;
{$IFDEF UNIX}
var
  cpuInfoText: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(Result), 0);
  
  try
    {$IFDEF CPUAARCH64}
    Result.Architecture := 'AArch64';
    Result.InstructionSet := 'ARMv8-A';
    {$ELSE}
    Result.Architecture := 'AArch32';
    Result.InstructionSet := 'ARMv7-A';
    {$ENDIF}
    
    {$IFDEF UNIX}
    cpuInfoText := ReadProcCpuInfoSafe;
    if cpuInfoText <> '' then
    begin
      // Parse additional processor information
      if Pos('cortex-a', LowerCase(cpuInfoText)) > 0 then
        Result.CoreType := 'Cortex-A'
      else if Pos('cortex-r', LowerCase(cpuInfoText)) > 0 then
        Result.CoreType := 'Cortex-R'
      else if Pos('cortex-m', LowerCase(cpuInfoText)) > 0 then
        Result.CoreType := 'Cortex-M'
      else
        Result.CoreType := 'Unknown';
    end;
    {$ENDIF}
    
  except
    // Use defaults on error
    Result.Architecture := 'Unknown';
    Result.InstructionSet := 'Unknown';
    Result.CoreType := 'Unknown';
  end;
end;

{$ELSE}

// === Stub implementations for non-ARM platforms ===

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

{$ENDIF} // SIMD_ARM_AVAILABLE

end.


