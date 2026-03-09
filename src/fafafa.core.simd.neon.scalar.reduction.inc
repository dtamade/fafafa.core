// === Reduction Operations ===

function NEONReduceAddF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] + a.f[1] + a.f[2] + a.f[3];
end;

function NEONReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function NEONReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function NEONReduceMulF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] * a.f[1] * a.f[2] * a.f[3];
end;

// ✅ I32x4 规约操作 (Scalar fallback)
{$PUSH}{$R-}{$Q-}
function NEONReduceAddI32x4(const a: TVecI32x4): Int32;
begin
  Result := a.i[0] + a.i[1] + a.i[2] + a.i[3];
end;

function NEONReduceMinI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := a.i[0];
  for i := 1 to 3 do
    if a.i[i] < Result then
      Result := a.i[i];
end;

function NEONReduceMaxI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := a.i[0];
  for i := 1 to 3 do
    if a.i[i] > Result then
      Result := a.i[i];
end;

// ✅ U32x4 规约操作 (Scalar fallback)
function NEONReduceAddU32x4(const a: TVecU32x4): UInt32;
begin
  Result := a.u[0] + a.u[1] + a.u[2] + a.u[3];
end;

function NEONReduceMinU32x4(const a: TVecU32x4): UInt32;
var i: Integer;
begin
  Result := a.u[0];
  for i := 1 to 3 do
    if a.u[i] < Result then
      Result := a.u[i];
end;

function NEONReduceMaxU32x4(const a: TVecU32x4): UInt32;
var i: Integer;
begin
  Result := a.u[0];
  for i := 1 to 3 do
    if a.u[i] > Result then
      Result := a.u[i];
end;
{$POP}

