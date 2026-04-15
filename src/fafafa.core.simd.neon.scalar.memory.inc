// === Memory Operations ===

function NEONLoadF32x4(p: PSingle): TVecF32x4;
type
  TSingleLanes = array[0..3] of Single;
  PSingleLanes = ^TSingleLanes;
begin
  Result.f[0] := PSingleLanes(p)^[0];
  Result.f[1] := PSingleLanes(p)^[1];
  Result.f[2] := PSingleLanes(p)^[2];
  Result.f[3] := PSingleLanes(p)^[3];
end;

function NEONLoadF32x4Aligned(p: PSingle): TVecF32x4;
type
  TSingleLanes = array[0..3] of Single;
  PSingleLanes = ^TSingleLanes;
begin
  Result.f[0] := PSingleLanes(p)^[0];
  Result.f[1] := PSingleLanes(p)^[1];
  Result.f[2] := PSingleLanes(p)^[2];
  Result.f[3] := PSingleLanes(p)^[3];
end;

procedure NEONStoreF32x4(p: PSingle; const a: TVecF32x4);
type
  TSingleLanes = array[0..3] of Single;
  PSingleLanes = ^TSingleLanes;
begin
  PSingleLanes(p)^[0] := a.f[0];
  PSingleLanes(p)^[1] := a.f[1];
  PSingleLanes(p)^[2] := a.f[2];
  PSingleLanes(p)^[3] := a.f[3];
end;

procedure NEONStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
type
  TSingleLanes = array[0..3] of Single;
  PSingleLanes = ^TSingleLanes;
begin
  PSingleLanes(p)^[0] := a.f[0];
  PSingleLanes(p)^[1] := a.f[1];
  PSingleLanes(p)^[2] := a.f[2];
  PSingleLanes(p)^[3] := a.f[3];
end;
