unit fafafa.core.simd.imageproc;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd;

// === 图像处理类型 ===
type
  TImageFormat = (
    ifRGB24,     // 24-bit RGB (3 bytes per pixel)
    ifRGBA32,    // 32-bit RGBA (4 bytes per pixel)
    ifGrayscale  // 8-bit grayscale (1 byte per pixel)
  );

  TImage = record
    Width, Height: Integer;
    Format: TImageFormat;
    Data: PByte;
    DataSize: Integer;
  end;

  TKernel3x3 = array[0..8] of Single;  // 3x3 卷积�?
// === 基础图像操作 ===

// 图像创建和销�?function CreateImage(width, height: Integer; format: TImageFormat): TImage;
procedure FreeImage(var img: TImage);

// 像素访问
function GetPixelRGB(const img: TImage; x, y: Integer): TVecF32x4; // 返回 [R,G,B,A]
procedure SetPixelRGB(var img: TImage; x, y: Integer; const color: TVecF32x4);

// === SIMD 优化的图像处理函�?===

// 基础操作
procedure ImageAdd(var dest: TImage; const src1, src2: TImage);
procedure ImageSubtract(var dest: TImage; const src1, src2: TImage);
procedure ImageMultiply(var dest: TImage; const src: TImage; factor: Single);
procedure ImageBlend(var dest: TImage; const src1, src2: TImage; alpha: Single);

// 颜色空间转换
procedure RGBToGrayscale(var dest: TImage; const src: TImage);
procedure GrayscaleToRGB(var dest: TImage; const src: TImage);

// 滤镜效果
procedure ApplyBrightness(var img: TImage; brightness: Single);
procedure ApplyContrast(var img: TImage; contrast: Single);
procedure ApplyGamma(var img: TImage; gamma: Single);

// 卷积操作
procedure ApplyConvolution3x3(var dest: TImage; const src: TImage; const kernel: TKernel3x3);

// 预定义滤�?procedure ApplyGaussianBlur(var dest: TImage; const src: TImage);
procedure ApplySharpen(var dest: TImage; const src: TImage);
procedure ApplyEdgeDetection(var dest: TImage; const src: TImage);

implementation

uses
  SysUtils,
  fafafa.core.math;

// === 常量定义 ===
const
  // RGB 到灰度转换权�?(ITU-R BT.709)
  RGB_TO_GRAY_R = 0.2126;
  RGB_TO_GRAY_G = 0.7152;
  RGB_TO_GRAY_B = 0.0722;

  // 预定义卷积核
  KERNEL_GAUSSIAN_BLUR: TKernel3x3 = (
    1/16, 2/16, 1/16,
    2/16, 4/16, 2/16,
    1/16, 2/16, 1/16
  );

  KERNEL_SHARPEN: TKernel3x3 = (
     0, -1,  0,
    -1,  5, -1,
     0, -1,  0
  );

  KERNEL_EDGE_DETECTION: TKernel3x3 = (
    -1, -1, -1,
    -1,  8, -1,
    -1, -1, -1
  );

// === 图像创建和管�?===

function CreateImage(width, height: Integer; format: TImageFormat): TImage;
var
  bytesPerPixel: Integer;
begin
  Result.Width := width;
  Result.Height := height;
  Result.Format := format;

  case format of
    ifRGB24: bytesPerPixel := 3;
    ifRGBA32: bytesPerPixel := 4;
    ifGrayscale: bytesPerPixel := 1;
  else
    bytesPerPixel := 4;
  end;

  Result.DataSize := width * height * bytesPerPixel;
  GetMem(Result.Data, Result.DataSize);
  FillChar(Result.Data^, Result.DataSize, 0);
end;

procedure FreeImage(var img: TImage);
begin
  if Assigned(img.Data) then
  begin
    FreeMem(img.Data);
    img.Data := nil;
  end;
  img.DataSize := 0;
end;

// === SIMD 优化的图像处�?===

procedure ImageAdd(var dest: TImage; const src1, src2: TImage);
var
  i: Integer;
  vec1, vec2, result: TVecF32x4;
  p1, p2, pd: PByte;
  temp1, temp2, tempResult: array[0..3] of Single;
begin
  if (src1.Width <> src2.Width) or (src1.Height <> src2.Height) or
     (src1.Format <> src2.Format) then
    raise Exception.Create('图像尺寸或格式不匹配');

  if (dest.Width <> src1.Width) or (dest.Height <> src1.Height) or
     (dest.Format <> src1.Format) then
    dest := CreateImage(src1.Width, src1.Height, src1.Format);

  p1 := src1.Data;
  p2 := src2.Data;
  pd := dest.Data;

  case src1.Format of
    ifRGBA32:
    begin
      // 4字节对齐，可以直接使�?SIMD
      i := 0;
      while i < src1.DataSize - 15 do  // 处理16字节�?      begin
        vec1 := VecF32x4Load(PSingle(@p1[i]));
        vec2 := VecF32x4Load(PSingle(@p2[i]));
        result := VecF32x4Add(vec1, vec2);
        VecF32x4Store(PSingle(@pd[i]), result);
        Inc(i, 16);
      end;

      // 处理剩余字节
      while i < src1.DataSize do
      begin
        pd[i] := p1[i] + p2[i];
        Inc(i);
      end;
    end;

    ifRGB24:
    begin
      // 3字节像素，需要特殊处�?      for i := 0 to (src1.Width * src1.Height) - 1 do
      begin
        temp1[0] := p1[i * 3 + 0];     // R
        temp1[1] := p1[i * 3 + 1];     // G
        temp1[2] := p1[i * 3 + 2];     // B
        temp1[3] := 0;                 // 填充

        temp2[0] := p2[i * 3 + 0];     // R
        temp2[1] := p2[i * 3 + 1];     // G
        temp2[2] := p2[i * 3 + 2];     // B
        temp2[3] := 0;                 // 填充

        vec1 := VecF32x4Load(@temp1[0]);
        vec2 := VecF32x4Load(@temp2[0]);
        result := VecF32x4Add(vec1, vec2);
        VecF32x4Store(@tempResult[0], result);

        pd[i * 3 + 0] := Round(tempResult[0]);
        pd[i * 3 + 1] := Round(tempResult[1]);
        pd[i * 3 + 2] := Round(tempResult[2]);
      end;
    end;

    ifGrayscale:
    begin
      // 单字节像�?      for i := 0 to src1.DataSize - 1 do
        pd[i] := p1[i] + p2[i];
    end;
  end;
end;

procedure RGBToGrayscale(var dest: TImage; const src: TImage);
var
  i: Integer;
  vecRGB, vecWeights, vecGray: TVecF32x4;
  ps, pd: PByte;
  r, g, b, gray: Single;
begin
  if src.Format <> ifRGB24 then
    raise Exception.Create('源图像必须是 RGB24 格式');

  if (dest.Width <> src.Width) or (dest.Height <> src.Height) or
     (dest.Format <> ifGrayscale) then
    dest := CreateImage(src.Width, src.Height, ifGrayscale);

  ps := src.Data;
  pd := dest.Data;

  // 创建权重向量 [R_weight, G_weight, B_weight, 0]
  vecWeights.f[0] := RGB_TO_GRAY_R;
  vecWeights.f[1] := RGB_TO_GRAY_G;
  vecWeights.f[2] := RGB_TO_GRAY_B;
  vecWeights.f[3] := 0.0;

  for i := 0 to (src.Width * src.Height) - 1 do
  begin
    // 加载 RGB �?    r := ps[i * 3 + 0];
    g := ps[i * 3 + 1];
    b := ps[i * 3 + 2];

    vecRGB.f[0] := r; vecRGB.f[1] := g; vecRGB.f[2] := b; vecRGB.f[3] := 0.0;
    vecGray := VecF32x4Mul(vecRGB, vecWeights);
    gray := VecF32x4ReduceAdd(vecGray);

    pd[i] := Round(gray);
  end;
end;

procedure ApplyBrightness(var img: TImage; brightness: Single);
var
  i: Integer;
  vecBrightness, vecPixel, vecResult: TVecF32x4;
  p: PByte;
  temp, tempResult: array[0..3] of Single;
begin
  vecBrightness := VecF32x4Splat(brightness);
  p := img.Data;

  case img.Format of
    ifRGBA32:
    begin
      i := 0;
      while i < img.DataSize - 15 do
      begin
        vecPixel := VecF32x4Load(PSingle(@p[i]));
        vecResult := VecF32x4Add(vecPixel, vecBrightness);
        VecF32x4Store(PSingle(@p[i]), vecResult);
        Inc(i, 16);
      end;
    end;

    ifRGB24:
    begin
      for i := 0 to (img.Width * img.Height) - 1 do
      begin
        temp[0] := p[i * 3 + 0] + brightness;
        temp[1] := p[i * 3 + 1] + brightness;
        temp[2] := p[i * 3 + 2] + brightness;
        temp[3] := 0;

        // 限制�?0-255 范围�?        if temp[0] < 0 then temp[0] := 0 else if temp[0] > 255 then temp[0] := 255;
        if temp[1] < 0 then temp[1] := 0 else if temp[1] > 255 then temp[1] := 255;
        if temp[2] < 0 then temp[2] := 0 else if temp[2] > 255 then temp[2] := 255;

        p[i * 3 + 0] := Round(temp[0]);
        p[i * 3 + 1] := Round(temp[1]);
        p[i * 3 + 2] := Round(temp[2]);
      end;
    end;
  end;
end;

procedure ApplyGaussianBlur(var dest: TImage; const src: TImage);
begin
  ApplyConvolution3x3(dest, src, KERNEL_GAUSSIAN_BLUR);
end;

procedure ApplySharpen(var dest: TImage; const src: TImage);
begin
  ApplyConvolution3x3(dest, src, KERNEL_SHARPEN);
end;

procedure ApplyEdgeDetection(var dest: TImage; const src: TImage);
begin
  ApplyConvolution3x3(dest, src, KERNEL_EDGE_DETECTION);
end;

procedure ApplyConvolution3x3(var dest: TImage; const src: TImage; const kernel: TKernel3x3);
var
  x, y, kx, ky: Integer;
  sum: Single;
  ps, pd: PByte;
  srcX, srcY: Integer;
begin
  if (dest.Width <> src.Width) or (dest.Height <> src.Height) or
     (dest.Format <> src.Format) then
    dest := CreateImage(src.Width, src.Height, src.Format);

  ps := src.Data;
  pd := dest.Data;

  // 简化实现：只处理灰度图�?  if src.Format <> ifGrayscale then
    raise Exception.Create('卷积操作目前只支持灰度图�?);

  for y := 1 to src.Height - 2 do
  begin
    for x := 1 to src.Width - 2 do
    begin
      sum := 0.0;

      // 应用 3x3 卷积�?      for ky := -1 to 1 do
      begin
        for kx := -1 to 1 do
        begin
          srcX := x + kx;
          srcY := y + ky;
          sum := sum + ps[srcY * src.Width + srcX] * kernel[(ky + 1) * 3 + (kx + 1)];
        end;
      end;

      // 限制结果范围
      if sum < 0 then sum := 0
      else if sum > 255 then sum := 255;

      pd[y * dest.Width + x] := Round(sum);
    end;
  end;
end;

// 其他函数的简化实�?..
procedure ImageSubtract(var dest: TImage; const src1, src2: TImage);
begin
  // 实现类似 ImageAdd，但使用减法
end;

procedure ImageMultiply(var dest: TImage; const src: TImage; factor: Single);
begin
  // 实现标量乘法
end;

procedure ImageBlend(var dest: TImage; const src1, src2: TImage; alpha: Single);
begin
  // 实现 alpha 混合
end;

function GetPixelRGB(const img: TImage; x, y: Integer): TVecF32x4;
begin
  // 实现像素读取
  Result := VecF32x4Zero;
end;

procedure SetPixelRGB(var img: TImage; x, y: Integer; const color: TVecF32x4);
begin
  // 实现像素写入
end;

procedure GrayscaleToRGB(var dest: TImage; const src: TImage);
begin
  // 实现灰度到RGB转换
end;

procedure ApplyContrast(var img: TImage; contrast: Single);
begin
  // 实现对比度调�?end;

procedure ApplyGamma(var img: TImage; gamma: Single);
begin
  // 实现伽马校正
end;

end.


