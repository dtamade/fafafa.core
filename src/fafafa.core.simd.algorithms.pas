{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

unit fafafa.core.simd.algorithms;

interface

uses
  fafafa.core.simd.base;

type
  TSimdWidth = (
    swScalar,
    sw128,
    sw256,
    sw512
  );

  TSimdLaneInfo = record
    Width: TSimdWidth;
    F32Lanes: Integer;
    F64Lanes: Integer;
    Alignment: Integer;
  end;

function SimdGetBestLaneInfo: TSimdLaneInfo;

procedure SimdArrayAdd(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
procedure SimdArrayMul(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
procedure SimdArrayMulScalar(aSrc, aDst: PSingle; aCount: SizeUInt; aScalar: Single);
procedure SimdArrayAxpy(aAlpha: Single; aX, aY, aDst: PSingle; aCount: SizeUInt);

function SimdReduceSum(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdReduceDot(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
function SimdReduceMin(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdReduceMax(aSrc: PSingle; aCount: SizeUInt): Single;

implementation

uses
  fafafa.core.simd.dispatch,
  fafafa.core.simd.direct;

type
  TF32Caps = record
    Has512: Boolean;
    Has256: Boolean;
    Has128: Boolean;
    D: PSimdDispatchTable;
  end;

function ProbeF32Caps: TF32Caps; inline;
var
  LD: PSimdDispatchTable;
begin
  LD := GetDirectDispatchTable;
  Result.D := LD;
  Result.Has128 := (LD <> nil) and Assigned(LD^.AddF32x4);
  Result.Has256 := (LD <> nil) and Assigned(LD^.AddF32x8);
  Result.Has512 := (LD <> nil) and Assigned(LD^.AddF32x16);
end;

function SimdGetBestLaneInfo: TSimdLaneInfo;
var
  LCaps: TF32Caps;
begin
  LCaps := ProbeF32Caps;
  if LCaps.Has512 then
  begin
    Result.Width := sw512;
    Result.F32Lanes := 16;
    Result.F64Lanes := 8;
    Result.Alignment := 64;
  end
  else if LCaps.Has256 then
  begin
    Result.Width := sw256;
    Result.F32Lanes := 8;
    Result.F64Lanes := 4;
    Result.Alignment := 32;
  end
  else if LCaps.Has128 then
  begin
    Result.Width := sw128;
    Result.F32Lanes := 4;
    Result.F64Lanes := 2;
    Result.Alignment := 16;
  end
  else
  begin
    Result.Width := swScalar;
    Result.F32Lanes := 1;
    Result.F64Lanes := 1;
    Result.Alignment := 4;
  end;
end;

// SIMD Array Add: dst[i] = src1[i] + src2[i]
procedure SimdArrayAdd(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then Exit;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;

  if LCaps.Has256 then
    while aCount >= 8 do
    begin
      LD^.StoreF32x8(aDst, LD^.AddF32x8(LD^.LoadF32x8(aSrc1), LD^.LoadF32x8(aSrc2)));
      Inc(aSrc1, 8); Inc(aSrc2, 8); Inc(aDst, 8); Dec(aCount, 8);
    end;

  if LCaps.Has128 then
    while aCount >= 4 do
    begin
      LD^.StoreF32x4(aDst, LD^.AddF32x4(LD^.LoadF32x4(aSrc1), LD^.LoadF32x4(aSrc2)));
      Inc(aSrc1, 4); Inc(aSrc2, 4); Inc(aDst, 4); Dec(aCount, 4);
    end;

  while aCount > 0 do
  begin
    aDst^ := aSrc1^ + aSrc2^;
    Inc(aSrc1); Inc(aSrc2); Inc(aDst); Dec(aCount);
  end;
end;

procedure SimdArrayMul(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then Exit;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;

  if LCaps.Has256 then
    while aCount >= 8 do
    begin
      LD^.StoreF32x8(aDst, LD^.MulF32x8(LD^.LoadF32x8(aSrc1), LD^.LoadF32x8(aSrc2)));
      Inc(aSrc1, 8); Inc(aSrc2, 8); Inc(aDst, 8); Dec(aCount, 8);
    end;

  if LCaps.Has128 then
    while aCount >= 4 do
    begin
      LD^.StoreF32x4(aDst, LD^.MulF32x4(LD^.LoadF32x4(aSrc1), LD^.LoadF32x4(aSrc2)));
      Inc(aSrc1, 4); Inc(aSrc2, 4); Inc(aDst, 4); Dec(aCount, 4);
    end;

  while aCount > 0 do
  begin
    aDst^ := aSrc1^ * aSrc2^;
    Inc(aSrc1); Inc(aSrc2); Inc(aDst); Dec(aCount);
  end;
end;

procedure SimdArrayMulScalar(aSrc, aDst: PSingle; aCount: SizeUInt; aScalar: Single);
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
  LScale4: TVecF32x4;
  LScale8: TVecF32x8;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then Exit;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;

  if LCaps.Has256 then
  begin
    LScale8 := LD^.SplatF32x8(aScalar);
    while aCount >= 8 do
    begin
      LD^.StoreF32x8(aDst, LD^.MulF32x8(LD^.LoadF32x8(aSrc), LScale8));
      Inc(aSrc, 8); Inc(aDst, 8); Dec(aCount, 8);
    end;
  end;

  if LCaps.Has128 then
  begin
    LScale4 := LD^.SplatF32x4(aScalar);
    while aCount >= 4 do
    begin
      LD^.StoreF32x4(aDst, LD^.MulF32x4(LD^.LoadF32x4(aSrc), LScale4));
      Inc(aSrc, 4); Inc(aDst, 4); Dec(aCount, 4);
    end;
  end;

  while aCount > 0 do
  begin
    aDst^ := aSrc^ * aScalar;
    Inc(aSrc); Inc(aDst); Dec(aCount);
  end;
end;

// AXPY: dst[i] = alpha * x[i] + y[i]
procedure SimdArrayAxpy(aAlpha: Single; aX, aY, aDst: PSingle; aCount: SizeUInt);
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
  LAlpha4: TVecF32x4;
  LAlpha8: TVecF32x8;
begin
  if (aX = nil) or (aY = nil) or (aDst = nil) or (aCount = 0) then Exit;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;

  if LCaps.Has256 then
  begin
    LAlpha8 := LD^.SplatF32x8(aAlpha);
    while aCount >= 8 do
    begin
      LD^.StoreF32x8(aDst, LD^.AddF32x8(
        LD^.MulF32x8(LAlpha8, LD^.LoadF32x8(aX)),
        LD^.LoadF32x8(aY)));
      Inc(aX, 8); Inc(aY, 8); Inc(aDst, 8); Dec(aCount, 8);
    end;
  end;

  if LCaps.Has128 then
  begin
    LAlpha4 := LD^.SplatF32x4(aAlpha);
    while aCount >= 4 do
    begin
      LD^.StoreF32x4(aDst, LD^.AddF32x4(
        LD^.MulF32x4(LAlpha4, LD^.LoadF32x4(aX)),
        LD^.LoadF32x4(aY)));
      Inc(aX, 4); Inc(aY, 4); Inc(aDst, 4); Dec(aCount, 4);
    end;
  end;

  while aCount > 0 do
  begin
    aDst^ := aAlpha * aX^ + aY^;
    Inc(aX); Inc(aY); Inc(aDst); Dec(aCount);
  end;
end;

function SimdReduceSum(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
  LAcc4: TVecF32x4;
  LAcc8: TVecF32x8;
begin
  Result := 0;
  if (aSrc = nil) or (aCount = 0) then Exit;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;

  if LCaps.Has256 and (aCount >= 8) then
  begin
    LAcc8 := LD^.LoadF32x8(aSrc);
    Inc(aSrc, 8); Dec(aCount, 8);
    while aCount >= 8 do
    begin
      LAcc8 := LD^.AddF32x8(LAcc8, LD^.LoadF32x8(aSrc));
      Inc(aSrc, 8); Dec(aCount, 8);
    end;
    Result := LD^.ReduceAddF32x8(LAcc8);
  end
  else if LCaps.Has128 and (aCount >= 4) then
  begin
    LAcc4 := LD^.LoadF32x4(aSrc);
    Inc(aSrc, 4); Dec(aCount, 4);
    while aCount >= 4 do
    begin
      LAcc4 := LD^.AddF32x4(LAcc4, LD^.LoadF32x4(aSrc));
      Inc(aSrc, 4); Dec(aCount, 4);
    end;
    Result := LD^.ReduceAddF32x4(LAcc4);
  end;

  while aCount > 0 do
  begin
    Result := Result + aSrc^;
    Inc(aSrc); Dec(aCount);
  end;
end;

function SimdReduceDot(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
  LAcc4: TVecF32x4;
  LAcc8: TVecF32x8;
begin
  Result := 0;
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then Exit;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;

  if LCaps.Has256 and (aCount >= 8) then
  begin
    LAcc8 := LD^.MulF32x8(LD^.LoadF32x8(aSrc1), LD^.LoadF32x8(aSrc2));
    Inc(aSrc1, 8); Inc(aSrc2, 8); Dec(aCount, 8);
    while aCount >= 8 do
    begin
      LAcc8 := LD^.AddF32x8(LAcc8, LD^.MulF32x8(LD^.LoadF32x8(aSrc1), LD^.LoadF32x8(aSrc2)));
      Inc(aSrc1, 8); Inc(aSrc2, 8); Dec(aCount, 8);
    end;
    Result := LD^.ReduceAddF32x8(LAcc8);
  end
  else if LCaps.Has128 and (aCount >= 4) then
  begin
    LAcc4 := LD^.MulF32x4(LD^.LoadF32x4(aSrc1), LD^.LoadF32x4(aSrc2));
    Inc(aSrc1, 4); Inc(aSrc2, 4); Dec(aCount, 4);
    while aCount >= 4 do
    begin
      LAcc4 := LD^.AddF32x4(LAcc4, LD^.MulF32x4(LD^.LoadF32x4(aSrc1), LD^.LoadF32x4(aSrc2)));
      Inc(aSrc1, 4); Inc(aSrc2, 4); Dec(aCount, 4);
    end;
    Result := LD^.ReduceAddF32x4(LAcc4);
  end;

  while aCount > 0 do
  begin
    Result := Result + aSrc1^ * aSrc2^;
    Inc(aSrc1); Inc(aSrc2); Dec(aCount);
  end;
end;

function SimdReduceMin(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
  LAcc4: TVecF32x4;
begin
  if (aSrc = nil) or (aCount = 0) then begin Result := 0; Exit; end;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;
  Result := aSrc^;

  if LCaps.Has128 and (aCount >= 4) then
  begin
    LAcc4 := LD^.LoadF32x4(aSrc);
    Inc(aSrc, 4); Dec(aCount, 4);
    while aCount >= 4 do
    begin
      LAcc4 := LD^.MinF32x4(LAcc4, LD^.LoadF32x4(aSrc));
      Inc(aSrc, 4); Dec(aCount, 4);
    end;
    Result := LD^.ReduceMinF32x4(LAcc4);
  end;

  while aCount > 0 do
  begin
    if aSrc^ < Result then Result := aSrc^;
    Inc(aSrc); Dec(aCount);
  end;
end;

function SimdReduceMax(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LCaps: TF32Caps;
  LD: PSimdDispatchTable;
  LAcc4: TVecF32x4;
begin
  if (aSrc = nil) or (aCount = 0) then begin Result := 0; Exit; end;
  LCaps := ProbeF32Caps;
  LD := LCaps.D;
  Result := aSrc^;

  if LCaps.Has128 and (aCount >= 4) then
  begin
    LAcc4 := LD^.LoadF32x4(aSrc);
    Inc(aSrc, 4); Dec(aCount, 4);
    while aCount >= 4 do
    begin
      LAcc4 := LD^.MaxF32x4(LAcc4, LD^.LoadF32x4(aSrc));
      Inc(aSrc, 4); Dec(aCount, 4);
    end;
    Result := LD^.ReduceMaxF32x4(LAcc4);
  end;

  while aCount > 0 do
  begin
    if aSrc^ > Result then Result := aSrc^;
    Inc(aSrc); Dec(aCount);
  end;
end;

end.
