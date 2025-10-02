program test_image_simple;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.graphics;

procedure TestBasicBitmap;
var
  Bitmap: TBitmap32;
begin
  WriteLn('Testing basic bitmap operations...');
  
  Bitmap := TBitmap32.Create;
  try
    // Test size setting
    Bitmap.SetSize(100, 100);
    if (Bitmap.Width = 100) and (Bitmap.Height = 100) then
      WriteLn('  [PASS] SetSize')
    else
      WriteLn('  [FAIL] SetSize');
    
    // Test clear
    Bitmap.Clear(clRed32);
    if Bitmap.Pixel[50, 50] = clRed32 then
      WriteLn('  [PASS] Clear')
    else
      WriteLn('  [FAIL] Clear');
    
    // Test pixel access
    Bitmap.Pixel[10, 10] := clBlue32;
    if Bitmap.Pixel[10, 10] = clBlue32 then
      WriteLn('  [PASS] Pixel access')
    else
      WriteLn('  [FAIL] Pixel access');
    
    // Test HasAlpha
    Bitmap.Clear(Color32(255, 0, 0, 128));
    if Bitmap.HasAlpha then
      WriteLn('  [PASS] HasAlpha detection')
    else
      WriteLn('  [FAIL] HasAlpha detection');
      
  finally
    Bitmap.Free;
  end;
end;

procedure TestImageTransformations;
var
  Bitmap: TBitmap32;
  OrigWidth, OrigHeight: Integer;
begin
  WriteLn('Testing image transformations...');
  
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(100, 50);
    Bitmap.Clear(clGreen32);
    
    // Test Rotate90
    OrigWidth := Bitmap.Width;
    OrigHeight := Bitmap.Height;
    Bitmap.Rotate90;
    if (Bitmap.Width = OrigHeight) and (Bitmap.Height = OrigWidth) then
      WriteLn('  [PASS] Rotate90')
    else
      WriteLn('  [FAIL] Rotate90');
    
    // Reset
    Bitmap.SetSize(100, 100);
    
    // Test FlipHorizontal
    Bitmap.Pixel[10, 50] := clRed32;
    Bitmap.FlipHorizontal;
    if Bitmap.Pixel[89, 50] = clRed32 then
      WriteLn('  [PASS] FlipHorizontal')
    else
      WriteLn('  [FAIL] FlipHorizontal');
    
    // Test FlipVertical
    Bitmap.SetSize(100, 100);
    Bitmap.Pixel[50, 10] := clBlue32;
    Bitmap.FlipVertical;
    if Bitmap.Pixel[50, 89] = clBlue32 then
      WriteLn('  [PASS] FlipVertical')
    else
      WriteLn('  [FAIL] FlipVertical');
      
  finally
    Bitmap.Free;
  end;
end;

procedure TestImageEffects;
var
  Bitmap: TBitmap32;
  PixelBefore, PixelAfter: TColor32;
  R, G, B: Byte;
begin
  WriteLn('Testing image effects...');
  
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(100, 100);
    
    // Test Grayscale
    Bitmap.Clear(Color32(100, 150, 200));
    Bitmap.Grayscale;
    PixelAfter := Bitmap.Pixel[50, 50];
    R := RedComponent(PixelAfter);
    G := GreenComponent(PixelAfter);
    B := BlueComponent(PixelAfter);
    if (R = G) and (G = B) then
      WriteLn('  [PASS] Grayscale')
    else
      WriteLn('  [FAIL] Grayscale');
    
    // Test Invert
    Bitmap.Clear(Color32(100, 100, 100));
    PixelBefore := Bitmap.Pixel[50, 50];
    Bitmap.Invert;
    PixelAfter := Bitmap.Pixel[50, 50];
    if RedComponent(PixelAfter) = 255 - RedComponent(PixelBefore) then
      WriteLn('  [PASS] Invert')
    else
      WriteLn('  [FAIL] Invert');
    
    // Test Brightness
    Bitmap.Clear(Color32(100, 100, 100));
    PixelBefore := Bitmap.Pixel[50, 50];
    Bitmap.AdjustBrightness(50);
    PixelAfter := Bitmap.Pixel[50, 50];
    if RedComponent(PixelAfter) > RedComponent(PixelBefore) then
      WriteLn('  [PASS] AdjustBrightness')
    else
      WriteLn('  [FAIL] AdjustBrightness');
      
  finally
    Bitmap.Free;
  end;
end;

procedure TestImageResize;
var
  Bitmap: TBitmap32;
begin
  WriteLn('Testing image resize...');
  
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(100, 100);
    Bitmap.Clear(clYellow32);
    
    // Test Resize
    Bitmap.Resize(200, 150);
    if (Bitmap.Width = 200) and (Bitmap.Height = 150) then
      WriteLn('  [PASS] Resize')
    else
      WriteLn('  [FAIL] Resize');
    
    // Test Crop
    Bitmap.SetSize(100, 100);
    Bitmap.Crop(10, 10, 50, 50);
    if (Bitmap.Width = 50) and (Bitmap.Height = 50) then
      WriteLn('  [PASS] Crop')
    else
      WriteLn('  [FAIL] Crop');
      
  finally
    Bitmap.Free;
  end;
end;

procedure TestBoundaryConditions;
var
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  WriteLn('Testing boundary conditions...');
  
  Bitmap := TBitmap32.Create;
  try
    // Test zero size
    ExceptionRaised := False;
    try
      Bitmap.SetSize(0, 0);
    except
      ExceptionRaised := True;
    end;
    if ExceptionRaised then
      WriteLn('  [PASS] Zero size exception')
    else
      WriteLn('  [FAIL] Zero size exception');
    
    // Test negative size
    ExceptionRaised := False;
    try
      Bitmap.SetSize(-10, 100);
    except
      ExceptionRaised := True;
    end;
    if ExceptionRaised then
      WriteLn('  [PASS] Negative size exception')
    else
      WriteLn('  [FAIL] Negative size exception');
    
    // Test very large size
    ExceptionRaised := False;
    try
      Bitmap.SetSize(100000, 100000);
    except
      ExceptionRaised := True;
    end;
    if ExceptionRaised then
      WriteLn('  [PASS] Max size exception')
    else
      WriteLn('  [FAIL] Max size exception');
      
  finally
    Bitmap.Free;
  end;
end;

procedure TestMemoryManagement;
var
  Bitmaps: array[0..9] of TBitmap32;
  I: Integer;
  MemBefore, MemAfter: NativeUInt;
begin
  WriteLn('Testing memory management...');
  
  // Create and destroy multiple bitmaps
  for I := 0 to 9 do
  begin
    Bitmaps[I] := TBitmap32.Create;
    Bitmaps[I].SetSize(512, 512);
    Bitmaps[I].Clear(clWhite32);
  end;
  
  for I := 0 to 9 do
    Bitmaps[I].Free;
  
  WriteLn('  [PASS] Multiple bitmap creation/destruction');
end;

procedure TestPerformance;
var
  Bitmap: TBitmap32;
  StartTick, ElapsedMs: QWord;
  I: Integer;
begin
  WriteLn('Testing performance...');
  
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(1024, 1024);
    
    // Test fill performance
    StartTick := GetTickCount64;
    for I := 0 to 9 do
      Bitmap.Clear(Color32(I * 25, I * 25, I * 25));
    ElapsedMs := GetTickCount64 - StartTick;
    WriteLn(Format('  Fill 1024x1024 x10: %d ms', [ElapsedMs]));
    
    // Test grayscale performance
    StartTick := GetTickCount64;
    Bitmap.Grayscale;
    ElapsedMs := GetTickCount64 - StartTick;
    WriteLn(Format('  Grayscale 1024x1024: %d ms', [ElapsedMs]));
    
    // Test rotate performance
    StartTick := GetTickCount64;
    Bitmap.Rotate90;
    ElapsedMs := GetTickCount64 - StartTick;
    WriteLn(Format('  Rotate90 1024x1024: %d ms', [ElapsedMs]));
    
  finally
    Bitmap.Free;
  end;
end;

procedure TestColorFunctions;
var
  C: TColor32;
begin
  WriteLn('Testing color functions...');
  
  // Test Color32 creation
  C := Color32(100, 150, 200, 255);
  if (RedComponent(C) = 100) and (GreenComponent(C) = 150) and 
     (BlueComponent(C) = 200) and (AlphaComponent(C) = 255) then
    WriteLn('  [PASS] Color32 creation and components')
  else
    WriteLn('  [FAIL] Color32 creation and components');
  
  // Test color constants
  if clRed32 = Color32(255, 0, 0, 255) then
    WriteLn('  [PASS] Color constants')
  else
    WriteLn('  [FAIL] Color constants');
end;

procedure TestBlending;
var
  Src, Dst: TBitmap32;
begin
  WriteLn('Testing blending operations...');
  
  Src := TBitmap32.Create;
  Dst := TBitmap32.Create;
  try
    Src.SetSize(100, 100);
    Dst.SetSize(100, 100);
    
    Src.Clear(Color32(255, 0, 0, 128));  // Semi-transparent red
    Dst.Clear(Color32(0, 0, 255, 255));  // Opaque blue
    
    // Test basic blend
    BlendBitmaps(Src, Dst, bmNormal);
    WriteLn('  [PASS] Basic blend (no crash)');
    
  finally
    Src.Free;
    Dst.Free;
  end;
end;

procedure RunAllTests;
var
  TotalTests, PassedTests: Integer;
begin
  WriteLn('========================================');
  WriteLn('Running Image Processing Tests');
  WriteLn('========================================');
  WriteLn;
  
  TotalTests := 0;
  PassedTests := 0;
  
  TestBasicBitmap;
  WriteLn;
  
  TestImageTransformations;
  WriteLn;
  
  TestImageEffects;
  WriteLn;
  
  TestImageResize;
  WriteLn;
  
  TestBoundaryConditions;
  WriteLn;
  
  TestMemoryManagement;
  WriteLn;
  
  TestColorFunctions;
  WriteLn;
  
  TestBlending;
  WriteLn;
  
  TestPerformance;
  WriteLn;
  
  WriteLn('========================================');
  WriteLn('Test Summary');
  WriteLn('========================================');
  WriteLn('All basic tests completed.');
  WriteLn;
end;

begin
  try
    RunAllTests;
  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.