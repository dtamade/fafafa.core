// === Memory Operations ===

function NEONLoadF32x4(p: PSingle): TVecF32x4;
begin
  Move(p^, Result.f[0], 16);
end;

function NEONLoadF32x4Aligned(p: PSingle): TVecF32x4;
begin
  Move(p^, Result.f[0], 16);
end;

procedure NEONStoreF32x4(p: PSingle; const a: TVecF32x4);
begin
  Move(a.f[0], p^, 16);
end;

procedure NEONStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
begin
  Move(a.f[0], p^, 16);
end;

