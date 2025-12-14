unit fafafa.core.graphics;

{$mode objfpc}{$H+}
{$POINTERMATH ON}

interface

uses
  Classes, SysUtils, fafafa.core.math;

type
  // Basic color type - 32-bit ARGB
  TColor32 = Cardinal;
  PColor32 = ^TColor32;
  
  // Color constants
  const
    clBlack32   = TColor32($FF000000);
    clWhite32   = TColor32($FFFFFFFF);
    clRed32     = TColor32($FFFF0000);
    clGreen32   = TColor32($FF00FF00);
    clBlue32    = TColor32($FF0000FF);
    clYellow32  = TColor32($FFFFFF00);
    clCyan32    = TColor32($FF00FFFF);
    clMagenta32 = TColor32($FFFF00FF);
    clGray32    = TColor32($FF808080);
    clTransparent32 = TColor32($00000000);

type
  // Blend modes
  TBlendMode = (
    bmNormal,
    bmMultiply,
    bmScreen,
    bmOverlay,
    bmSoftLight,
    bmHardLight,
    bmColorDodge,
    bmColorBurn,
    bmDarken,
    bmLighten,
    bmDifference,
    bmExclusion
  );
  
  // Pixel formats
  TPixelFormat = (
    pfUnknown,
    pf8bit,
    pf16bit,
    pf24bit,
    pf32bit
  );
  
  // Forward declarations
  TBitmap32 = class;
  
  // Custom exception types
  EGraphicsError = class(Exception);
  EImageFormatError = class(EGraphicsError);
  EInvalidDimension = class(EGraphicsError);
  EOutOfMemory = class(EGraphicsError);
  
  { TBitmap32 }
  TBitmap32 = class(TPersistent)
  private
    FWidth: Integer;
    FHeight: Integer;
    FBits: PColor32;
    FAllocated: Boolean;
    FStride: Integer;
    
    function GetPixel(X, Y: Integer): TColor32; inline;
    procedure SetPixel(X, Y: Integer; Value: TColor32); inline;
    function GetScanLine(Y: Integer): PColor32; inline;
    procedure CheckDimensions(AWidth, AHeight: Integer);
    procedure AllocateMemory;
    procedure FreeMemory;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure SetSize(AWidth, AHeight: Integer);
    procedure Clear(Color: TColor32 = clBlack32);
    procedure Assign(Source: TPersistent); override;
    
    // Basic operations
    procedure FlipHorizontal;
    procedure FlipVertical;
    procedure Rotate90;
    procedure Rotate180;
    procedure Rotate270;
    procedure Crop(X, Y, Width, Height: Integer);
    procedure Resize(NewWidth, NewHeight: Integer);
    
    // Effects
    procedure Grayscale;
    procedure Invert;
    procedure AdjustBrightness(Amount: Integer);
    procedure AdjustContrast(Factor: Double);
    procedure AdjustGamma(Gamma: Double);
    procedure GaussianBlur(Radius: Double);
    procedure Sharpen(Amount: Double);
    
    // Alpha channel
    function HasAlpha: Boolean;
    procedure SetAlpha(Alpha: Byte);
    procedure PreMultiplyAlpha;
    procedure UnPreMultiplyAlpha;
    
    // Properties
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Bits: PColor32 read FBits;
    property Stride: Integer read FStride;
    property Pixel[X, Y: Integer]: TColor32 read GetPixel write SetPixel; default;
    property ScanLine[Y: Integer]: PColor32 read GetScanLine;
  end;
  
// Color functions
function Color32(R, G, B: Byte; A: Byte = 255): TColor32; inline;
function RedComponent(Color: TColor32): Byte; inline;
function GreenComponent(Color: TColor32): Byte; inline;
function BlueComponent(Color: TColor32): Byte; inline;
function AlphaComponent(Color: TColor32): Byte; inline;
function SetAlphaComponent(Color: TColor32; Alpha: Byte): TColor32; inline;

// Blending functions
procedure BlendPixel(var Dest: TColor32; Src: TColor32; Mode: TBlendMode = bmNormal);
procedure BlendBitmaps(Src, Dest: TBitmap32; Mode: TBlendMode = bmNormal);

// Utility functions
function ClampByte(Value: Integer): Byte; inline;
function GetMemoryUsage: NativeUInt;

implementation

const
  MAX_BITMAP_SIZE = 32768;  // Maximum width or height
  MAX_TOTAL_PIXELS = 1073741824; // 1 billion pixels max (~ 4GB at 32bpp)

{ Color functions }

function Color32(R, G, B: Byte; A: Byte): TColor32;
begin
  Result := (A shl 24) or (R shl 16) or (G shl 8) or B;
end;

function RedComponent(Color: TColor32): Byte;
begin
  Result := (Color shr 16) and $FF;
end;

function GreenComponent(Color: TColor32): Byte;
begin
  Result := (Color shr 8) and $FF;
end;

function BlueComponent(Color: TColor32): Byte;
begin
  Result := Color and $FF;
end;

function AlphaComponent(Color: TColor32): Byte;
begin
  Result := (Color shr 24) and $FF;
end;

function SetAlphaComponent(Color: TColor32; Alpha: Byte): TColor32;
begin
  Result := (Color and $00FFFFFF) or (TColor32(Alpha) shl 24);
end;

function ClampByte(Value: Integer): Byte;
begin
  if Value < 0 then
    Result := 0
  else if Value > 255 then
    Result := 255
  else
    Result := Value;
end;

function GetMemoryUsage: NativeUInt;
begin
  // Basic estimation for bitmap memory (width * height * 4 bytes per pixel)
  // This is a simplified calculation - actual usage may be higher due to alignment
  Result := 0; // Returns 0 since this is a global function without bitmap context
  // For per-bitmap memory usage, use TBitmap32.GetMemorySize instead
end;

{ TBitmap32 }

constructor TBitmap32.Create;
begin
  inherited Create;
  FWidth := 0;
  FHeight := 0;
  FBits := nil;
  FAllocated := False;
  FStride := 0;
end;

destructor TBitmap32.Destroy;
begin
  FreeMemory;
  inherited Destroy;
end;

procedure TBitmap32.CheckDimensions(AWidth, AHeight: Integer);
begin
  if (AWidth < 0) or (AHeight < 0) then
    raise EInvalidDimension.Create('Bitmap dimensions cannot be negative');
    
  if (AWidth = 0) or (AHeight = 0) then
    raise EInvalidDimension.Create('Bitmap dimensions cannot be zero');
    
  if (AWidth > MAX_BITMAP_SIZE) or (AHeight > MAX_BITMAP_SIZE) then
    raise EInvalidDimension.CreateFmt('Bitmap dimensions exceed maximum (%d)', [MAX_BITMAP_SIZE]);
    
  // Check for integer overflow
  if Int64(AWidth) * Int64(AHeight) > MAX_TOTAL_PIXELS then
    raise EInvalidDimension.Create('Total pixel count exceeds maximum');
end;

procedure TBitmap32.AllocateMemory;
var
  Size: NativeUInt;
begin
  if FAllocated then
    FreeMemory;
    
  if (FWidth > 0) and (FHeight > 0) then
  begin
    FStride := FWidth * SizeOf(TColor32);
    Size := NativeUInt(FStride) * NativeUInt(FHeight);
    
    try
      GetMem(FBits, Size);
      FillChar(FBits^, Size, 0);
      FAllocated := True;
    except
      on E: EOutOfMemory do
      begin
        FBits := nil;
        FAllocated := False;
        raise EOutOfMemory.CreateFmt('Cannot allocate %d bytes for bitmap', [Size]);
      end;
    end;
  end;
end;

procedure TBitmap32.FreeMemory;
begin
  if FAllocated and Assigned(FBits) then
  begin
    FreeMem(FBits);
    FBits := nil;
    FAllocated := False;
  end;
end;

procedure TBitmap32.SetSize(AWidth, AHeight: Integer);
begin
  CheckDimensions(AWidth, AHeight);
  
  if (AWidth <> FWidth) or (AHeight <> FHeight) then
  begin
    FWidth := AWidth;
    FHeight := AHeight;
    AllocateMemory;
  end;
end;

procedure TBitmap32.Clear(Color: TColor32);
var
  P: PColor32;
  I: Integer;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    P^ := Color;
    Inc(P);
  end;
end;

function TBitmap32.GetPixel(X, Y: Integer): TColor32;
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    Result := PColor32(PByte(FBits) + Y * FStride + X * SizeOf(TColor32))^
  else
    Result := 0;
end;

procedure TBitmap32.SetPixel(X, Y: Integer; Value: TColor32);
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    PColor32(PByte(FBits) + Y * FStride + X * SizeOf(TColor32))^ := Value;
end;

function TBitmap32.GetScanLine(Y: Integer): PColor32;
begin
  if (Y >= 0) and (Y < FHeight) then
    Result := PColor32(PByte(FBits) + Y * FStride)
  else
    Result := nil;
end;

procedure TBitmap32.Assign(Source: TPersistent);
var
  SrcBitmap: TBitmap32;
begin
  if Source is TBitmap32 then
  begin
    SrcBitmap := TBitmap32(Source);
    SetSize(SrcBitmap.Width, SrcBitmap.Height);
    if FAllocated and SrcBitmap.FAllocated then
      Move(SrcBitmap.FBits^, FBits^, FStride * FHeight);
  end
  else
    inherited Assign(Source);
end;

procedure TBitmap32.AssignTo(Dest: TPersistent);
begin
  if Dest is TBitmap32 then
    TBitmap32(Dest).Assign(Self)
  else
    inherited AssignTo(Dest);
end;

procedure TBitmap32.FlipHorizontal;
var
  Y, X: Integer;
  Line: PColor32;
  Temp: TColor32;
begin
  if not FAllocated then
    Exit;
    
  for Y := 0 to FHeight - 1 do
  begin
    Line := ScanLine[Y];
    for X := 0 to (FWidth div 2) - 1 do
    begin
      Temp := Line[X];
      Line[X] := Line[FWidth - 1 - X];
      Line[FWidth - 1 - X] := Temp;
    end;
  end;
end;

procedure TBitmap32.FlipVertical;
var
  Y: Integer;
  TempLine: PColor32;
  LineSize: Integer;
begin
  if not FAllocated then
    Exit;
    
  LineSize := FStride;
  GetMem(TempLine, LineSize);
  try
    for Y := 0 to (FHeight div 2) - 1 do
    begin
      Move(ScanLine[Y]^, TempLine^, LineSize);
      Move(ScanLine[FHeight - 1 - Y]^, ScanLine[Y]^, LineSize);
      Move(TempLine^, ScanLine[FHeight - 1 - Y]^, LineSize);
    end;
  finally
    FreeMem(TempLine);
  end;
end;

procedure TBitmap32.Rotate90;
var
  NewBitmap: TBitmap32;
  X, Y: Integer;
begin
  if not FAllocated then
    Exit;
    
  NewBitmap := TBitmap32.Create;
  try
    NewBitmap.SetSize(FHeight, FWidth);
    
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
        NewBitmap.Pixel[FHeight - 1 - Y, X] := Pixel[X, Y];
    
    // Swap dimensions and data
    SetSize(NewBitmap.Width, NewBitmap.Height);
    Move(NewBitmap.FBits^, FBits^, FStride * FHeight);
  finally
    NewBitmap.Free;
  end;
end;

procedure TBitmap32.Rotate180;
var
  X, Y: Integer;
  Temp: TColor32;
  P1, P2: PColor32;
begin
  if not FAllocated then
    Exit;
    
  for Y := 0 to (FHeight div 2) - 1 do
  begin
    for X := 0 to FWidth - 1 do
    begin
      P1 := PColor32(PByte(FBits) + Y * FStride + X * SizeOf(TColor32));
      P2 := PColor32(PByte(FBits) + (FHeight - 1 - Y) * FStride + (FWidth - 1 - X) * SizeOf(TColor32));
      Temp := P1^;
      P1^ := P2^;
      P2^ := Temp;
    end;
  end;
  
  // Handle middle row for odd height
  if Odd(FHeight) then
  begin
    Y := FHeight div 2;
    for X := 0 to (FWidth div 2) - 1 do
    begin
      P1 := PColor32(PByte(FBits) + Y * FStride + X * SizeOf(TColor32));
      P2 := PColor32(PByte(FBits) + Y * FStride + (FWidth - 1 - X) * SizeOf(TColor32));
      Temp := P1^;
      P1^ := P2^;
      P2^ := Temp;
    end;
  end;
end;

procedure TBitmap32.Rotate270;
var
  NewBitmap: TBitmap32;
  X, Y: Integer;
begin
  if not FAllocated then
    Exit;
    
  NewBitmap := TBitmap32.Create;
  try
    NewBitmap.SetSize(FHeight, FWidth);
    
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
        NewBitmap.Pixel[Y, FWidth - 1 - X] := Pixel[X, Y];
    
    // Swap dimensions and data
    SetSize(NewBitmap.Width, NewBitmap.Height);
    Move(NewBitmap.FBits^, FBits^, FStride * FHeight);
  finally
    NewBitmap.Free;
  end;
end;

procedure TBitmap32.Crop(X, Y, Width, Height: Integer);
var
  NewBitmap: TBitmap32;
  SrcY, DstY: Integer;
begin
  if not FAllocated then
    Exit;
    
  // Validate crop region
  if X < 0 then begin Width := Width + X; X := 0; end;
  if Y < 0 then begin Height := Height + Y; Y := 0; end;
  if X + Width > FWidth then Width := FWidth - X;
  if Y + Height > FHeight then Height := FHeight - Y;
  
  if (Width <= 0) or (Height <= 0) then
    raise EInvalidDimension.Create('Invalid crop dimensions');
    
  NewBitmap := TBitmap32.Create;
  try
    NewBitmap.SetSize(Width, Height);
    
    for DstY := 0 to Height - 1 do
    begin
      SrcY := Y + DstY;
      Move(PColor32(PByte(FBits) + SrcY * FStride + X * SizeOf(TColor32))^,
           NewBitmap.ScanLine[DstY]^,
           Width * SizeOf(TColor32));
    end;
    
    SetSize(NewBitmap.Width, NewBitmap.Height);
    Move(NewBitmap.FBits^, FBits^, FStride * FHeight);
  finally
    NewBitmap.Free;
  end;
end;

procedure TBitmap32.Resize(NewWidth, NewHeight: Integer);
var
  NewBitmap: TBitmap32;
  X, Y: Integer;
  SrcX, SrcY: Integer;
  XRatio, YRatio: Double;
begin
  if not FAllocated then
    Exit;
    
  CheckDimensions(NewWidth, NewHeight);
  
  if (NewWidth = FWidth) and (NewHeight = FHeight) then
    Exit;
    
  NewBitmap := TBitmap32.Create;
  try
    NewBitmap.SetSize(NewWidth, NewHeight);
    
    XRatio := FWidth / NewWidth;
    YRatio := FHeight / NewHeight;
    
    // Simple nearest neighbor scaling
    for Y := 0 to NewHeight - 1 do
    begin
      SrcY := Trunc(Y * YRatio);
      for X := 0 to NewWidth - 1 do
      begin
        SrcX := Trunc(X * XRatio);
        NewBitmap.Pixel[X, Y] := Pixel[SrcX, SrcY];
      end;
    end;
    
    SetSize(NewBitmap.Width, NewBitmap.Height);
    Move(NewBitmap.FBits^, FBits^, FStride * FHeight);
  finally
    NewBitmap.Free;
  end;
end;

procedure TBitmap32.Grayscale;
var
  P: PColor32;
  I: Integer;
  R, G, B, Gray: Byte;
  Color: TColor32;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    R := RedComponent(Color);
    G := GreenComponent(Color);
    B := BlueComponent(Color);
    
    // Use standard luminance formula
    Gray := Round(0.299 * R + 0.587 * G + 0.114 * B);
    
    P^ := Color32(Gray, Gray, Gray, AlphaComponent(Color));
    Inc(P);
  end;
end;

procedure TBitmap32.Invert;
var
  P: PColor32;
  I: Integer;
  Color: TColor32;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    P^ := Color32(
      255 - RedComponent(Color),
      255 - GreenComponent(Color),
      255 - BlueComponent(Color),
      AlphaComponent(Color)
    );
    Inc(P);
  end;
end;

procedure TBitmap32.AdjustBrightness(Amount: Integer);
var
  P: PColor32;
  I: Integer;
  Color: TColor32;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    P^ := Color32(
      ClampByte(RedComponent(Color) + Amount),
      ClampByte(GreenComponent(Color) + Amount),
      ClampByte(BlueComponent(Color) + Amount),
      AlphaComponent(Color)
    );
    Inc(P);
  end;
end;

procedure TBitmap32.AdjustContrast(Factor: Double);
var
  P: PColor32;
  I: Integer;
  Color: TColor32;
  R, G, B: Integer;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    
    R := Round((RedComponent(Color) - 128) * Factor + 128);
    G := Round((GreenComponent(Color) - 128) * Factor + 128);
    B := Round((BlueComponent(Color) - 128) * Factor + 128);
    
    P^ := Color32(ClampByte(R), ClampByte(G), ClampByte(B), AlphaComponent(Color));
    Inc(P);
  end;
end;

procedure TBitmap32.AdjustGamma(Gamma: Double);
var
  P: PColor32;
  I: Integer;
  Color: TColor32;
  GammaTable: array[0..255] of Byte;
begin
  if not FAllocated then
    Exit;
    
  // Build gamma lookup table
  for I := 0 to 255 do
    GammaTable[I] := ClampByte(Round(Power(I / 255.0, 1.0 / Gamma) * 255));
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    P^ := Color32(
      GammaTable[RedComponent(Color)],
      GammaTable[GreenComponent(Color)],
      GammaTable[BlueComponent(Color)],
      AlphaComponent(Color)
    );
    Inc(P);
  end;
end;

procedure TBitmap32.GaussianBlur(Radius: Double);
begin
  // Gaussian blur not yet implemented
  // This would require:
  // 1. Convolution kernel generation based on radius
  // 2. Separable filter implementation for performance
  // 3. Edge handling (wrap, clamp, or mirror)
  // Consider using external image processing libraries for now
  if Radius > 0 then
    raise ENotSupported.Create('Gaussian blur not yet implemented. Use external image processing library or implement convolution kernel.');
end;

procedure TBitmap32.Sharpen(Amount: Double);
begin
  // Sharpen filter not yet implemented
  // This would require:
  // 1. Unsharp mask algorithm or convolution kernel
  // 2. Edge-preserving considerations
  // 3. Amount parameter validation and scaling
  // Consider using external image processing libraries for now
  if Amount > 0 then
    raise ENotSupported.Create('Sharpen filter not yet implemented. Use external image processing library or implement unsharp mask algorithm.');
end;

function TBitmap32.HasAlpha: Boolean;
var
  P: PColor32;
  I: Integer;
begin
  Result := False;
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    if AlphaComponent(P^) <> 255 then
    begin
      Result := True;
      Exit;
    end;
    Inc(P);
  end;
end;

procedure TBitmap32.SetAlpha(Alpha: Byte);
var
  P: PColor32;
  I: Integer;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    P^ := SetAlphaComponent(P^, Alpha);
    Inc(P);
  end;
end;

procedure TBitmap32.PreMultiplyAlpha;
var
  P: PColor32;
  I: Integer;
  Color: TColor32;
  A: Byte;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    A := AlphaComponent(Color);
    if A < 255 then
    begin
      P^ := Color32(
        (RedComponent(Color) * A) div 255,
        (GreenComponent(Color) * A) div 255,
        (BlueComponent(Color) * A) div 255,
        A
      );
    end;
    Inc(P);
  end;
end;

procedure TBitmap32.UnPreMultiplyAlpha;
var
  P: PColor32;
  I: Integer;
  Color: TColor32;
  A: Byte;
begin
  if not FAllocated then
    Exit;
    
  P := FBits;
  for I := 0 to FWidth * FHeight - 1 do
  begin
    Color := P^;
    A := AlphaComponent(Color);
    if (A > 0) and (A < 255) then
    begin
      P^ := Color32(
        Min(255, (RedComponent(Color) * 255) div A),
        Min(255, (GreenComponent(Color) * 255) div A),
        Min(255, (BlueComponent(Color) * 255) div A),
        A
      );
    end;
    Inc(P);
  end;
end;

{ Blending functions }

procedure BlendPixel(var Dest: TColor32; Src: TColor32; Mode: TBlendMode);
var
  SrcA, DstA, OutA: Byte;
  SrcR, SrcG, SrcB: Byte;
  DstR, DstG, DstB: Byte;
  OutR, OutG, OutB: Byte;
begin
  if Mode = bmNormal then
  begin
    // Simple alpha blending
    SrcA := AlphaComponent(Src);
    if SrcA = 0 then
      Exit
    else if SrcA = 255 then
      Dest := Src
    else
    begin
      DstA := AlphaComponent(Dest);
      SrcR := RedComponent(Src);
      SrcG := GreenComponent(Src);
      SrcB := BlueComponent(Src);
      DstR := RedComponent(Dest);
      DstG := GreenComponent(Dest);
      DstB := BlueComponent(Dest);
      
      OutA := SrcA + DstA - (SrcA * DstA) div 255;
      if OutA = 0 then
        Dest := 0
      else
      begin
        OutR := (SrcR * SrcA + DstR * DstA * (255 - SrcA) div 255) div OutA;
        OutG := (SrcG * SrcA + DstG * DstA * (255 - SrcA) div 255) div OutA;
        OutB := (SrcB * SrcA + DstB * DstA * (255 - SrcA) div 255) div OutA;
        
        Dest := Color32(ClampByte(OutR), ClampByte(OutG), ClampByte(OutB), OutA);
      end;
    end;
  end;
  // Other blend modes would be implemented here
end;

procedure BlendBitmaps(Src, Dest: TBitmap32; Mode: TBlendMode);
var
  X, Y: Integer;
  SrcP, DstP: PColor32;
begin
  if (Src.Width <> Dest.Width) or (Src.Height <> Dest.Height) then
    Exit;
    
  for Y := 0 to Src.Height - 1 do
  begin
    SrcP := Src.ScanLine[Y];
    DstP := Dest.ScanLine[Y];
    for X := 0 to Src.Width - 1 do
    begin
      BlendPixel(DstP^, SrcP^, Mode);
      Inc(SrcP);
      Inc(DstP);
    end;
  end;
end;

end.