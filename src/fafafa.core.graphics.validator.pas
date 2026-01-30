unit fafafa.core.graphics.validator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  fafafa.core.graphics;

type
  TImageFormat = (ifUnknown, ifBMP, ifPNG, ifJPEG, ifGIF, ifTIFF, ifTGA, ifICO, ifWebP);
  
  TValidationLevel = (vlQuick, vlStandard, vlThorough);
  
  TValidationIssue = record
    Severity: (isInfo, isWarning, isError, isCritical);
    Code: string;
    Message: string;
    Offset: Int64;
    CanRepair: Boolean;
  end;
  
  TValidationResult = record
    Format: TImageFormat;
    IsValid: Boolean;
    CanLoad: Boolean;
    Issues: array of TValidationIssue;
    FileSize: Int64;
    ImageWidth: Integer;
    ImageHeight: Integer;
    BitDepth: Integer;
    HasAlpha: Boolean;
  end;
  
  { TImageValidator }
  TImageValidator = class
  private
    FStream: TStream;
    FOwnsStream: Boolean;
    FValidationLevel: TValidationLevel;
    FResult: TValidationResult;
    
    function DetectFormat: TImageFormat;
    function ValidateBMP: Boolean;
    function ValidatePNG: Boolean;
    function ValidateJPEG: Boolean;
    function ValidateGIF: Boolean;
    function ValidateTIFF: Boolean;
    function ValidateTGA: Boolean;
    function ValidateICO: Boolean;
    function ValidateWebP: Boolean;
    
    procedure AddIssue(ASeverity: Integer; const ACode, AMessage: string; 
      AOffset: Int64 = -1; ACanRepair: Boolean = False);
    function CheckCRC32(AData: PByte; ASize: Integer; AExpectedCRC: Cardinal): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    function ValidateFile(const AFileName: string; 
      ALevel: TValidationLevel = vlStandard): TValidationResult;
    function ValidateStream(AStream: TStream; 
      ALevel: TValidationLevel = vlStandard): TValidationResult;
    function ValidateMemory(AData: Pointer; ASize: Integer;
      ALevel: TValidationLevel = vlStandard): TValidationResult;
      
    function RepairFile(const AFileName: string; 
      const AOutputFileName: string = ''): Boolean;
    function RepairStream(AInputStream, AOutputStream: TStream): Boolean;
    
    class function GetFormatName(AFormat: TImageFormat): string;
    class function GetFormatExtension(AFormat: TImageFormat): string;
    class function IsFormatSupported(AFormat: TImageFormat): Boolean;
  end;
  
  { TImageFormatInfo }
  TImageFormatInfo = class
  public
    class function GetBMPInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetPNGInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetJPEGInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetGIFInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetTIFFInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetTGAInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetICOInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
    class function GetWebPInfo(AStream: TStream; out AInfo: TValidationResult): Boolean;
  end;

implementation

uses
  fafafa.core.math;

type
  TCRC32Table = array[0..255] of Cardinal;

var
  CRC32Table: TCRC32Table;
  CRC32TableInitialized: Boolean = False;

const
  // Size limits
  MAX_FILE_SIZE = 512 * 1024 * 1024; // 512MB max file size
  MAX_IMAGE_DIMENSION = 32768; // Maximum width or height
  
  // BMP constants
  BMP_SIGNATURE = $4D42; // 'BM'
  
  // BMP header sizes
  BITMAPINFOHEADER_SIZE = 40;
  BITMAPV4HEADER_SIZE = 108;
  BITMAPV5HEADER_SIZE = 124;
  
  // PNG constants  
  PNG_SIGNATURE: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
  
  // JPEG constants
  JPEG_SOI = $FFD8;
  JPEG_EOI = $FFD9;
  
  // GIF constants
  GIF87A_SIGNATURE = 'GIF87a';
  GIF89A_SIGNATURE = 'GIF89a';
  
  // TIFF constants
  TIFF_LITTLE_ENDIAN = $4949;
  TIFF_BIG_ENDIAN = $4D4D;
  TIFF_MAGIC = 42;
  
  // WebP constants
  WEBP_RIFF = 'RIFF';
  WEBP_WEBP = 'WEBP';

{ TImageValidator }

constructor TImageValidator.Create;
begin
  inherited Create;
  FStream := nil;
  FOwnsStream := False;
  FValidationLevel := vlStandard;
end;

destructor TImageValidator.Destroy;
begin
  if FOwnsStream and Assigned(FStream) then
    FStream.Free;
  inherited Destroy;
end;

function TImageValidator.DetectFormat: TImageFormat;
var
  Signature: array[0..11] of Byte;
  SavedPos: Int64;
begin
  Result := ifUnknown;
  if not Assigned(FStream) then
    Exit;
    
  SavedPos := FStream.Position;
  try
    FStream.Position := 0;
    FillChar(Signature, SizeOf(Signature), 0);
    FStream.Read(Signature, LongInt(Min(Int64(SizeOf(Signature)), FStream.Size)));
    
    // Check PNG
    if CompareMem(@Signature[0], @PNG_SIGNATURE[0], 8) then
      Result := ifPNG
    // Check JPEG
    else if (Signature[0] = $FF) and (Signature[1] = $D8) then
      Result := ifJPEG
    // Check BMP
    else if (Signature[0] = $42) and (Signature[1] = $4D) then
      Result := ifBMP
    // Check GIF
    else if (CompareMem(@Signature[0], PAnsiChar(GIF87A_SIGNATURE), 6)) or
            (CompareMem(@Signature[0], PAnsiChar(GIF89A_SIGNATURE), 6)) then
      Result := ifGIF
    // Check TIFF
    else if ((Signature[0] = $49) and (Signature[1] = $49) and 
             (Signature[2] = $2A) and (Signature[3] = $00)) or
            ((Signature[0] = $4D) and (Signature[1] = $4D) and 
             (Signature[2] = $00) and (Signature[3] = $2A)) then
      Result := ifTIFF
    // Check WebP
    else if CompareMem(@Signature[0], @WEBP_RIFF[1], 4) and
            CompareMem(@Signature[8], @WEBP_WEBP[1], 4) then
      Result := ifWebP
    // Check ICO/CUR
    else if (Signature[0] = 0) and (Signature[1] = 0) and
            ((Signature[2] = 1) or (Signature[2] = 2)) and (Signature[3] = 0) then
      Result := ifICO
    // TGA doesn't have a definitive signature, needs heuristic check
    else
    begin
      // Try TGA heuristic
      FStream.Position := 0;
      if FStream.Size >= 18 then
      begin
        // Simple TGA detection based on header structure
        if (Signature[2] in [0, 1, 2, 3, 9, 10, 11]) then
          Result := ifTGA;
      end;
    end;
  finally
    FStream.Position := SavedPos;
  end;
end;

procedure TImageValidator.AddIssue(ASeverity: Integer; const ACode, AMessage: string;
  AOffset: Int64; ACanRepair: Boolean);
var
  Issue: TValidationIssue;
begin
  // Fix: Proper type conversion for severity
  case ASeverity of
    0: Issue.Severity := isInfo;
    1: Issue.Severity := isWarning;
    2: Issue.Severity := isError;
    3: Issue.Severity := isCritical;
  else
    Issue.Severity := isInfo;
  end;
  
  Issue.Code := ACode;
  Issue.Message := AMessage;
  Issue.Offset := AOffset;
  Issue.CanRepair := ACanRepair;
  
  SetLength(FResult.Issues, Length(FResult.Issues) + 1);
  FResult.Issues[High(FResult.Issues)] := Issue;
  
  if ASeverity >= Ord(isError) then
    FResult.IsValid := False;
end;

procedure InitCRC32Table;
var
  i, j: Integer;
  CRC: Cardinal;
begin
  if CRC32TableInitialized then
    Exit;
    
  for i := 0 to 255 do
  begin
    CRC := i;
    for j := 0 to 7 do
    begin
      if (CRC and 1) <> 0 then
        CRC := (CRC shr 1) xor $EDB88320
      else
        CRC := CRC shr 1;
    end;
    CRC32Table[i] := CRC;
  end;
  
  CRC32TableInitialized := True;
end;

function TImageValidator.CheckCRC32(AData: PByte; ASize: Integer; 
  AExpectedCRC: Cardinal): Boolean;
var
  i: Integer;
  CRC: Cardinal;
  P: PByte;
begin
  InitCRC32Table; // Initialize only once
  
  // Calculate CRC
  CRC := $FFFFFFFF;
  P := AData;
  for i := 0 to ASize - 1 do
  begin
    CRC := CRC32Table[(CRC xor P^) and $FF] xor (CRC shr 8);
    Inc(P);
  end;
  
  Result := (CRC xor $FFFFFFFF) = AExpectedCRC;
end;

function TImageValidator.ValidateBMP: Boolean;
type
  TBitmapFileHeader = packed record
    bfType: Word;
    bfSize: Cardinal;
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: Cardinal;
  end;
  
  TBitmapInfoHeader = packed record
    biSize: Cardinal;
    biWidth: LongInt;
    biHeight: LongInt;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: Cardinal;
    biSizeImage: Cardinal;
    biXPelsPerMeter: LongInt;
    biYPelsPerMeter: LongInt;
    biClrUsed: Cardinal;
    biClrImportant: Cardinal;
  end;
var
  FileHeader: TBitmapFileHeader;
  InfoHeader: TBitmapInfoHeader;
  ExpectedDataSize: Cardinal;
  RowSize: Cardinal;
begin
  Result := False;
  
  FStream.Position := 0;
  
  // Read file header
  if FStream.Read(FileHeader, SizeOf(FileHeader)) <> SizeOf(FileHeader) then
  begin
    AddIssue(Ord(isCritical), 'BMP001', 'Cannot read BMP file header', 0);
    Exit;
  end;
  
  // Validate signature
  if FileHeader.bfType <> BMP_SIGNATURE then
  begin
    AddIssue(Ord(isCritical), 'BMP002', 'Invalid BMP signature', 0);
    Exit;
  end;
  
  // Validate file size
  if FileHeader.bfSize <> FStream.Size then
  begin
    AddIssue(Ord(isWarning), 'BMP003', 
      Format('File size mismatch: header says %d, actual is %d', 
        [FileHeader.bfSize, FStream.Size]), 2, True);
  end;
  
  // Read info header
  if FStream.Read(InfoHeader, SizeOf(InfoHeader)) <> SizeOf(InfoHeader) then
  begin
    AddIssue(Ord(isCritical), 'BMP004', 'Cannot read BMP info header', 14);
    Exit;
  end;
  
  // Validate info header
  if not (InfoHeader.biSize in [BITMAPINFOHEADER_SIZE, BITMAPV4HEADER_SIZE, BITMAPV5HEADER_SIZE]) then
  begin
    AddIssue(Ord(isError), 'BMP005', 
      Format('Unsupported info header size: %d', [InfoHeader.biSize]), 14);
  end;
  
  // Validate dimensions
  if (InfoHeader.biWidth <= 0) or (InfoHeader.biWidth > MAX_IMAGE_DIMENSION) then
  begin
    AddIssue(Ord(isError), 'BMP006', 
      Format('Invalid width: %d', [InfoHeader.biWidth]), 18);
  end;
  
  if (Abs(InfoHeader.biHeight) > MAX_IMAGE_DIMENSION) then
  begin
    AddIssue(Ord(isError), 'BMP007', 
      Format('Invalid height: %d', [InfoHeader.biHeight]), 22);
  end;
  
  // Validate bit depth
  if not (InfoHeader.biBitCount in [1, 4, 8, 16, 24, 32]) then
  begin
    AddIssue(Ord(isError), 'BMP008', 
      Format('Invalid bit depth: %d', [InfoHeader.biBitCount]), 28);
  end;
  
  // Validate compression
  if InfoHeader.biCompression > 3 then
  begin
    AddIssue(Ord(isWarning), 'BMP009', 
      Format('Unsupported compression: %d', [InfoHeader.biCompression]), 30);
  end;
  
  // Store image info
  FResult.ImageWidth := InfoHeader.biWidth;
  FResult.ImageHeight := Abs(InfoHeader.biHeight);
  FResult.BitDepth := InfoHeader.biBitCount;
  FResult.HasAlpha := InfoHeader.biBitCount = 32;
  
  // Calculate expected data size
  if FValidationLevel >= vlThorough then
  begin
    RowSize := ((InfoHeader.biWidth * InfoHeader.biBitCount + 31) div 32) * 4;
    ExpectedDataSize := RowSize * Abs(InfoHeader.biHeight);
    
    if (InfoHeader.biCompression = 0) and (InfoHeader.biSizeImage > 0) then
    begin
      if InfoHeader.biSizeImage < ExpectedDataSize then
      begin
        AddIssue(Ord(isWarning), 'BMP010', 
          Format('Image data size too small: %d < %d', 
            [InfoHeader.biSizeImage, ExpectedDataSize]), 34);
      end;
    end;
    
    // Check if file has enough data
    if FileHeader.bfOffBits + ExpectedDataSize > FStream.Size then
    begin
      AddIssue(Ord(isError), 'BMP011', 'File truncated: missing image data', 
        FStream.Size);
    end;
  end;
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidatePNG: Boolean;
type
  TPNGChunkHeader = packed record
    Length: Cardinal;
    ChunkType: array[0..3] of AnsiChar;
  end;
var
  Signature: array[0..7] of Byte;
  ChunkHeader: TPNGChunkHeader;
  ChunkCRC: Cardinal;
  HasIHDR, HasIDAT, HasIEND: Boolean;
  ChunkData: PByte;
  ComputedCRC: Cardinal;
  IHDRData: packed record
    Width: Cardinal;
    Height: Cardinal;
    BitDepth: Byte;
    ColorType: Byte;
    Compression: Byte;
    Filter: Byte;
    Interlace: Byte;
  end;
begin
  Result := False;
  HasIHDR := False;
  HasIDAT := False;
  HasIEND := False;
  
  FStream.Position := 0;
  
  // Check PNG signature
  if FStream.Read(Signature, 8) <> 8 then
  begin
    AddIssue(Ord(isCritical), 'PNG001', 'Cannot read PNG signature', 0);
    Exit;
  end;
  
  if not CompareMem(@Signature[0], @PNG_SIGNATURE[0], 8) then
  begin
    AddIssue(Ord(isCritical), 'PNG002', 'Invalid PNG signature', 0);
    Exit;
  end;
  
  // Read chunks
  while FStream.Position < FStream.Size do
  begin
    if FStream.Read(ChunkHeader, SizeOf(ChunkHeader)) <> SizeOf(ChunkHeader) then
    begin
      if not HasIEND then
        AddIssue(Ord(isError), 'PNG003', 'Unexpected end of file', FStream.Position);
      Break;
    end;
    
    // Convert length from network byte order
    ChunkHeader.Length := SwapEndian(ChunkHeader.Length);
    
    // Check for critical chunks
    if ChunkHeader.ChunkType = 'IHDR' then
    begin
      HasIHDR := True;
      
      // Read IHDR data
      if ChunkHeader.Length = 13 then
      begin
        if FStream.Read(IHDRData, 13) = 13 then
        begin
          FResult.ImageWidth := SwapEndian(IHDRData.Width);
          FResult.ImageHeight := SwapEndian(IHDRData.Height);
          FResult.BitDepth := IHDRData.BitDepth;
          FResult.HasAlpha := IHDRData.ColorType in [4, 6];
          
          // Validate IHDR values
          if (FResult.ImageWidth = 0) or (FResult.ImageWidth > 65535) then
            AddIssue(Ord(isError), 'PNG004', 
              Format('Invalid width: %d', [FResult.ImageWidth]), FStream.Position - 13);
              
          if (FResult.ImageHeight = 0) or (FResult.ImageHeight > 65535) then
            AddIssue(Ord(isError), 'PNG005', 
              Format('Invalid height: %d', [FResult.ImageHeight]), FStream.Position - 9);
              
          if not (IHDRData.BitDepth in [1, 2, 4, 8, 16]) then
            AddIssue(Ord(isError), 'PNG006', 
              Format('Invalid bit depth: %d', [IHDRData.BitDepth]), FStream.Position - 5);
              
          if IHDRData.ColorType > 6 then
            AddIssue(Ord(isError), 'PNG007', 
              Format('Invalid color type: %d', [IHDRData.ColorType]), FStream.Position - 4);
        end;
        
        FStream.Seek(-13, soFromCurrent);
      end;
    end
    else if ChunkHeader.ChunkType = 'IDAT' then
      HasIDAT := True
    else if ChunkHeader.ChunkType = 'IEND' then
      HasIEND := True;
    
    // CRC check for critical chunks (if thorough validation)
    if (FValidationLevel = vlThorough) and 
       (ChunkHeader.ChunkType[0] in ['A'..'Z']) then
    begin
      GetMem(ChunkData, ChunkHeader.Length + 4);
      try
        Move(ChunkHeader.ChunkType[0], ChunkData^, 4);
        if FStream.Read(ChunkData[4], ChunkHeader.Length) = ChunkHeader.Length then
        begin
          if FStream.Read(ChunkCRC, 4) = 4 then
          begin
            ChunkCRC := SwapEndian(ChunkCRC);
            if not CheckCRC32(ChunkData, ChunkHeader.Length + 4, ChunkCRC) then
            begin
              AddIssue(Ord(isError), 'PNG008', 
                Format('CRC error in chunk %s', [ChunkHeader.ChunkType]), 
                FStream.Position - ChunkHeader.Length - 8, True);
            end;
          end;
        end;
      finally
        FreeMem(ChunkData);
      end;
    end
    else
    begin
      // Skip chunk data and CRC
      FStream.Seek(ChunkHeader.Length + 4, soFromCurrent);
    end;
    
    if HasIEND then
      Break;
  end;
  
  // Check for required chunks
  if not HasIHDR then
    AddIssue(Ord(isCritical), 'PNG009', 'Missing IHDR chunk', 8);
    
  if not HasIDAT then
    AddIssue(Ord(isCritical), 'PNG010', 'Missing IDAT chunk', 8);
    
  if not HasIEND then
    AddIssue(Ord(isError), 'PNG011', 'Missing IEND chunk', FStream.Size);
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateJPEG: Boolean;
var
  Marker, PrevMarker: Word;
  SegmentLength: Word;
  HasSOI, HasEOI, HasSOF, HasSOS: Boolean;
  B1, B2: Byte;
  FrameHeader: packed record
    Precision: Byte;
    Height: Word;
    Width: Word;
    Components: Byte;
  end;
begin
  Result := False;
  HasSOI := True;  // We check for SOI first
  HasSOF := False;
  HasSOS := False;
  HasEOI := False;
  
  FStream.Position := 0;
  
  // Check SOI marker
  if FStream.Read(Marker, 2) <> 2 then
  begin
    AddIssue(Ord(isCritical), 'JPEG001', 'Cannot read JPEG header', 0);
    Exit;
  end;
  
  Marker := SwapEndian(Marker);
  if Marker <> JPEG_SOI then
  begin
    AddIssue(Ord(isCritical), 'JPEG002', 'Invalid JPEG SOI marker', 0);
    Exit;
  end;
  
  // Parse markers
  while FStream.Position < FStream.Size - 1 do
  begin
    if FStream.Read(Marker, 2) <> 2 then
      Break;
      
    Marker := SwapEndian(Marker);
    
    // Check for valid marker
    if (Marker and $FF00) <> $FF00 then
    begin
      AddIssue(Ord(isWarning), 'JPEG003', 
        Format('Invalid marker: $%.4x at offset %d', [Marker, FStream.Position - 2]), 
        FStream.Position - 2);
      // Try to resync
      Continue;
    end;
    
    case Marker of
      $FFD8: ; // SOI - already processed
      $FFD9: // EOI
        begin
          HasEOI := True;
          Break;
        end;
      $FFDA: // SOS - Start of Scan
        begin
          HasSOS := True;
          // After SOS, we have compressed data until EOI
          // Skip to find EOI
          while FStream.Position < FStream.Size - 1 do
          begin
            if FStream.Read(B1, 1) = 1 then
            begin
              if B1 = $FF then
              begin
                if FStream.Read(B2, 1) = 1 then
                begin
                  if B2 = $D9 then // EOI found
                  begin
                    HasEOI := True;
                    Break;
                  end;
                end;
              end;
            end;
          end;
          Break;
        end;
      $FFC0..$FFC3, $FFC5..$FFC7, $FFC9..$FFCB, $FFCD..$FFCF: // SOF markers
        begin
          HasSOF := True;
          
          // Read segment length
          if FStream.Read(SegmentLength, 2) = 2 then
          begin
            SegmentLength := SwapEndian(SegmentLength);
            
            // Read frame header
            if SegmentLength >= 8 then
            begin
              if FStream.Read(FrameHeader, 6) = 6 then
              begin
                FResult.ImageHeight := SwapEndian(FrameHeader.Height);
                FResult.ImageWidth := SwapEndian(FrameHeader.Width);
                FResult.BitDepth := FrameHeader.Precision * FrameHeader.Components;
                
                // Validate dimensions
                if FResult.ImageWidth = 0 then
                  AddIssue(Ord(isError), 'JPEG004', 'Invalid width: 0', FStream.Position - 4);
                  
                if FResult.ImageHeight = 0 then
                  AddIssue(Ord(isError), 'JPEG005', 'Invalid height: 0', FStream.Position - 2);
              end;
              
              // Skip rest of segment
              FStream.Seek(SegmentLength - 8, soFromCurrent);
            end
            else
              FStream.Seek(SegmentLength - 2, soFromCurrent);
          end;
        end;
      $FFE0..$FFEF: // APP markers
        begin
          // Read segment length and skip
          if FStream.Read(SegmentLength, 2) = 2 then
          begin
            SegmentLength := SwapEndian(SegmentLength);
            FStream.Seek(SegmentLength - 2, soFromCurrent);
          end;
        end;
      $FFDB, $FFDC, $FFDD, $FFDE, $FFDF, $FFC4, $FFC8, $FFCC, $FFFE: // Other segments
        begin
          // Read segment length and skip
          if FStream.Read(SegmentLength, 2) = 2 then
          begin
            SegmentLength := SwapEndian(SegmentLength);
            FStream.Seek(SegmentLength - 2, soFromCurrent);
          end;
        end;
      else
        begin
          // Unknown marker - try to skip
          if (Marker >= $FFD0) and (Marker <= $FFD7) then
          begin
            // RST markers have no length
          end
          else
          begin
            AddIssue(Ord(isInfo), 'JPEG006', 
              Format('Unknown marker: $%.4x', [Marker]), FStream.Position - 2);
          end;
        end;
    end;
  end;
  
  // Check for required markers
  if not HasSOF then
    AddIssue(Ord(isError), 'JPEG007', 'Missing SOF marker', 2);
    
  if not HasSOS then
    AddIssue(Ord(isError), 'JPEG008', 'Missing SOS marker', 2);
    
  if not HasEOI then
    AddIssue(Ord(isWarning), 'JPEG009', 'Missing EOI marker', FStream.Size, True);
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateGIF: Boolean;
var
  Header: array[0..5] of AnsiChar;
  LogicalScreen: packed record
    Width: Word;
    Height: Word;
    PackedField: Byte;
    Background: Byte;
    AspectRatio: Byte;
  end;
  BlockType: Byte;
  HasTerminator: Boolean;
  ColorTableSize: Integer;
  ImageDesc: packed record
    Left: Word;
    Top: Word;
    Width: Word;
    Height: Word;
    PackedField: Byte;
  end;
  LZWMinCodeSize: Byte;
  SubBlockSize: Byte;
  ExtLabel: Byte;
begin
  Result := False;
  HasTerminator := False;
  
  FStream.Position := 0;
  
  // Read header
  if FStream.Read(Header, 6) <> 6 then
  begin
    AddIssue(Ord(isCritical), 'GIF001', 'Cannot read GIF header', 0);
    Exit;
  end;
  
  // Validate signature
  if (Header <> GIF87A_SIGNATURE) and (Header <> GIF89A_SIGNATURE) then
  begin
    AddIssue(Ord(isCritical), 'GIF002', 'Invalid GIF signature', 0);
    Exit;
  end;
  
  // Read logical screen descriptor
  if FStream.Read(LogicalScreen, SizeOf(LogicalScreen)) <> SizeOf(LogicalScreen) then
  begin
    AddIssue(Ord(isCritical), 'GIF003', 'Cannot read logical screen descriptor', 6);
    Exit;
  end;
  
  FResult.ImageWidth := LogicalScreen.Width;
  FResult.ImageHeight := LogicalScreen.Height;
  FResult.BitDepth := (LogicalScreen.PackedField and $07) + 1;
  
  // Skip global color table if present
  if (LogicalScreen.PackedField and $80) <> 0 then
  begin
    ColorTableSize := 3 * (1 shl ((LogicalScreen.PackedField and $07) + 1));
    FStream.Seek(ColorTableSize, soFromCurrent);
  end;
  
  // Parse data stream
  while FStream.Position < FStream.Size do
  begin
    if FStream.Read(BlockType, 1) <> 1 then
      Break;
      
    case BlockType of
      $2C: // Image descriptor
        begin
          if FStream.Read(ImageDesc, SizeOf(ImageDesc)) = SizeOf(ImageDesc) then
          begin
            // Validate image dimensions
            if ImageDesc.Width = 0 then
              AddIssue(Ord(isError), 'GIF004', 'Image width is 0', FStream.Position - 4);
              
            if ImageDesc.Height = 0 then
              AddIssue(Ord(isError), 'GIF005', 'Image height is 0', FStream.Position - 2);
              
            // Skip local color table if present
            if (ImageDesc.PackedField and $80) <> 0 then
            begin
              ColorTableSize := 3 * (1 shl ((ImageDesc.PackedField and $07) + 1));
              FStream.Seek(ColorTableSize, soFromCurrent);
            end;
            
            // Skip LZW data
            if FStream.Read(LZWMinCodeSize, 1) = 1 then
            begin
              // Skip data sub-blocks
              repeat
                if FStream.Read(SubBlockSize, 1) <> 1 then
                  Break;
                if SubBlockSize > 0 then
                  FStream.Seek(SubBlockSize, soFromCurrent);
              until SubBlockSize = 0;
            end;
          end;
        end;
      $21: // Extension
        begin
          if FStream.Read(ExtLabel, 1) = 1 then
          begin
            // Skip extension data
            repeat
              if FStream.Read(SubBlockSize, 1) <> 1 then
                Break;
              if SubBlockSize > 0 then
                FStream.Seek(SubBlockSize, soFromCurrent);
            until SubBlockSize = 0;
          end;
        end;
      $3B: // Terminator
        begin
          HasTerminator := True;
          Break;
        end;
      $00: // Padding
        Continue;
      else
        AddIssue(Ord(isWarning), 'GIF006', 
          Format('Unknown block type: $%.2x', [BlockType]), FStream.Position - 1);
    end;
  end;
  
  if not HasTerminator then
    AddIssue(Ord(isWarning), 'GIF007', 'Missing terminator', FStream.Size, True);
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateTIFF: Boolean;
var
  Header: packed record
    ByteOrder: Word;
    Magic: Word;
    IFDOffset: Cardinal;
  end;
  IFDCount: Word;
  HasWidth, HasHeight, HasBitsPerSample: Boolean;
  i: Integer;
  Entry: packed record
    Tag: Word;
    FieldType: Word;
    Count: Cardinal;
    ValueOffset: Cardinal;
  end;
begin
  Result := False;
  HasWidth := False;
  HasHeight := False;
  HasBitsPerSample := False;
  
  FStream.Position := 0;
  
  // Read header
  if FStream.Read(Header, SizeOf(Header)) <> SizeOf(Header) then
  begin
    AddIssue(Ord(isCritical), 'TIFF001', 'Cannot read TIFF header', 0);
    Exit;
  end;
  
  // Check byte order
  if (Header.ByteOrder <> TIFF_LITTLE_ENDIAN) and 
     (Header.ByteOrder <> TIFF_BIG_ENDIAN) then
  begin
    AddIssue(Ord(isCritical), 'TIFF002', 'Invalid TIFF byte order', 0);
    Exit;
  end;
  
  // Check magic number
  if ((Header.ByteOrder = TIFF_LITTLE_ENDIAN) and (Header.Magic <> TIFF_MAGIC)) or
     ((Header.ByteOrder = TIFF_BIG_ENDIAN) and (SwapEndian(Header.Magic) <> TIFF_MAGIC)) then
  begin
    AddIssue(Ord(isCritical), 'TIFF003', 'Invalid TIFF magic number', 2);
    Exit;
  end;
  
  // Validate IFD offset
  if Header.IFDOffset >= FStream.Size then
  begin
    AddIssue(Ord(isError), 'TIFF004', 'Invalid IFD offset', 4);
    Exit;
  end;
  
  // Read first IFD
  FStream.Position := Header.IFDOffset;
  if FStream.Read(IFDCount, 2) = 2 then
  begin
    if Header.ByteOrder = TIFF_BIG_ENDIAN then
      IFDCount := SwapEndian(IFDCount);
      
    // Parse IFD entries
    for i := 0 to IFDCount - 1 do
    begin
      if FStream.Read(Entry, SizeOf(Entry)) = SizeOf(Entry) then
      begin
        if Header.ByteOrder = TIFF_BIG_ENDIAN then
        begin
          Entry.Tag := SwapEndian(Entry.Tag);
          Entry.FieldType := SwapEndian(Entry.FieldType);
          Entry.Count := SwapEndian(Entry.Count);
          Entry.ValueOffset := SwapEndian(Entry.ValueOffset);
        end;
        
        case Entry.Tag of
          256: // ImageWidth
            begin
              HasWidth := True;
              FResult.ImageWidth := Entry.ValueOffset;
            end;
          257: // ImageHeight
            begin
              HasHeight := True;
              FResult.ImageHeight := Entry.ValueOffset;
            end;
          258: // BitsPerSample
            begin
              HasBitsPerSample := True;
              if Entry.Count = 1 then
                FResult.BitDepth := Entry.ValueOffset and $FFFF
              else
                FResult.BitDepth := Entry.Count * 8;
            end;
        end;
      end;
    end;
  end;
  
  if not HasWidth then
    AddIssue(Ord(isError), 'TIFF005', 'Missing ImageWidth tag', Header.IFDOffset);
    
  if not HasHeight then
    AddIssue(Ord(isError), 'TIFF006', 'Missing ImageHeight tag', Header.IFDOffset);
    
  if not HasBitsPerSample then
    AddIssue(Ord(isWarning), 'TIFF007', 'Missing BitsPerSample tag', Header.IFDOffset);
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateTGA: Boolean;
var
  Header: packed record
    IDLength: Byte;
    ColorMapType: Byte;
    ImageType: Byte;
    ColorMapSpec: array[0..4] of Byte;
    XOrigin: Word;
    YOrigin: Word;
    Width: Word;
    Height: Word;
    PixelDepth: Byte;
    ImageDescriptor: Byte;
  end;
  ExpectedDataSize: Integer;
  HeaderSize: Integer;
  ColorMapLength: Word;
  ColorMapEntrySize: Byte;
begin
  Result := False;
  
  FStream.Position := 0;
  
  // Read header
  if FStream.Read(Header, SizeOf(Header)) <> SizeOf(Header) then
  begin
    AddIssue(Ord(isCritical), 'TGA001', 'Cannot read TGA header', 0);
    Exit;
  end;
  
  // Validate image type
  if not (Header.ImageType in [0, 1, 2, 3, 9, 10, 11]) then
  begin
    AddIssue(Ord(isError), 'TGA002', 
      Format('Invalid image type: %d', [Header.ImageType]), 2);
  end;
  
  // Validate dimensions
  if Header.Width = 0 then
    AddIssue(Ord(isError), 'TGA003', 'Width is 0', 12);
    
  if Header.Height = 0 then
    AddIssue(Ord(isError), 'TGA004', 'Height is 0', 14);
    
  // Validate pixel depth
  if not (Header.PixelDepth in [8, 15, 16, 24, 32]) then
  begin
    AddIssue(Ord(isError), 'TGA005', 
      Format('Invalid pixel depth: %d', [Header.PixelDepth]), 16);
  end;
  
  FResult.ImageWidth := Header.Width;
  FResult.ImageHeight := Header.Height;
  FResult.BitDepth := Header.PixelDepth;
  FResult.HasAlpha := Header.PixelDepth = 32;
  
  // Check file size
  if FValidationLevel >= vlThorough then
  begin
    HeaderSize := 18 + Header.IDLength;
    
    // Add color map size if present
    if Header.ColorMapType = 1 then
    begin
      Move(Header.ColorMapSpec[0], ColorMapLength, 2);
      ColorMapEntrySize := Header.ColorMapSpec[4];
      HeaderSize := HeaderSize + (ColorMapLength * ((ColorMapEntrySize + 7) div 8));
    end;
    
    // Calculate image data size
    case Header.ImageType of
      0: ExpectedDataSize := 0; // No image data
      1, 2, 3: // Uncompressed
        ExpectedDataSize := Header.Width * Header.Height * ((Header.PixelDepth + 7) div 8);
      9, 10, 11: // RLE compressed - can't predict exact size
        ExpectedDataSize := 0;
    end;
    
    if (ExpectedDataSize > 0) and (HeaderSize + ExpectedDataSize > FStream.Size) then
    begin
      AddIssue(Ord(isError), 'TGA006', 'File truncated: missing image data', FStream.Size);
    end;
  end;
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateICO: Boolean;
var
  Header: packed record
    Reserved: Word;
    ImageType: Word;
    ImageCount: Word;
  end;
  DirEntry: packed record
    Width: Byte;
    Height: Byte;
    ColorCount: Byte;
    Reserved: Byte;
    Planes: Word;
    BitCount: Word;
    BytesInRes: Cardinal;
    ImageOffset: Cardinal;
  end;
  i: Integer;
begin
  Result := False;
  
  FStream.Position := 0;
  
  // Read header
  if FStream.Read(Header, SizeOf(Header)) <> SizeOf(Header) then
  begin
    AddIssue(Ord(isCritical), 'ICO001', 'Cannot read ICO header', 0);
    Exit;
  end;
  
  // Validate header
  if Header.Reserved <> 0 then
    AddIssue(Ord(isWarning), 'ICO002', 'Reserved field not zero', 0);
    
  if not (Header.ImageType in [1, 2]) then // 1=ICO, 2=CUR
  begin
    AddIssue(Ord(isError), 'ICO003', 
      Format('Invalid image type: %d', [Header.ImageType]), 2);
  end;
  
  if Header.ImageCount = 0 then
  begin
    AddIssue(Ord(isError), 'ICO004', 'No images in file', 4);
    Exit;
  end;
  
  // Read directory entries
  for i := 0 to Header.ImageCount - 1 do
  begin
    if FStream.Read(DirEntry, SizeOf(DirEntry)) <> SizeOf(DirEntry) then
    begin
      AddIssue(Ord(isError), 'ICO005', 
        Format('Cannot read directory entry %d', [i]), 6 + i * SizeOf(DirEntry));
      Break;
    end;
    
    // Store info from first image
    if i = 0 then
    begin
      if DirEntry.Width = 0 then
        FResult.ImageWidth := 256
      else
        FResult.ImageWidth := DirEntry.Width;
        
      if DirEntry.Height = 0 then
        FResult.ImageHeight := 256
      else
        FResult.ImageHeight := DirEntry.Height;
        
      FResult.BitDepth := DirEntry.BitCount;
    end;
    
    // Validate offset and size
    if DirEntry.ImageOffset >= FStream.Size then
    begin
      AddIssue(Ord(isError), 'ICO006', 
        Format('Invalid image offset for entry %d', [i]), 
        6 + i * SizeOf(DirEntry) + 12);
    end;
    
    if DirEntry.ImageOffset + DirEntry.BytesInRes > FStream.Size then
    begin
      AddIssue(Ord(isError), 'ICO007', 
        Format('Image data truncated for entry %d', [i]), 
        DirEntry.ImageOffset);
    end;
  end;
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateWebP: Boolean;
var
  RIFFHeader: packed record
    RIFF: array[0..3] of AnsiChar;
    FileSize: Cardinal;
    WEBP: array[0..3] of AnsiChar;
  end;
  ChunkHeader: packed record
    FourCC: array[0..3] of AnsiChar;
    ChunkSize: Cardinal;
  end;
  VP8Header: packed record
    Width: Word;
    Height: Word;
  end;
  Bits: Cardinal;
  Width, Height: array[0..2] of Byte;
begin
  Result := False;
  
  FStream.Position := 0;
  
  // Read RIFF header
  if FStream.Read(RIFFHeader, SizeOf(RIFFHeader)) <> SizeOf(RIFFHeader) then
  begin
    AddIssue(Ord(isCritical), 'WEBP001', 'Cannot read WebP header', 0);
    Exit;
  end;
  
  // Validate RIFF signature
  if RIFFHeader.RIFF <> WEBP_RIFF then
  begin
    AddIssue(Ord(isCritical), 'WEBP002', 'Invalid RIFF signature', 0);
    Exit;
  end;
  
  // Validate WebP signature
  if RIFFHeader.WEBP <> WEBP_WEBP then
  begin
    AddIssue(Ord(isCritical), 'WEBP003', 'Invalid WebP signature', 8);
    Exit;
  end;
  
  // Validate file size
  if RIFFHeader.FileSize + 8 <> FStream.Size then
  begin
    AddIssue(Ord(isWarning), 'WEBP004', 
      Format('File size mismatch: header says %d, actual is %d', 
        [RIFFHeader.FileSize + 8, FStream.Size]), 4, True);
  end;
  
  // Read first chunk
  if FStream.Read(ChunkHeader, SizeOf(ChunkHeader)) = SizeOf(ChunkHeader) then
  begin
    // VP8, VP8L, VP8X are valid WebP chunks
    if (ChunkHeader.FourCC = 'VP8 ') or 
       (ChunkHeader.FourCC = 'VP8L') or 
       (ChunkHeader.FourCC = 'VP8X') then
    begin
      // Basic validation passed
      FResult.Format := ifWebP;
      
      // Try to extract dimensions (simplified)
      if ChunkHeader.FourCC = 'VP8 ' then
      begin
        // Lossy WebP
        FStream.Seek(6, soFromCurrent); // Skip frame tag
        if FStream.Read(VP8Header, 4) = 4 then
        begin
          FResult.ImageWidth := VP8Header.Width and $3FFF;
          FResult.ImageHeight := VP8Header.Height and $3FFF;
        end;
      end
      else if ChunkHeader.FourCC = 'VP8L' then
      begin
        // Lossless WebP
        FStream.Seek(1, soFromCurrent); // Skip signature
        if FStream.Read(Bits, 4) = 4 then
        begin
          FResult.ImageWidth := ((Bits and $3FFF) + 1);
          FResult.ImageHeight := (((Bits shr 14) and $3FFF) + 1);
        end;
      end
      else if ChunkHeader.FourCC = 'VP8X' then
      begin
        // Extended WebP
        FStream.Seek(4, soFromCurrent); // Skip flags
        if FStream.Read(Width, 3) = 3 then
        begin
          if FStream.Read(Height, 3) = 3 then
          begin
          FResult.ImageWidth := (Width[0] or (Width[1] shl 8) or (Width[2] shl 16)) + 1;
          FResult.ImageHeight := (Height[0] or (Height[1] shl 8) or (Height[2] shl 16)) + 1;
          end;
        end;
      end;
    end
    else
    begin
      AddIssue(Ord(isError), 'WEBP005', 
        Format('Invalid chunk type: %s', [ChunkHeader.FourCC]), 12);
    end;
  end;
  
  Result := FResult.IsValid;
end;

function TImageValidator.ValidateFile(const AFileName: string; 
  ALevel: TValidationLevel): TValidationResult;
var
  FS: TFileStream;
begin
  // Initialize result
  FillChar(Result, SizeOf(Result), 0);
  Result.Format := ifUnknown;
  Result.IsValid := False;
  Result.CanLoad := False;
  SetLength(Result.Issues, 0);
  
  // Check if file exists
  if not FileExists(AFileName) then
  begin
    SetLength(Result.Issues, 1);
    Result.Issues[0].Severity := isCritical;
    Result.Issues[0].Code := 'FILE001';
    Result.Issues[0].Message := 'File not found: ' + AFileName;
    Result.Issues[0].Offset := -1;
    Result.Issues[0].CanRepair := False;
    Exit;
  end;
  
  // Try to open file
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  except
    on E: Exception do
    begin
      SetLength(Result.Issues, 1);
      Result.Issues[0].Severity := isCritical;
      Result.Issues[0].Code := 'FILE002';
      Result.Issues[0].Message := 'Cannot open file: ' + E.Message;
      Result.Issues[0].Offset := -1;
      Result.Issues[0].CanRepair := False;
      Exit;
    end;
  end;
  
  try
    Result := ValidateStream(FS, ALevel);
  finally
    FS.Free;
  end;
end;

function TImageValidator.ValidateStream(AStream: TStream; 
  ALevel: TValidationLevel): TValidationResult;
var
  i: Integer;
begin
  FStream := AStream;
  FOwnsStream := False;
  FValidationLevel := ALevel;
  
  // Initialize result
  FillChar(FResult, SizeOf(FResult), 0);
  FResult.IsValid := True;
  FResult.CanLoad := True;
  FResult.FileSize := AStream.Size;
  SetLength(FResult.Issues, 0);
  
  // Check file size limit
  if AStream.Size > MAX_FILE_SIZE then
  begin
    AddIssue(Ord(isCritical), 'SIZE001', 
      Format('File size exceeds maximum limit of %d MB', [MAX_FILE_SIZE div (1024*1024)]), 0);
    FResult.CanLoad := False;
    Result := FResult;
    Exit;
  end;
  
  // Detect format
  FResult.Format := DetectFormat;
  
  if FResult.Format = ifUnknown then
  begin
    AddIssue(Ord(isCritical), 'FMT001', 'Unknown or unsupported image format', 0);
    FResult.CanLoad := False;
  end
  else
  begin
    // Validate based on format
    case FResult.Format of
      ifBMP: ValidateBMP;
      ifPNG: ValidatePNG;
      ifJPEG: ValidateJPEG;
      ifGIF: ValidateGIF;
      ifTIFF: ValidateTIFF;
      ifTGA: ValidateTGA;
      ifICO: ValidateICO;
      ifWebP: ValidateWebP;
    end;
    
    // Determine if file can be loaded despite issues
    for i := 0 to High(FResult.Issues) do
    begin
      if FResult.Issues[i].Severity >= isCritical then
      begin
        FResult.CanLoad := False;
        Break;
      end;
    end;
  end;
  
  Result := FResult;
end;

function TImageValidator.ValidateMemory(AData: Pointer; ASize: Integer;
  ALevel: TValidationLevel): TValidationResult;
var
  MS: TMemoryStream;
begin
  MS := TMemoryStream.Create;
  try
    MS.WriteBuffer(AData^, ASize);
    MS.Position := 0;
    Result := ValidateStream(MS, ALevel);
  finally
    MS.Free;
  end;
end;

function TImageValidator.RepairFile(const AFileName: string; 
  const AOutputFileName: string): Boolean;
var
  InputFS, OutputFS: TFileStream;
  OutputName: string;
begin
  Result := False;
  
  // Validate input file
  if not FileExists(AFileName) then
    Exit;
  
  if AOutputFileName = '' then
    OutputName := ChangeFileExt(AFileName, '.repaired' + ExtractFileExt(AFileName))
  else
  begin
    OutputName := ExpandFileName(AOutputFileName);
    // Security check: prevent path traversal
    if Pos('..', OutputName) > 0 then
      raise EGraphicsError.Create('Invalid output path: path traversal detected');
  end;
  
  // Don't overwrite input file
  if SameText(ExpandFileName(AFileName), OutputName) then
    raise EGraphicsError.Create('Output file cannot be the same as input file');
    
  InputFS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    OutputFS := TFileStream.Create(OutputName, fmCreate);
    try
      Result := RepairStream(InputFS, OutputFS);
    finally
      OutputFS.Free;
    end;
  finally
    InputFS.Free;
  end;
end;

function TImageValidator.RepairStream(AInputStream, AOutputStream: TStream): Boolean;
var
  ValidationResult: TValidationResult;
  CanRepair: Boolean;
  i: Integer;
  Header: array[0..53] of Byte;
  FileSize: Cardinal;
  LastBytes: array[0..1] of Byte;
  LastByte: Byte;
begin
  Result := False;
  
  // First validate to identify issues
  ValidationResult := ValidateStream(AInputStream, vlThorough);
  
  if ValidationResult.IsValid then
  begin
    // No repair needed, just copy
    AInputStream.Position := 0;
    AOutputStream.CopyFrom(AInputStream, AInputStream.Size);
    Result := True;
    Exit;
  end;
  
  // Check if any issues can be repaired
  CanRepair := False;
  for i := 0 to High(ValidationResult.Issues) do
  begin
    if ValidationResult.Issues[i].CanRepair then
    begin
      CanRepair := True;
      Break;
    end;
  end;
  
  if not CanRepair then
    Exit;
  
  // Perform format-specific repairs
  AInputStream.Position := 0;
  
  case ValidationResult.Format of
    ifBMP:
      begin
        // Copy and fix BMP header issues
        AInputStream.Read(Header, SizeOf(Header));
        
        // Fix file size in header
        FileSize := AInputStream.Size;
        Move(FileSize, Header[2], 4);
        
        // Write fixed header
        AOutputStream.Write(Header, SizeOf(Header));
        
        // Copy rest of file
        AOutputStream.CopyFrom(AInputStream, AInputStream.Size - SizeOf(Header));
        Result := True;
      end;
      
    ifJPEG:
      begin
        // Copy JPEG and add missing EOI if needed
        AOutputStream.CopyFrom(AInputStream, AInputStream.Size);
        
        // Check if EOI is missing
        AInputStream.Position := AInputStream.Size - 2;
        AInputStream.Read(LastBytes, 2);
        
        if (LastBytes[0] <> $FF) or (LastBytes[1] <> $D9) then
        begin
          // Add EOI marker
          LastBytes[0] := $FF;
          LastBytes[1] := $D9;
          AOutputStream.Write(LastBytes, 2);
        end;
        Result := True;
      end;
      
    ifGIF:
      begin
        // Copy GIF and add missing terminator if needed
        AOutputStream.CopyFrom(AInputStream, AInputStream.Size);
        
        // Check if terminator is missing
        AInputStream.Position := AInputStream.Size - 1;
        AInputStream.Read(LastByte, 1);
        
        if LastByte <> $3B then
        begin
          // Add terminator
          LastByte := $3B;
          AOutputStream.Write(LastByte, 1);
        end;
        Result := True;
      end;
      
    else
      // For other formats, just copy as-is if issues are minor
      if ValidationResult.CanLoad then
      begin
        AInputStream.Position := 0;
        AOutputStream.CopyFrom(AInputStream, AInputStream.Size);
        Result := True;
      end;
  end;
end;

class function TImageValidator.GetFormatName(AFormat: TImageFormat): string;
begin
  case AFormat of
    ifBMP: Result := 'Windows Bitmap';
    ifPNG: Result := 'Portable Network Graphics';
    ifJPEG: Result := 'JPEG';
    ifGIF: Result := 'Graphics Interchange Format';
    ifTIFF: Result := 'Tagged Image File Format';
    ifTGA: Result := 'Truevision TGA';
    ifICO: Result := 'Windows Icon';
    ifWebP: Result := 'WebP';
    else Result := 'Unknown';
  end;
end;

class function TImageValidator.GetFormatExtension(AFormat: TImageFormat): string;
begin
  case AFormat of
    ifBMP: Result := '.bmp';
    ifPNG: Result := '.png';
    ifJPEG: Result := '.jpg';
    ifGIF: Result := '.gif';
    ifTIFF: Result := '.tif';
    ifTGA: Result := '.tga';
    ifICO: Result := '.ico';
    ifWebP: Result := '.webp';
    else Result := '';
  end;
end;

class function TImageValidator.IsFormatSupported(AFormat: TImageFormat): Boolean;
begin
  Result := AFormat in [ifBMP, ifPNG, ifJPEG, ifGIF, ifTIFF, ifTGA, ifICO, ifWebP];
end;

{ TImageFormatInfo }

class function TImageFormatInfo.GetBMPInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed BMP information
  Result := False;
end;

class function TImageFormatInfo.GetPNGInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed PNG information
  Result := False;
end;

class function TImageFormatInfo.GetJPEGInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed JPEG information
  Result := False;
end;

class function TImageFormatInfo.GetGIFInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed GIF information
  Result := False;
end;

class function TImageFormatInfo.GetTIFFInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed TIFF information
  Result := False;
end;

class function TImageFormatInfo.GetTGAInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed TGA information
  Result := False;
end;

class function TImageFormatInfo.GetICOInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed ICO information
  Result := False;
end;

class function TImageFormatInfo.GetWebPInfo(AStream: TStream; 
  out AInfo: TValidationResult): Boolean;
begin
  // Implementation would extract detailed WebP information
  Result := False;
end;

end.