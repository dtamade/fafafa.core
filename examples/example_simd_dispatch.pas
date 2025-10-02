program example_simd_dispatch;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
  {$CODEPAGE UTF8}
{$ENDIF}

uses
  SysUtils, DateUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

type
  // Function pointer for vector addition
  TVectorAddFunc = procedure(const a, b: PSingle; result: PSingle; count: Integer);

// === Scalar Implementation ===
procedure VectorAdd_Scalar(const a, b: PSingle; result: PSingle; count: Integer);
var
  i: Integer;
begin
  for i := 0 to count - 1 do
    result[i] := a[i] + b[i];
end;

// === SSE2 Implementation ===
procedure VectorAdd_SSE2(const a, b: PSingle; result: PSingle; count: Integer);
var
  i: Integer;
begin
  // Simulate SSE2 optimized version (in real code, use assembly or intrinsics)
  // Process 4 floats at a time
  i := 0;
  while i <= count - 4 do
  begin
    result[i] := a[i] + b[i];
    result[i+1] := a[i+1] + b[i+1];
    result[i+2] := a[i+2] + b[i+2];
    result[i+3] := a[i+3] + b[i+3];
    Inc(i, 4);
  end;
  
  // Handle remaining elements
  while i < count do
  begin
    result[i] := a[i] + b[i];
    Inc(i);
  end;
end;

// === AVX2 Implementation ===
procedure VectorAdd_AVX2(const a, b: PSingle; result: PSingle; count: Integer);
var
  i: Integer;
begin
  // Simulate AVX2 optimized version
  // Process 8 floats at a time
  i := 0;
  while i <= count - 8 do
  begin
    result[i] := a[i] + b[i];
    result[i+1] := a[i+1] + b[i+1];
    result[i+2] := a[i+2] + b[i+2];
    result[i+3] := a[i+3] + b[i+3];
    result[i+4] := a[i+4] + b[i+4];
    result[i+5] := a[i+5] + b[i+5];
    result[i+6] := a[i+6] + b[i+6];
    result[i+7] := a[i+7] + b[i+7];
    Inc(i, 8);
  end;
  
  // Handle remaining elements
  while i < count do
  begin
    result[i] := a[i] + b[i];
    Inc(i);
  end;
end;

// === Dynamic Dispatch Based on CPU Features ===
function SelectVectorAddImplementation: TVectorAddFunc;
var
  bestBackend: TSimdBackend;
  cpuInfo: TCPUInfo;
begin
  bestBackend := GetBestBackend;
  cpuInfo := GetCPUInfo;
  
  WriteLn('CPU Detection Results:');
  WriteLn('  Vendor: ', cpuInfo.Vendor);
  WriteLn('  Model: ', cpuInfo.Model);
  WriteLn('  Best SIMD Backend: ', GetBackendInfo(bestBackend).Name);
  WriteLn;
  
  case bestBackend of
    sbAVX2:
      begin
        WriteLn('  → Using AVX2 optimized implementation');
        Result := @VectorAdd_AVX2;
      end;
    sbSSE2:
      begin
        WriteLn('  → Using SSE2 optimized implementation');
        Result := @VectorAdd_SSE2;
      end;
    else
      begin
        WriteLn('  → Using scalar fallback implementation');
        Result := @VectorAdd_Scalar;
      end;
  end;
end;

// === Benchmark Function ===
procedure BenchmarkVectorAdd(impl: TVectorAddFunc; const name: string; 
                            const a, b: PSingle; result: PSingle; count: Integer);
const
  ITERATIONS = 1000;
var
  i: Integer;
  startTime, endTime: TDateTime;
  elapsed: Double;
  throughput: Double;
begin
  Write(Format('  %-20s: ', [name]));
  
  startTime := Now;
  for i := 1 to ITERATIONS do
    impl(a, b, result, count);
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  throughput := (count * ITERATIONS * SizeOf(Single) * 3) / (elapsed / 1000) / (1024 * 1024); // MB/s
  
  WriteLn(Format('%8.2f ms | %8.2f MB/s', [elapsed, throughput]));
end;

// === Image Processing Example ===
procedure ExampleImageProcessing;
type
  TPixel = packed record
    R, G, B, A: Byte;
  end;
  PPixel = ^TPixel;
  
var
  width, height: Integer;
  pixelCount: Integer;
  image1, image2, result: array of TPixel;
  i: Integer;
  startTime, endTime: TDateTime;
  backend: TSimdBackend;
begin
  WriteLn('=== Image Processing Example ===');
  WriteLn('Scenario: Alpha blending two 1920x1080 images');
  WriteLn;
  
  width := 1920;
  height := 1080;
  pixelCount := width * height;
  
  // Allocate memory for images
  SetLength(image1, pixelCount);
  SetLength(image2, pixelCount);
  SetLength(result, pixelCount);
  
  // Initialize with random data
  Randomize;
  for i := 0 to pixelCount - 1 do
  begin
    image1[i].R := Random(256);
    image1[i].G := Random(256);
    image1[i].B := Random(256);
    image1[i].A := Random(256);
    
    image2[i].R := Random(256);
    image2[i].G := Random(256);
    image2[i].B := Random(256);
    image2[i].A := Random(256);
  end;
  
  backend := GetBestBackend;
  Write('Processing with ', GetBackendInfo(backend).Name, ' backend... ');
  
  startTime := Now;
  
  // Simulate alpha blending based on available SIMD
  case backend of
    sbAVX2, sbSSE2:
      begin
        // SIMD-optimized path (simplified)
        for i := 0 to pixelCount - 1 do
        begin
          result[i].R := (image1[i].R * image1[i].A + image2[i].R * (255 - image1[i].A)) div 255;
          result[i].G := (image1[i].G * image1[i].A + image2[i].G * (255 - image1[i].A)) div 255;
          result[i].B := (image1[i].B * image1[i].A + image2[i].B * (255 - image1[i].A)) div 255;
          result[i].A := 255;
        end;
      end;
    else
      begin
        // Scalar fallback
        for i := 0 to pixelCount - 1 do
        begin
          result[i].R := (image1[i].R + image2[i].R) div 2;
          result[i].G := (image1[i].G + image2[i].G) div 2;
          result[i].B := (image1[i].B + image2[i].B) div 2;
          result[i].A := 255;
        end;
      end;
  end;
  
  endTime := Now;
  WriteLn(Format('Done in %.2f ms', [MilliSecondsBetween(endTime, startTime) * 1.0]));
  WriteLn(Format('  Processed %d pixels (%.2f megapixels)', 
                 [pixelCount, pixelCount / 1000000.0]));
  WriteLn;
end;

// === Matrix Multiplication Example ===
procedure ExampleMatrixMultiplication;
const
  MATRIX_SIZE = 128;
type
  TMatrix = array[0..MATRIX_SIZE-1, 0..MATRIX_SIZE-1] of Single;
var
  matrixA, matrixB, matrixC: TMatrix;
  i, j, k: Integer;
  startTime, endTime: TDateTime;
  cpuInfo: TCPUInfo;
  useFMA: Boolean;
  ops: Int64;
  gflops: Double;
begin
  WriteLn('=== Matrix Multiplication Example ===');
  WriteLn(Format('Multiplying two %dx%d matrices', [MATRIX_SIZE, MATRIX_SIZE]));
  WriteLn;
  
  cpuInfo := GetCPUInfo;
  useFMA := HasFeature(gfFMA);
  
  if useFMA then
    WriteLn('  ✓ FMA instructions available - using optimized path')
  else
    WriteLn('  ○ FMA not available - using standard multiplication');
  
  // Initialize matrices with random values
  Randomize;
  for i := 0 to MATRIX_SIZE - 1 do
    for j := 0 to MATRIX_SIZE - 1 do
    begin
      matrixA[i, j] := Random * 10;
      matrixB[i, j] := Random * 10;
      matrixC[i, j] := 0;
    end;
  
  Write('  Computing C = A × B... ');
  startTime := Now;
  
  // Matrix multiplication
  if useFMA then
  begin
    // Simulated FMA-optimized version
    for i := 0 to MATRIX_SIZE - 1 do
      for j := 0 to MATRIX_SIZE - 1 do
        for k := 0 to MATRIX_SIZE - 1 do
          matrixC[i, j] := matrixC[i, j] + matrixA[i, k] * matrixB[k, j];
  end
  else
  begin
    // Standard version
    for i := 0 to MATRIX_SIZE - 1 do
      for j := 0 to MATRIX_SIZE - 1 do
        for k := 0 to MATRIX_SIZE - 1 do
          matrixC[i, j] := matrixC[i, j] + matrixA[i, k] * matrixB[k, j];
  end;
  
  endTime := Now;
  
  // Calculate performance metrics
  ops := 2 * Int64(MATRIX_SIZE) * MATRIX_SIZE * MATRIX_SIZE; // multiply-add operations
  gflops := ops / (MilliSecondsBetween(endTime, startTime) / 1000.0) / 1e9;
  
  WriteLn(Format('Done in %.2f ms', [MilliSecondsBetween(endTime, startTime) * 1.0]));
  WriteLn(Format('  Performance: %.2f GFLOPS', [gflops]));
  WriteLn;
end;

// === Main Program ===
const
  VECTOR_SIZE = 1024 * 1024;  // 1M elements
var
  a, b, c: array of Single;
  vectorAddFunc: TVectorAddFunc;
  i: Integer;
  cpuInfo: TCPUInfo;
  backends: TSimdBackendArray;
  backendInfo: TSimdBackendInfo;
begin
  WriteLn('================================================');
  WriteLn('     SIMD CPU Info - Real-World Examples');
  WriteLn('     ', FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
  WriteLn('================================================');
  WriteLn;
  
  // Display system information
  cpuInfo := GetCPUInfo;
  WriteLn('System Information:');
  WriteLn('  CPU: ', cpuInfo.Model);
  WriteLn('  Logical Cores: ', cpuInfo.LogicalCores);
  WriteLn('  Cache: L1=', cpuInfo.Cache.L1DataKB, 'KB, L2=', 
          cpuInfo.Cache.L2KB, 'KB, L3=', cpuInfo.Cache.L3KB, 'KB');
  WriteLn;
  
  // Display available SIMD backends
  WriteLn('Available SIMD Backends:');
  backends := GetAvailableBackends;
  for i := 0 to Length(backends) - 1 do
  begin
    backendInfo := GetBackendInfo(backends[i]);
    WriteLn(Format('  [%d] %-15s - %s', 
                   [i+1, backendInfo.Name, backendInfo.Description]));
  end;
  WriteLn;
  
  // Example 1: Dynamic dispatch for vector operations
  WriteLn('=== Example 1: Dynamic Vector Operations ===');
  WriteLn('Adding two vectors with ', VECTOR_SIZE, ' elements');
  WriteLn;
  
  // Allocate and initialize vectors
  SetLength(a, VECTOR_SIZE);
  SetLength(b, VECTOR_SIZE);
  SetLength(c, VECTOR_SIZE);
  
  for i := 0 to VECTOR_SIZE - 1 do
  begin
    a[i] := Random * 100;
    b[i] := Random * 100;
  end;
  
  // Select best implementation
  vectorAddFunc := SelectVectorAddImplementation;
  WriteLn;
  
  // Benchmark different implementations
  WriteLn('Benchmarking implementations:');
  BenchmarkVectorAdd(@VectorAdd_Scalar, 'Scalar', @a[0], @b[0], @c[0], VECTOR_SIZE);
  BenchmarkVectorAdd(@VectorAdd_SSE2, 'SSE2', @a[0], @b[0], @c[0], VECTOR_SIZE);
  BenchmarkVectorAdd(@VectorAdd_AVX2, 'AVX2', @a[0], @b[0], @c[0], VECTOR_SIZE);
  WriteLn;
  
  // Example 2: Image processing
  ExampleImageProcessing;
  
  // Example 3: Matrix multiplication
  ExampleMatrixMultiplication;
  
  WriteLn('================================================');
  WriteLn('All examples completed successfully!');
  WriteLn('================================================');
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.