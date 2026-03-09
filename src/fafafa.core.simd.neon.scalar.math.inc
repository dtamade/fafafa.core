// === Math Operations ===

function NEONAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Abs(a.f[i]);
end;

function NEONSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function NEONMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function NEONMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

