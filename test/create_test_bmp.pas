program CreateTestBMP;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes;

type
  TBitmapFileHeader = packed record
    bfType: Word;      // Must be $4D42 ('BM')
    bfSize: Cardinal;  // File size
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: Cardinal; // Offset to pixel data
  end;

  TBitmapInfoHeader = packed record
    biSize: Cardinal;
    biWidth: Integer;
    biHeight: Integer;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: Cardinal;
    biSizeImage: Cardinal;
    biXPelsPerMeter: Integer;
    biYPelsPerMeter: Integer;
    biClrUsed: Cardinal;
    biClrImportant: Cardinal;
  end;

procedure CreateSimpleBMP(const FileName: string; Width, Height: Integer);
var
  FS: TFileStream;
  FileHeader: TBitmapFileHeader;
  InfoHeader: TBitmapInfoHeader;
  RowSize, Padding: Integer;
  PixelData: array of Byte;
  y, x: Integer;
  Color: Byte;
begin
  // Calculate row size with padding
  RowSize := Width * 3;
  Padding := (4 - (RowSize mod 4)) mod 4;
  RowSize := RowSize + Padding;
  
  // Prepare headers
  FillChar(FileHeader, SizeOf(FileHeader), 0);
  FileHeader.bfType := $4D42; // 'BM'
  FileHeader.bfSize := SizeOf(FileHeader) + SizeOf(InfoHeader) + RowSize * Height;
  FileHeader.bfOffBits := SizeOf(FileHeader) + SizeOf(InfoHeader);
  
  FillChar(InfoHeader, SizeOf(InfoHeader), 0);
  InfoHeader.biSize := SizeOf(InfoHeader);
  InfoHeader.biWidth := Width;
  InfoHeader.biHeight := Height;
  InfoHeader.biPlanes := 1;
  InfoHeader.biBitCount := 24;
  InfoHeader.biCompression := 0; // BI_RGB
  InfoHeader.biSizeImage := RowSize * Height;
  
  // Create file
  FS := TFileStream.Create(FileName, fmCreate);
  try
    // Write headers
    FS.Write(FileHeader, SizeOf(FileHeader));
    FS.Write(InfoHeader, SizeOf(InfoHeader));
    
    // Create pixel data (gradient pattern)
    SetLength(PixelData, RowSize);
    
    for y := 0 to Height - 1 do
    begin
      // Create gradient row
      for x := 0 to Width - 1 do
      begin
        Color := Byte((x * 255) div Width);
        PixelData[x * 3] := Color;     // Blue
        PixelData[x * 3 + 1] := Color; // Green
        PixelData[x * 3 + 2] := 255 - Color; // Red
      end;
      
      // Clear padding bytes
      for x := Width * 3 to RowSize - 1 do
        PixelData[x] := 0;
        
      // Write row
      FS.Write(PixelData[0], RowSize);
    end;
    
  finally
    FS.Free;
  end;
  
  WriteLn('Created BMP file: ', FileName);
  WriteLn('  Size: ', Width, 'x', Height);
  WriteLn('  File size: ', FileHeader.bfSize, ' bytes');
end;

procedure CreateCorruptedBMP(const FileName: string);
var
  FS: TFileStream;
  FileHeader: TBitmapFileHeader;
  InfoHeader: TBitmapInfoHeader;
begin
  // Create file with incorrect file size
  FillChar(FileHeader, SizeOf(FileHeader), 0);
  FileHeader.bfType := $4D42; // 'BM'
  FileHeader.bfSize := 100; // Wrong size!
  FileHeader.bfOffBits := SizeOf(FileHeader) + SizeOf(InfoHeader);
  
  FillChar(InfoHeader, SizeOf(InfoHeader), 0);
  InfoHeader.biSize := SizeOf(InfoHeader);
  InfoHeader.biWidth := 100;
  InfoHeader.biHeight := 100;
  InfoHeader.biPlanes := 1;
  InfoHeader.biBitCount := 24;
  
  FS := TFileStream.Create(FileName, fmCreate);
  try
    FS.Write(FileHeader, SizeOf(FileHeader));
    FS.Write(InfoHeader, SizeOf(InfoHeader));
    // Don't write any pixel data - file is truncated
  finally
    FS.Free;
  end;
  
  WriteLn('Created corrupted BMP file: ', FileName);
end;

begin
  WriteLn('Creating test BMP files...');
  WriteLn;
  
  // Create valid BMP
  CreateSimpleBMP('test_valid.bmp', 100, 100);
  WriteLn;
  
  // Create corrupted BMP
  CreateCorruptedBMP('test_corrupted.bmp');
  WriteLn;
  
  WriteLn('Done! You can now test these files with imgvalidate.exe');
end.