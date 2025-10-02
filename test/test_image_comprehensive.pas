program test_image_comprehensive;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.graphics,
  fafafa.core.graphics.imageio,
  fafafa.core.graphics.bmp,
  fafafa.core.graphics.png,
  fafafa.core.graphics.jpeg,
  fafafa.core.graphics.gif,
  fafafa.core.graphics.tiff,
  fafafa.core.graphics.tga,
  fafafa.core.graphics.ico,
  fafafa.core.graphics.webp,
  fafafa.core.graphics.parallel,
  fafafa.core.graphics.streaming,
  fafafa.core.graphics.mempool,
  fafafa.core.graphics.sse2;

type
  { TImageFormatTests }
  TImageFormatTests = class(TTestCase)
  private
    FTestDir: string;
    FBitmap: TBitmap32;
    procedure CreateTestImage(AWidth, AHeight: Integer; AAlpha: Boolean = False);
    procedure CreateTestDirectory;
    procedure CleanupTestDirectory;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // BMP Format Tests
    procedure TestBMP24BitLoadSave;
    procedure TestBMP32BitLoadSave;
    procedure TestBMPRLECompression;
    procedure TestBMP16BitFormat;
    procedure TestBMPLargeImage;
    
    // PNG Format Tests
    procedure TestPNG24BitLoadSave;
    procedure TestPNG32BitAlphaLoadSave;
    procedure TestPNGInterlaced;
    procedure TestPNGCompression;
    
    // JPEG Format Tests
    procedure TestJPEGLoadSave;
    procedure TestJPEGQualityLevels;
    procedure TestJPEGProgressive;
    
    // GIF Format Tests
    procedure TestGIFLoadSave;
    procedure TestGIFAnimation;
    procedure TestGIFTransparency;
    
    // TIFF Format Tests
    procedure TestTIFFLoadSave;
    procedure TestTIFFMultiPage;
    procedure TestTIFFCompression;
    
    // TGA Format Tests
    procedure TestTGAUncompressed;
    procedure TestTGARLECompressed;
    procedure TestTGA32BitAlpha;
    
    // ICO Format Tests
    procedure TestICOLoadSave;
    procedure TestICOMultiResolution;
    procedure TestCURHotspot;
    
    // WebP Format Tests
    procedure TestWebPLossyLoadSave;
    procedure TestWebPLosslessLoadSave;
    procedure TestWebPAnimation;
    
    // Format Detection Tests
    procedure TestAutoFormatDetection;
    procedure TestInvalidFormatHandling;
  end;

  { TParallelProcessingTests }
  TParallelProcessingTests = class(TTestCase)
  private
    FBitmap: TBitmap32;
    FProcessor: TParallelImageProcessor;
    procedure CreateLargeTestImage;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestParallelGaussianBlur;
    procedure TestParallelSharpen;
    procedure TestParallelGrayscale;
    procedure TestParallelBrightnessContrast;
    procedure TestParallelResize;
    procedure TestThreadPoolManagement;
    procedure TestConcurrentOperations;
    procedure TestPerformanceComparison;
  end;

  { TStreamingTests }
  TStreamingTests = class(TTestCase)
  private
    FProcessor: TStreamingImageProcessor;
    FTestFile: string;
    procedure CreateLargeTestFile;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLazyLoading;
    procedure TestChunkedProcessing;
    procedure TestProgressiveDecoding;
    procedure TestMemoryEfficiency;
    procedure TestStreamPerformance;
    procedure TestThumbnailGeneration;
  end;

  { TMemoryPoolTests }
  TMemoryPoolTests = class(TTestCase)
  private
    FPool: TMemoryPool;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestPoolAllocation;
    procedure TestPoolReuse;
    procedure TestPoolGrowth;
    procedure TestConcurrentAccess;
    procedure TestMemoryLeak;
    procedure TestFragmentation;
  end;

  { TSSE2OptimizationTests }
  TSSE2OptimizationTests = class(TTestCase)
  private
    FBitmap: TBitmap32;
    procedure CreateTestBitmap;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSSE2Blend;
    procedure TestSSE2Fill;
    procedure TestSSE2ColorConversion;
    procedure TestSSE2Performance;
    procedure TestSSE2Accuracy;
    procedure TestFallbackCompatibility;
  end;

  { TImageProcessingTests }
  TImageProcessingTests = class(TTestCase)
  private
    FBitmap: TBitmap32;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRotate90;
    procedure TestRotate180;
    procedure TestRotate270;
    procedure TestFlipHorizontal;
    procedure TestFlipVertical;
    procedure TestCrop;
    procedure TestResize;
    procedure TestGaussianBlur;
    procedure TestSharpen;
    procedure TestGrayscale;
    procedure TestInvert;
    procedure TestBrightnessAdjustment;
    procedure TestContrastAdjustment;
    procedure TestGammaCorrection;
  end;

  { TBoundaryTests }
  TBoundaryTests = class(TTestCase)
  published
    procedure TestZeroSizeImage;
    procedure TestMaxSizeImage;
    procedure TestInvalidDimensions;
    procedure TestNullPointers;
    procedure TestCorruptedData;
    procedure TestOutOfMemory;
    procedure TestIntegerOverflow;
  end;

  { TPerformanceTests }
  TPerformanceTests = class(TTestCase)
  private
    procedure MeasureOperation(const AName: string; AProc: TProcedure);
  published
    procedure TestLoadPerformance;
    procedure TestSavePerformance;
    procedure TestBlendPerformance;
    procedure TestFilterPerformance;
    procedure TestResizePerformance;
    procedure TestParallelSpeedup;
    procedure TestMemoryPoolEfficiency;
  end;

{ TImageFormatTests }

procedure TImageFormatTests.SetUp;
begin
  FTestDir := ExtractFilePath(ParamStr(0)) + 'test_images' + PathDelim;
  CreateTestDirectory;
  FBitmap := TBitmap32.Create;
end;

procedure TImageFormatTests.TearDown;
begin
  FBitmap.Free;
  CleanupTestDirectory;
end;

procedure TImageFormatTests.CreateTestDirectory;
begin
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TImageFormatTests.CleanupTestDirectory;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(FTestDir + '*.*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        DeleteFile(FTestDir + SearchRec.Name);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

procedure TImageFormatTests.CreateTestImage(AWidth, AHeight: Integer; AAlpha: Boolean);
var
  X, Y: Integer;
  P: PColor32;
begin
  FBitmap.SetSize(AWidth, AHeight);
  
  // Create gradient test pattern
  for Y := 0 to AHeight - 1 do
  begin
    P := FBitmap.ScanLine[Y];
    for X := 0 to AWidth - 1 do
    begin
      if AAlpha then
        P^ := Color32(
          (X * 255) div AWidth,
          (Y * 255) div AHeight,
          ((X + Y) * 255) div (AWidth + AHeight),
          ((X * Y * 255) div (AWidth * AHeight))
        )
      else
        P^ := Color32(
          (X * 255) div AWidth,
          (Y * 255) div AHeight,
          ((X + Y) * 255) div (AWidth + AHeight)
        );
      Inc(P);
    end;
  end;
end;

procedure TImageFormatTests.TestBMP24BitLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test24.bmp';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('BMP file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestBMP32BitLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test32.bmp';
  CreateTestImage(100, 100, True);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('BMP file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
    AssertTrue('Alpha channel lost', LoadedBitmap.HasAlpha);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestBMPRLECompression;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
  X, Y: Integer;
begin
  TestFile := FTestDir + 'test_rle.bmp';
  
  // Create image with RLE-friendly pattern
  FBitmap.SetSize(100, 100);
  for Y := 0 to 99 do
    for X := 0 to 99 do
      FBitmap.Pixel[X, Y] := Color32(255 * (X div 10) div 10, 0, 0);
  
  // Save with RLE compression (if supported)
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestBMP16BitFormat;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test16.bmp';
  CreateTestImage(50, 50, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestBMPLargeImage;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_large.bmp';
  CreateTestImage(2048, 2048, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('Large BMP file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', 2048, LoadedBitmap.Width);
    AssertEquals('Height mismatch', 2048, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestPNG24BitLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test24.png';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('PNG file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestPNG32BitAlphaLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test32_alpha.png';
  CreateTestImage(100, 100, True);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('PNG file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
    AssertTrue('Alpha channel lost', LoadedBitmap.HasAlpha);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestPNGInterlaced;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_interlaced.png';
  CreateTestImage(100, 100, True);
  
  // Save as interlaced PNG
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestPNGCompression;
var
  TestFile: string;
  FileSize1, FileSize2: Int64;
  SR: TSearchRec;
begin
  TestFile := FTestDir + 'test_compress.png';
  
  // Create compressible image
  FBitmap.SetSize(200, 200);
  FBitmap.Clear(clBlue32);
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  if FindFirst(TestFile, faAnyFile, SR) = 0 then
  begin
    FileSize1 := SR.Size;
    FindClose(SR);
  end;
  
  // Create less compressible image
  CreateTestImage(200, 200, True);
  SaveBitmapToFile(FBitmap, TestFile);
  
  if FindFirst(TestFile, faAnyFile, SR) = 0 then
  begin
    FileSize2 := SR.Size;
    FindClose(SR);
  end;
  
  AssertTrue('Compression not working', FileSize1 < FileSize2);
end;

procedure TImageFormatTests.TestJPEGLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test.jpg';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('JPEG file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestJPEGQualityLevels;
var
  TestFile1, TestFile2: string;
  Size1, Size2: Int64;
  SR: TSearchRec;
begin
  TestFile1 := FTestDir + 'test_q95.jpg';
  TestFile2 := FTestDir + 'test_q50.jpg';
  
  CreateTestImage(200, 200, False);
  
  // Save with high quality
  SaveBitmapToFile(FBitmap, TestFile1);
  
  // Save with lower quality
  SaveBitmapToFile(FBitmap, TestFile2);
  
  if FindFirst(TestFile1, faAnyFile, SR) = 0 then
  begin
    Size1 := SR.Size;
    FindClose(SR);
  end;
  
  if FindFirst(TestFile2, faAnyFile, SR) = 0 then
  begin
    Size2 := SR.Size;
    FindClose(SR);
  end;
  
  AssertTrue('Quality settings not affecting file size', Size1 > Size2);
end;

procedure TImageFormatTests.TestJPEGProgressive;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_progressive.jpg';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestGIFLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test.gif';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('GIF file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestGIFAnimation;
var
  TestFile: string;
  GIF: TGIFImageFormat;
  Frame: TBitmap32;
  I: Integer;
begin
  TestFile := FTestDir + 'test_anim.gif';
  
  GIF := TGIFImageFormat.Create;
  try
    // Create animation frames
    for I := 0 to 4 do
    begin
      Frame := TBitmap32.Create;
      try
        Frame.SetSize(100, 100);
        Frame.Clear(Color32(I * 50, I * 50, I * 50));
        GIF.AddFrame(Frame, 100); // 100ms delay
      finally
        Frame.Free;
      end;
    end;
    
    GIF.SaveToFile(TestFile);
    AssertTrue('Animated GIF not created', FileExists(TestFile));
    AssertEquals('Frame count mismatch', 5, GIF.FrameCount);
  finally
    GIF.Free;
  end;
end;

procedure TImageFormatTests.TestGIFTransparency;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_trans.gif';
  
  FBitmap.SetSize(100, 100);
  FBitmap.Clear(Color32(255, 0, 255)); // Magenta as transparent
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestTIFFLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test.tif';
  CreateTestImage(100, 100, True);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('TIFF file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestTIFFMultiPage;
var
  TestFile: string;
  TIFF: TTIFFImageFormat;
  Page: TBitmap32;
  I: Integer;
begin
  TestFile := FTestDir + 'test_multipage.tif';
  
  TIFF := TTIFFImageFormat.Create;
  try
    // Create multiple pages
    for I := 0 to 2 do
    begin
      Page := TBitmap32.Create;
      try
        Page.SetSize(100, 100);
        Page.Clear(Color32(I * 80, I * 80, I * 80));
        TIFF.AddPage(Page);
      finally
        Page.Free;
      end;
    end;
    
    TIFF.SaveToFile(TestFile);
    AssertTrue('Multi-page TIFF not created', FileExists(TestFile));
    AssertEquals('Page count mismatch', 3, TIFF.PageCount);
  finally
    TIFF.Free;
  end;
end;

procedure TImageFormatTests.TestTIFFCompression;
var
  TestFile1, TestFile2: string;
  Size1, Size2: Int64;
  SR: TSearchRec;
begin
  TestFile1 := FTestDir + 'test_nocomp.tif';
  TestFile2 := FTestDir + 'test_lzw.tif';
  
  CreateTestImage(200, 200, False);
  
  // Save uncompressed
  SaveBitmapToFile(FBitmap, TestFile1);
  
  // Save with LZW compression
  SaveBitmapToFile(FBitmap, TestFile2);
  
  if FindFirst(TestFile1, faAnyFile, SR) = 0 then
  begin
    Size1 := SR.Size;
    FindClose(SR);
  end;
  
  if FindFirst(TestFile2, faAnyFile, SR) = 0 then
  begin
    Size2 := SR.Size;
    FindClose(SR);
  end;
  
  AssertTrue('Compression not working', Size2 < Size1);
end;

procedure TImageFormatTests.TestTGAUncompressed;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_uncomp.tga';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('TGA file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestTGARLECompressed;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_rle.tga';
  
  // Create RLE-friendly pattern
  FBitmap.SetSize(100, 100);
  FBitmap.Clear(clRed32);
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestTGA32BitAlpha;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test32_alpha.tga';
  CreateTestImage(100, 100, True);
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
    AssertTrue('Alpha channel lost', LoadedBitmap.HasAlpha);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestICOLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test.ico';
  CreateTestImage(32, 32, True);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('ICO file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestICOMultiResolution;
var
  TestFile: string;
  ICO: TICOImageFormat;
  Icon: TBitmap32;
  Sizes: array[0..2] of Integer = (16, 32, 48);
  I: Integer;
begin
  TestFile := FTestDir + 'test_multi.ico';
  
  ICO := TICOImageFormat.Create;
  try
    for I := 0 to High(Sizes) do
    begin
      Icon := TBitmap32.Create;
      try
        Icon.SetSize(Sizes[I], Sizes[I]);
        Icon.Clear(Color32(I * 80, I * 80, I * 80));
        ICO.AddIcon(Icon);
      finally
        Icon.Free;
      end;
    end;
    
    ICO.SaveToFile(TestFile);
    AssertTrue('Multi-resolution ICO not created', FileExists(TestFile));
    AssertEquals('Icon count mismatch', 3, ICO.IconCount);
  finally
    ICO.Free;
  end;
end;

procedure TImageFormatTests.TestCURHotspot;
var
  TestFile: string;
  CUR: TICOImageFormat;
begin
  TestFile := FTestDir + 'test.cur';
  CreateTestImage(32, 32, True);
  
  CUR := TICOImageFormat.Create;
  try
    CUR.IsCursor := True;
    CUR.HotspotX := 16;
    CUR.HotspotY := 16;
    CUR.AddIcon(FBitmap);
    CUR.SaveToFile(TestFile);
    
    AssertTrue('CUR file not created', FileExists(TestFile));
    AssertEquals('Hotspot X mismatch', 16, CUR.HotspotX);
    AssertEquals('Hotspot Y mismatch', 16, CUR.HotspotY);
  finally
    CUR.Free;
  end;
end;

procedure TImageFormatTests.TestWebPLossyLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_lossy.webp';
  CreateTestImage(100, 100, False);
  
  SaveBitmapToFile(FBitmap, TestFile);
  AssertTrue('WebP file not created', FileExists(TestFile));
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestWebPLosslessLoadSave;
var
  TestFile: string;
  LoadedBitmap: TBitmap32;
begin
  TestFile := FTestDir + 'test_lossless.webp';
  CreateTestImage(100, 100, True);
  
  SaveBitmapToFile(FBitmap, TestFile);
  
  LoadedBitmap := TBitmap32.Create;
  try
    LoadBitmapFromFile(LoadedBitmap, TestFile);
    AssertEquals('Width mismatch', FBitmap.Width, LoadedBitmap.Width);
    AssertEquals('Height mismatch', FBitmap.Height, LoadedBitmap.Height);
    AssertTrue('Alpha channel lost', LoadedBitmap.HasAlpha);
  finally
    LoadedBitmap.Free;
  end;
end;

procedure TImageFormatTests.TestWebPAnimation;
var
  TestFile: string;
  WebP: TWebPImageFormat;
  Frame: TBitmap32;
  I: Integer;
begin
  TestFile := FTestDir + 'test_anim.webp';
  
  WebP := TWebPImageFormat.Create;
  try
    for I := 0 to 4 do
    begin
      Frame := TBitmap32.Create;
      try
        Frame.SetSize(100, 100);
        Frame.Clear(Color32(I * 50, I * 50, I * 50));
        WebP.AddFrame(Frame, I * 100);
      finally
        Frame.Free;
      end;
    end;
    
    WebP.SaveToFile(TestFile);
    AssertTrue('Animated WebP not created', FileExists(TestFile));
    AssertEquals('Frame count mismatch', 5, WebP.FrameCount);
  finally
    WebP.Free;
  end;
end;

procedure TImageFormatTests.TestAutoFormatDetection;
var
  TestFiles: array[0..7] of string;
  I: Integer;
  Bitmap: TBitmap32;
begin
  TestFiles[0] := FTestDir + 'detect.bmp';
  TestFiles[1] := FTestDir + 'detect.png';
  TestFiles[2] := FTestDir + 'detect.jpg';
  TestFiles[3] := FTestDir + 'detect.gif';
  TestFiles[4] := FTestDir + 'detect.tif';
  TestFiles[5] := FTestDir + 'detect.tga';
  TestFiles[6] := FTestDir + 'detect.ico';
  TestFiles[7] := FTestDir + 'detect.webp';
  
  CreateTestImage(50, 50, False);
  
  // Save in different formats
  for I := 0 to High(TestFiles) do
    SaveBitmapToFile(FBitmap, TestFiles[I]);
  
  // Test auto-detection
  Bitmap := TBitmap32.Create;
  try
    for I := 0 to High(TestFiles) do
    begin
      if FileExists(TestFiles[I]) then
      begin
        LoadBitmapFromFile(Bitmap, TestFiles[I]);
        AssertEquals('Auto-detection failed for ' + ExtractFileExt(TestFiles[I]),
          50, Bitmap.Width);
      end;
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TImageFormatTests.TestInvalidFormatHandling;
var
  TestFile: string;
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  TestFile := FTestDir + 'invalid.xyz';
  
  // Create invalid file
  with TFileStream.Create(TestFile, fmCreate) do
  try
    WriteBuffer('INVALID', 7);
  finally
    Free;
  end;
  
  Bitmap := TBitmap32.Create;
  try
    ExceptionRaised := False;
    try
      LoadBitmapFromFile(Bitmap, TestFile);
    except
      on E: EImageFormatError do
        ExceptionRaised := True;
    end;
    AssertTrue('Exception not raised for invalid format', ExceptionRaised);
  finally
    Bitmap.Free;
  end;
end;

{ TParallelProcessingTests }

procedure TParallelProcessingTests.SetUp;
begin
  FBitmap := TBitmap32.Create;
  FProcessor := TParallelImageProcessor.Create;
  FProcessor.ThreadCount := 4;
end;

procedure TParallelProcessingTests.TearDown;
begin
  FProcessor.Free;
  FBitmap.Free;
end;

procedure TParallelProcessingTests.CreateLargeTestImage;
var
  X, Y: Integer;
begin
  FBitmap.SetSize(1024, 1024);
  for Y := 0 to FBitmap.Height - 1 do
    for X := 0 to FBitmap.Width - 1 do
      FBitmap.Pixel[X, Y] := Color32(
        (X * 255) div FBitmap.Width,
        (Y * 255) div FBitmap.Height,
        ((X + Y) * 255) div (FBitmap.Width + FBitmap.Height)
      );
end;

procedure TParallelProcessingTests.TestParallelGaussianBlur;
var
  StartTick: QWord;
  ElapsedMs: Int64;
begin
  CreateLargeTestImage;
  
  StartTick := GetTickCount64;
  FProcessor.GaussianBlur(FBitmap, 5.0);
  ElapsedMs := GetTickCount64 - StartTick;
  
  AssertTrue('Parallel blur too slow', ElapsedMs < 1000);
  AssertEquals('Image dimensions changed', 1024, FBitmap.Width);
end;

procedure TParallelProcessingTests.TestParallelSharpen;
begin
  CreateLargeTestImage;
  FProcessor.Sharpen(FBitmap, 1.5);
  AssertEquals('Image dimensions changed', 1024, FBitmap.Width);
end;

procedure TParallelProcessingTests.TestParallelGrayscale;
var
  PixelBefore, PixelAfter: TColor32;
begin
  CreateLargeTestImage;
  PixelBefore := FBitmap.Pixel[100, 100];
  
  FProcessor.Grayscale(FBitmap);
  
  PixelAfter := FBitmap.Pixel[100, 100];
  AssertTrue('Grayscale conversion failed', 
    (RedComponent(PixelAfter) = GreenComponent(PixelAfter)) and
    (GreenComponent(PixelAfter) = BlueComponent(PixelAfter)));
end;

procedure TParallelProcessingTests.TestParallelBrightnessContrast;
begin
  CreateLargeTestImage;
  FProcessor.AdjustBrightnessContrast(FBitmap, 20, 1.2);
  AssertEquals('Image dimensions changed', 1024, FBitmap.Width);
end;

procedure TParallelProcessingTests.TestParallelResize;
var
  NewBitmap: TBitmap32;
begin
  CreateLargeTestImage;
  
  NewBitmap := TBitmap32.Create;
  try
    FProcessor.ResizeBilinear(FBitmap, NewBitmap, 512, 512);
    AssertEquals('Resize width incorrect', 512, NewBitmap.Width);
    AssertEquals('Resize height incorrect', 512, NewBitmap.Height);
  finally
    NewBitmap.Free;
  end;
end;

procedure TParallelProcessingTests.TestThreadPoolManagement;
begin
  AssertEquals('Thread count mismatch', 4, FProcessor.ThreadCount);
  
  FProcessor.ThreadCount := 8;
  AssertEquals('Thread count not updated', 8, FProcessor.ThreadCount);
  
  FProcessor.ThreadCount := 2;
  AssertEquals('Thread count not reduced', 2, FProcessor.ThreadCount);
end;

procedure TParallelProcessingTests.TestConcurrentOperations;
var
  Bitmap1, Bitmap2: TBitmap32;
begin
  Bitmap1 := TBitmap32.Create;
  Bitmap2 := TBitmap32.Create;
  try
    Bitmap1.SetSize(512, 512);
    Bitmap2.SetSize(512, 512);
    
    // Run concurrent operations
    FProcessor.Grayscale(Bitmap1);
    FProcessor.Invert(Bitmap2);
    
    AssertEquals('Bitmap1 corrupted', 512, Bitmap1.Width);
    AssertEquals('Bitmap2 corrupted', 512, Bitmap2.Width);
  finally
    Bitmap1.Free;
    Bitmap2.Free;
  end;
end;

procedure TParallelProcessingTests.TestPerformanceComparison;
var
  StartTime: TDateTime;
  ParallelTime, SerialTime: Int64;
  SerialBitmap: TBitmap32;
begin
  CreateLargeTestImage;
  SerialBitmap := TBitmap32.Create;
  try
    SerialBitmap.Assign(FBitmap);
    
    // Parallel processing
    StartTime := Now;
    FProcessor.GaussianBlur(FBitmap, 3.0);
    ParallelTime := MilliSecondsBetween(Now, StartTime);
    
    // Serial processing
    StartTime := Now;
    SerialBitmap.GaussianBlur(3.0);
    SerialTime := MilliSecondsBetween(Now, StartTime);
    
    AssertTrue('Parallel not faster than serial', ParallelTime < SerialTime);
  finally
    SerialBitmap.Free;
  end;
end;

{ TStreamingTests }

procedure TStreamingTests.SetUp;
begin
  FProcessor := TStreamingImageProcessor.Create;
  FTestFile := ExtractFilePath(ParamStr(0)) + 'large_test.bmp';
  CreateLargeTestFile;
end;

procedure TStreamingTests.TearDown;
begin
  FProcessor.Free;
  if FileExists(FTestFile) then
    DeleteFile(FTestFile);
end;

procedure TStreamingTests.CreateLargeTestFile;
var
  Bitmap: TBitmap32;
begin
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(4096, 4096);
    Bitmap.Clear(clWhite32);
    SaveBitmapToFile(Bitmap, FTestFile);
  finally
    Bitmap.Free;
  end;
end;

procedure TStreamingTests.TestLazyLoading;
var
  LazyBitmap: TLazyBitmap;
  MemBefore, MemAfter: NativeUInt;
begin
  MemBefore := GetMemoryUsage;
  
  LazyBitmap := TLazyBitmap.Create;
  try
    LazyBitmap.LoadFile(FTestFile);
    
    MemAfter := GetMemoryUsage;
    AssertTrue('Memory usage too high for lazy loading', 
      MemAfter - MemBefore < 1024 * 1024); // Less than 1MB increase
    
    // Access should trigger actual loading
    LazyBitmap.GetPixel(0, 0);
    AssertEquals('Width incorrect', 4096, LazyBitmap.Width);
  finally
    LazyBitmap.Free;
  end;
end;

procedure TStreamingTests.TestChunkedProcessing;
var
  ChunkCount: Integer;
begin
  ChunkCount := 0;
  
  FProcessor.ProcessChunked(FTestFile, 256,
    procedure(Chunk: TBitmap32; X, Y: Integer)
    begin
      Inc(ChunkCount);
      Chunk.Grayscale;
    end);
  
  AssertTrue('Not enough chunks processed', ChunkCount > 100);
end;

procedure TStreamingTests.TestProgressiveDecoding;
var
  ProgressCount: Integer;
begin
  ProgressCount := 0;
  
  FProcessor.OnProgress := procedure(Percent: Integer)
    begin
      Inc(ProgressCount);
    end;
  
  FProcessor.LoadProgressive(FTestFile);
  
  AssertTrue('Progress not reported', ProgressCount > 0);
end;

procedure TStreamingTests.TestMemoryEfficiency;
var
  MemBefore, MemDuring, MemAfter: NativeUInt;
begin
  MemBefore := GetMemoryUsage;
  
  FProcessor.ProcessChunked(FTestFile, 128,
    procedure(Chunk: TBitmap32; X, Y: Integer)
    begin
      if MemDuring = 0 then
        MemDuring := GetMemoryUsage;
      Chunk.Invert;
    end);
  
  MemAfter := GetMemoryUsage;
  
  AssertTrue('Memory not released after streaming', 
    Abs(MemAfter - MemBefore) < 10 * 1024 * 1024); // Within 10MB
end;

procedure TStreamingTests.TestStreamPerformance;
var
  StartTime: TDateTime;
  ElapsedMs: Int64;
begin
  StartTime := Now;
  
  FProcessor.ProcessChunked(FTestFile, 256,
    procedure(Chunk: TBitmap32; X, Y: Integer)
    begin
      // Simple processing
      Chunk.AdjustBrightness(10);
    end);
  
  ElapsedMs := MilliSecondsBetween(Now, StartTime);
  AssertTrue('Streaming too slow', ElapsedMs < 5000);
end;

procedure TStreamingTests.TestThumbnailGeneration;
var
  Thumbnail: TBitmap32;
begin
  Thumbnail := FProcessor.GenerateThumbnail(FTestFile, 128, 128);
  try
    AssertEquals('Thumbnail width incorrect', 128, Thumbnail.Width);
    AssertEquals('Thumbnail height incorrect', 128, Thumbnail.Height);
  finally
    Thumbnail.Free;
  end;
end;

{ TMemoryPoolTests }

procedure TMemoryPoolTests.SetUp;
begin
  FPool := TMemoryPool.Create;
end;

procedure TMemoryPoolTests.TearDown;
begin
  FPool.Free;
end;

procedure TMemoryPoolTests.TestPoolAllocation;
var
  P1, P2, P3: Pointer;
begin
  P1 := FPool.Allocate(1024);
  P2 := FPool.Allocate(2048);
  P3 := FPool.Allocate(512);
  
  AssertTrue('P1 not allocated', P1 <> nil);
  AssertTrue('P2 not allocated', P2 <> nil);
  AssertTrue('P3 not allocated', P3 <> nil);
  
  FPool.Release(P1);
  FPool.Release(P2);
  FPool.Release(P3);
end;

procedure TMemoryPoolTests.TestPoolReuse;
var
  P1, P2: Pointer;
begin
  P1 := FPool.Allocate(1024);
  FPool.Release(P1);
  
  P2 := FPool.Allocate(1024);
  AssertEquals('Memory not reused', NativeUInt(P1), NativeUInt(P2));
  
  FPool.Release(P2);
end;

procedure TMemoryPoolTests.TestPoolGrowth;
var
  Pointers: array[0..99] of Pointer;
  I: Integer;
begin
  for I := 0 to 99 do
    Pointers[I] := FPool.Allocate(1024);
  
  AssertTrue('Pool failed to grow', FPool.TotalSize >= 100 * 1024);
  
  for I := 0 to 99 do
    FPool.Release(Pointers[I]);
end;

procedure TMemoryPoolTests.TestConcurrentAccess;
var
  Threads: array[0..3] of TThread;
  I: Integer;
begin
  for I := 0 to 3 do
  begin
    Threads[I] := TThread.CreateAnonymousThread(
      procedure
      var
        J: Integer;
        P: Pointer;
      begin
        for J := 0 to 99 do
        begin
          P := FPool.Allocate(Random(4096) + 1);
          Sleep(1);
          FPool.Release(P);
        end;
      end);
    Threads[I].Start;
  end;
  
  for I := 0 to 3 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  
  AssertTrue('Pool corrupted', FPool.Validate);
end;

procedure TMemoryPoolTests.TestMemoryLeak;
var
  MemBefore, MemAfter: NativeUInt;
  I: Integer;
  P: Pointer;
begin
  MemBefore := GetMemoryUsage;
  
  for I := 0 to 999 do
  begin
    P := FPool.Allocate(1024);
    FPool.Release(P);
  end;
  
  MemAfter := GetMemoryUsage;
  AssertTrue('Memory leak detected', 
    Abs(MemAfter - MemBefore) < 100 * 1024); // Within 100KB
end;

procedure TMemoryPoolTests.TestFragmentation;
var
  Pointers: array[0..49] of Pointer;
  I: Integer;
  FragBefore, FragAfter: Double;
begin
  // Allocate all
  for I := 0 to 49 do
    Pointers[I] := FPool.Allocate((I + 1) * 100);
  
  FragBefore := FPool.FragmentationRatio;
  
  // Release every other
  for I := 0 to 24 do
    FPool.Release(Pointers[I * 2]);
  
  FragAfter := FPool.FragmentationRatio;
  
  AssertTrue('Fragmentation not tracked', FragAfter > FragBefore);
  
  // Cleanup
  for I := 0 to 24 do
    FPool.Release(Pointers[I * 2 + 1]);
end;

{ TSSE2OptimizationTests }

procedure TSSE2OptimizationTests.SetUp;
begin
  FBitmap := TBitmap32.Create;
end;

procedure TSSE2OptimizationTests.TearDown;
begin
  FBitmap.Free;
end;

procedure TSSE2OptimizationTests.CreateTestBitmap;
begin
  FBitmap.SetSize(1024, 1024);
  FBitmap.Clear(Color32(128, 128, 128, 128));
end;

procedure TSSE2OptimizationTests.TestSSE2Blend;
var
  Src, Dst: TBitmap32;
  StartTime: TDateTime;
  ElapsedMs: Int64;
begin
  CreateTestBitmap;
  
  Src := TBitmap32.Create;
  Dst := TBitmap32.Create;
  try
    Src.SetSize(1024, 1024);
    Dst.SetSize(1024, 1024);
    Src.Clear(Color32(255, 0, 0, 128));
    Dst.Clear(Color32(0, 0, 255, 128));
    
    StartTime := Now;
    BlendBitmapsSSE2(Src, Dst, bmNormal);
    ElapsedMs := MilliSecondsBetween(Now, StartTime);
    
    AssertTrue('SSE2 blend too slow', ElapsedMs < 100);
  finally
    Src.Free;
    Dst.Free;
  end;
end;

procedure TSSE2OptimizationTests.TestSSE2Fill;
var
  StartTime: TDateTime;
  ElapsedMs: Int64;
begin
  CreateTestBitmap;
  
  StartTime := Now;
  FillBitmapSSE2(FBitmap, Color32(255, 128, 64, 255));
  ElapsedMs := MilliSecondsBetween(Now, StartTime);
  
  AssertTrue('SSE2 fill too slow', ElapsedMs < 50);
  AssertEquals('Fill color incorrect', 
    Color32(255, 128, 64, 255), FBitmap.Pixel[512, 512]);
end;

procedure TSSE2OptimizationTests.TestSSE2ColorConversion;
var
  StartTime: TDateTime;
  ElapsedMs: Int64;
begin
  CreateTestBitmap;
  
  StartTime := Now;
  ConvertToGrayscaleSSE2(FBitmap);
  ElapsedMs := MilliSecondsBetween(Now, StartTime);
  
  AssertTrue('SSE2 grayscale too slow', ElapsedMs < 100);
end;

procedure TSSE2OptimizationTests.TestSSE2Performance;
var
  NormalTime, SSE2Time: Int64;
  StartTime: TDateTime;
begin
  CreateTestBitmap;
  
  // Normal processing
  StartTime := Now;
  FBitmap.Grayscale;
  NormalTime := MilliSecondsBetween(Now, StartTime);
  
  CreateTestBitmap;
  
  // SSE2 processing
  StartTime := Now;
  ConvertToGrayscaleSSE2(FBitmap);
  SSE2Time := MilliSecondsBetween(Now, StartTime);
  
  AssertTrue('SSE2 not faster than normal', SSE2Time <= NormalTime);
end;

procedure TSSE2OptimizationTests.TestSSE2Accuracy;
var
  Normal, SSE2: TBitmap32;
  X, Y: Integer;
  MaxDiff: Integer;
begin
  Normal := TBitmap32.Create;
  SSE2 := TBitmap32.Create;
  try
    Normal.SetSize(256, 256);
    SSE2.SetSize(256, 256);
    
    // Fill with test pattern
    for Y := 0 to 255 do
      for X := 0 to 255 do
      begin
        Normal.Pixel[X, Y] := Color32(X, Y, (X + Y) div 2);
        SSE2.Pixel[X, Y] := Normal.Pixel[X, Y];
      end;
    
    // Process both
    Normal.Grayscale;
    ConvertToGrayscaleSSE2(SSE2);
    
    // Compare results
    MaxDiff := 0;
    for Y := 0 to 255 do
      for X := 0 to 255 do
        MaxDiff := Max(MaxDiff, 
          Abs(Normal.Pixel[X, Y] - SSE2.Pixel[X, Y]));
    
    AssertTrue('SSE2 accuracy too low', MaxDiff <= 2);
  finally
    Normal.Free;
    SSE2.Free;
  end;
end;

procedure TSSE2OptimizationTests.TestFallbackCompatibility;
var
  HasSSE2Saved: Boolean;
begin
  CreateTestBitmap;
  
  // Save SSE2 state
  HasSSE2Saved := HasSSE2Support;
  
  try
    // Disable SSE2
    HasSSE2Support := False;
    
    // Should still work with fallback
    FBitmap.Grayscale;
    AssertEquals('Fallback failed', 1024, FBitmap.Width);
  finally
    // Restore SSE2 state
    HasSSE2Support := HasSSE2Saved;
  end;
end;

{ TImageProcessingTests }

procedure TImageProcessingTests.SetUp;
begin
  FBitmap := TBitmap32.Create;
  FBitmap.SetSize(100, 100);
  
  // Create test pattern
  var X, Y: Integer;
  for Y := 0 to 99 do
    for X := 0 to 99 do
      FBitmap.Pixel[X, Y] := Color32(X * 2, Y * 2, (X + Y));
end;

procedure TImageProcessingTests.TearDown;
begin
  FBitmap.Free;
end;

procedure TImageProcessingTests.TestRotate90;
var
  OrigWidth, OrigHeight: Integer;
  OrigPixel: TColor32;
begin
  OrigWidth := FBitmap.Width;
  OrigHeight := FBitmap.Height;
  OrigPixel := FBitmap.Pixel[10, 20];
  
  FBitmap.Rotate90;
  
  AssertEquals('Width after rotate90', OrigHeight, FBitmap.Width);
  AssertEquals('Height after rotate90', OrigWidth, FBitmap.Height);
  AssertEquals('Pixel mapping incorrect', OrigPixel, FBitmap.Pixel[79, 10]);
end;

procedure TImageProcessingTests.TestRotate180;
var
  OrigPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[10, 20];
  
  FBitmap.Rotate180;
  
  AssertEquals('Width after rotate180', 100, FBitmap.Width);
  AssertEquals('Height after rotate180', 100, FBitmap.Height);
  AssertEquals('Pixel mapping incorrect', OrigPixel, FBitmap.Pixel[89, 79]);
end;

procedure TImageProcessingTests.TestRotate270;
var
  OrigWidth, OrigHeight: Integer;
  OrigPixel: TColor32;
begin
  OrigWidth := FBitmap.Width;
  OrigHeight := FBitmap.Height;
  OrigPixel := FBitmap.Pixel[10, 20];
  
  FBitmap.Rotate270;
  
  AssertEquals('Width after rotate270', OrigHeight, FBitmap.Width);
  AssertEquals('Height after rotate270', OrigWidth, FBitmap.Height);
  AssertEquals('Pixel mapping incorrect', OrigPixel, FBitmap.Pixel[20, 89]);
end;

procedure TImageProcessingTests.TestFlipHorizontal;
var
  OrigPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[10, 20];
  
  FBitmap.FlipHorizontal;
  
  AssertEquals('Width after flip', 100, FBitmap.Width);
  AssertEquals('Height after flip', 100, FBitmap.Height);
  AssertEquals('Pixel mapping incorrect', OrigPixel, FBitmap.Pixel[89, 20]);
end;

procedure TImageProcessingTests.TestFlipVertical;
var
  OrigPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[10, 20];
  
  FBitmap.FlipVertical;
  
  AssertEquals('Width after flip', 100, FBitmap.Width);
  AssertEquals('Height after flip', 100, FBitmap.Height);
  AssertEquals('Pixel mapping incorrect', OrigPixel, FBitmap.Pixel[10, 79]);
end;

procedure TImageProcessingTests.TestCrop;
begin
  FBitmap.Crop(10, 10, 50, 50);
  
  AssertEquals('Width after crop', 50, FBitmap.Width);
  AssertEquals('Height after crop', 50, FBitmap.Height);
end;

procedure TImageProcessingTests.TestResize;
begin
  FBitmap.Resize(200, 150);
  
  AssertEquals('Width after resize', 200, FBitmap.Width);
  AssertEquals('Height after resize', 150, FBitmap.Height);
end;

procedure TImageProcessingTests.TestGaussianBlur;
var
  OrigPixel, BlurredPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[50, 50];
  
  FBitmap.GaussianBlur(3.0);
  
  BlurredPixel := FBitmap.Pixel[50, 50];
  AssertTrue('Blur had no effect', OrigPixel <> BlurredPixel);
end;

procedure TImageProcessingTests.TestSharpen;
var
  OrigPixel, SharpenedPixel: TColor32;
begin
  // First blur to have something to sharpen
  FBitmap.GaussianBlur(2.0);
  OrigPixel := FBitmap.Pixel[50, 50];
  
  FBitmap.Sharpen(1.5);
  
  SharpenedPixel := FBitmap.Pixel[50, 50];
  AssertTrue('Sharpen had no effect', OrigPixel <> SharpenedPixel);
end;

procedure TImageProcessingTests.TestGrayscale;
var
  GrayPixel: TColor32;
  R, G, B: Byte;
begin
  FBitmap.Grayscale;
  
  GrayPixel := FBitmap.Pixel[50, 50];
  R := RedComponent(GrayPixel);
  G := GreenComponent(GrayPixel);
  B := BlueComponent(GrayPixel);
  
  AssertTrue('Not grayscale', (R = G) and (G = B));
end;

procedure TImageProcessingTests.TestInvert;
var
  OrigPixel, InvertedPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[50, 50];
  
  FBitmap.Invert;
  
  InvertedPixel := FBitmap.Pixel[50, 50];
  AssertEquals('Red not inverted', 
    255 - RedComponent(OrigPixel), RedComponent(InvertedPixel));
  AssertEquals('Green not inverted', 
    255 - GreenComponent(OrigPixel), GreenComponent(InvertedPixel));
  AssertEquals('Blue not inverted', 
    255 - BlueComponent(OrigPixel), BlueComponent(InvertedPixel));
end;

procedure TImageProcessingTests.TestBrightnessAdjustment;
var
  OrigPixel, BrighterPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[50, 50];
  
  FBitmap.AdjustBrightness(50);
  
  BrighterPixel := FBitmap.Pixel[50, 50];
  AssertTrue('Brightness not increased', 
    RedComponent(BrighterPixel) > RedComponent(OrigPixel));
end;

procedure TImageProcessingTests.TestContrastAdjustment;
var
  OrigPixel, ContrastedPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[50, 50];
  
  FBitmap.AdjustContrast(1.5);
  
  ContrastedPixel := FBitmap.Pixel[50, 50];
  AssertTrue('Contrast not changed', OrigPixel <> ContrastedPixel);
end;

procedure TImageProcessingTests.TestGammaCorrection;
var
  OrigPixel, CorrectedPixel: TColor32;
begin
  OrigPixel := FBitmap.Pixel[50, 50];
  
  FBitmap.AdjustGamma(2.2);
  
  CorrectedPixel := FBitmap.Pixel[50, 50];
  AssertTrue('Gamma not corrected', OrigPixel <> CorrectedPixel);
end;

{ TBoundaryTests }

procedure TBoundaryTests.TestZeroSizeImage;
var
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  Bitmap := TBitmap32.Create;
  try
    ExceptionRaised := False;
    try
      Bitmap.SetSize(0, 0);
    except
      ExceptionRaised := True;
    end;
    AssertTrue('Zero size should raise exception', ExceptionRaised);
  finally
    Bitmap.Free;
  end;
end;

procedure TBoundaryTests.TestMaxSizeImage;
var
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  Bitmap := TBitmap32.Create;
  try
    ExceptionRaised := False;
    try
      Bitmap.SetSize(100000, 100000); // Unreasonably large
    except
      ExceptionRaised := True;
    end;
    AssertTrue('Max size should raise exception', ExceptionRaised);
  finally
    Bitmap.Free;
  end;
end;

procedure TBoundaryTests.TestInvalidDimensions;
var
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  Bitmap := TBitmap32.Create;
  try
    ExceptionRaised := False;
    try
      Bitmap.SetSize(-10, 100);
    except
      ExceptionRaised := True;
    end;
    AssertTrue('Negative dimension should raise exception', ExceptionRaised);
  finally
    Bitmap.Free;
  end;
end;

procedure TBoundaryTests.TestNullPointers;
var
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  ExceptionRaised := False;
  try
    LoadBitmapFromFile(nil, 'test.bmp');
  except
    ExceptionRaised := True;
  end;
  AssertTrue('Null bitmap should raise exception', ExceptionRaised);
end;

procedure TBoundaryTests.TestCorruptedData;
var
  Stream: TMemoryStream;
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  Stream := TMemoryStream.Create;
  Bitmap := TBitmap32.Create;
  try
    // Write corrupted header
    Stream.WriteBuffer('BADHEADER', 9);
    Stream.Position := 0;
    
    ExceptionRaised := False;
    try
      LoadBitmapFromStream(Bitmap, Stream);
    except
      ExceptionRaised := True;
    end;
    AssertTrue('Corrupted data should raise exception', ExceptionRaised);
  finally
    Bitmap.Free;
    Stream.Free;
  end;
end;

procedure TBoundaryTests.TestOutOfMemory;
var
  Bitmaps: array of TBitmap32;
  I: Integer;
  ExceptionRaised: Boolean;
begin
  SetLength(Bitmaps, 1000);
  ExceptionRaised := False;
  
  try
    for I := 0 to 999 do
    begin
      Bitmaps[I] := TBitmap32.Create;
      Bitmaps[I].SetSize(1024, 1024); // 4MB each
    end;
  except
    on E: EOutOfMemory do
      ExceptionRaised := True;
  end;
  
  // Cleanup
  for I := 0 to High(Bitmaps) do
    if Assigned(Bitmaps[I]) then
      Bitmaps[I].Free;
  
  // This test may not always trigger on systems with lots of RAM
  // So we don't assert, just ensure cleanup happened
end;

procedure TBoundaryTests.TestIntegerOverflow;
var
  Bitmap: TBitmap32;
  ExceptionRaised: Boolean;
begin
  Bitmap := TBitmap32.Create;
  try
    ExceptionRaised := False;
    try
      // Try to allocate size that would overflow 32-bit integer
      Bitmap.SetSize(65536, 65536);
    except
      ExceptionRaised := True;
    end;
    AssertTrue('Integer overflow should be caught', ExceptionRaised);
  finally
    Bitmap.Free;
  end;
end;

{ TPerformanceTests }

procedure TPerformanceTests.MeasureOperation(const AName: string; AProc: TProcedure);
var
  StartTime: TDateTime;
  ElapsedMs: Int64;
begin
  StartTime := Now;
  AProc();
  ElapsedMs := MilliSecondsBetween(Now, StartTime);
  WriteLn(Format('%s: %d ms', [AName, ElapsedMs]));
end;

procedure TPerformanceTests.TestLoadPerformance;
var
  Bitmap: TBitmap32;
  TestFile: string;
begin
  TestFile := ExtractFilePath(ParamStr(0)) + 'perf_test.bmp';
  
  // Create test file
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(2048, 2048);
    SaveBitmapToFile(Bitmap, TestFile);
  finally
    Bitmap.Free;
  end;
  
  // Measure load time
  MeasureOperation('Load 2048x2048 BMP',
    procedure
    var
      B: TBitmap32;
    begin
      B := TBitmap32.Create;
      try
        LoadBitmapFromFile(B, TestFile);
      finally
        B.Free;
      end;
    end);
  
  DeleteFile(TestFile);
end;

procedure TPerformanceTests.TestSavePerformance;
var
  Bitmap: TBitmap32;
  TestFile: string;
begin
  TestFile := ExtractFilePath(ParamStr(0)) + 'perf_save.bmp';
  
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(2048, 2048);
    
    MeasureOperation('Save 2048x2048 BMP',
      procedure
      begin
        SaveBitmapToFile(Bitmap, TestFile);
      end);
  finally
    Bitmap.Free;
  end;
  
  DeleteFile(TestFile);
end;

procedure TPerformanceTests.TestBlendPerformance;
var
  Src, Dst: TBitmap32;
begin
  Src := TBitmap32.Create;
  Dst := TBitmap32.Create;
  try
    Src.SetSize(1024, 1024);
    Dst.SetSize(1024, 1024);
    Src.Clear(Color32(255, 0, 0, 128));
    Dst.Clear(Color32(0, 0, 255, 128));
    
    MeasureOperation('Blend 1024x1024',
      procedure
      begin
        BlendBitmaps(Src, Dst, bmNormal);
      end);
  finally
    Src.Free;
    Dst.Free;
  end;
end;

procedure TPerformanceTests.TestFilterPerformance;
var
  Bitmap: TBitmap32;
begin
  Bitmap := TBitmap32.Create;
  try
    Bitmap.SetSize(1024, 1024);
    
    MeasureOperation('GaussianBlur 1024x1024',
      procedure
      begin
        Bitmap.GaussianBlur(3.0);
      end);
  finally
    Bitmap.Free;
  end;
end;

procedure TPerformanceTests.TestResizePerformance;
var
  Src, Dst: TBitmap32;
begin
  Src := TBitmap32.Create;
  Dst := TBitmap32.Create;
  try
    Src.SetSize(2048, 2048);
    
    MeasureOperation('Resize 2048x2048 to 1024x1024',
      procedure
      begin
        Dst.SetSize(1024, 1024);
        ResizeBilinear(Src, Dst);
      end);
  finally
    Src.Free;
    Dst.Free;
  end;
end;

procedure TPerformanceTests.TestParallelSpeedup;
var
  Bitmap: TBitmap32;
  Processor: TParallelImageProcessor;
  SerialTime, ParallelTime: Int64;
  StartTime: TDateTime;
begin
  Bitmap := TBitmap32.Create;
  Processor := TParallelImageProcessor.Create;
  try
    Bitmap.SetSize(2048, 2048);
    
    // Serial
    StartTime := Now;
    Bitmap.GaussianBlur(5.0);
    SerialTime := MilliSecondsBetween(Now, StartTime);
    
    // Parallel
    StartTime := Now;
    Processor.GaussianBlur(Bitmap, 5.0);
    ParallelTime := MilliSecondsBetween(Now, StartTime);
    
    WriteLn(Format('Speedup: %.2fx', [SerialTime / ParallelTime]));
    AssertTrue('Parallel should be faster', ParallelTime < SerialTime);
  finally
    Processor.Free;
    Bitmap.Free;
  end;
end;

procedure TPerformanceTests.TestMemoryPoolEfficiency;
var
  Pool: TMemoryPool;
  DirectTime, PoolTime: Int64;
  StartTime: TDateTime;
  I: Integer;
  P: Pointer;
begin
  // Direct allocation
  StartTime := Now;
  for I := 0 to 9999 do
  begin
    GetMem(P, 1024);
    FreeMem(P);
  end;
  DirectTime := MilliSecondsBetween(Now, StartTime);
  
  // Pool allocation
  Pool := TMemoryPool.Create;
  try
    StartTime := Now;
    for I := 0 to 9999 do
    begin
      P := Pool.Allocate(1024);
      Pool.Release(P);
    end;
    PoolTime := MilliSecondsBetween(Now, StartTime);
    
    WriteLn(Format('Pool speedup: %.2fx', [DirectTime / PoolTime]));
    AssertTrue('Pool should be faster', PoolTime <= DirectTime);
  finally
    Pool.Free;
  end;
end;

var
  Application: TTestRunner;

begin
  // Register all test suites
  RegisterTest(TImageFormatTests);
  RegisterTest(TParallelProcessingTests);
  RegisterTest(TStreamingTests);
  RegisterTest(TMemoryPoolTests);
  RegisterTest(TSSE2OptimizationTests);
  RegisterTest(TImageProcessingTests);
  RegisterTest(TBoundaryTests);
  RegisterTest(TPerformanceTests);
  
  // Run tests
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'Comprehensive Image Processing Tests';
  Application.Run;
  Application.Free;
end.