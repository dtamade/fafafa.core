unit fafafa.core.term.paste.ring;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils;

function term_paste_ring_store_text(const aText: string): SizeUInt;
function term_paste_ring_get_text(aId: SizeUInt): string;
procedure term_paste_ring_clear_all;
procedure term_paste_ring_trim_keep_last(aKeepLast: SizeUInt);
procedure term_paste_ring_set_auto_keep_last(aKeepLast: SizeUInt);
procedure term_paste_ring_set_max_bytes(aMaxBytes: SizeUInt);
procedure term_paste_ring_set_trim_fastpath_div(aDivisor: SizeUInt);
function term_paste_ring_get_count: SizeUInt;
function term_paste_ring_get_total_bytes: SizeUInt;
function term_paste_ring_get_auto_keep_last: SizeUInt;
function term_paste_ring_get_max_bytes: SizeUInt;
function term_paste_ring_get_trim_fastpath_div: SizeUInt;

implementation

var
  RING_ITEMS: array of string = nil;
  RING_CAP: SizeUInt = 0;
  RING_HEAD: SizeUInt = 0;
  RING_COUNT: SizeUInt = 0;
  RING_TOTAL_BYTES: SizeUInt = 0;

  RING_MAX_BYTES: SizeUInt = 0;
  RING_AUTO_KEEP_LAST: SizeUInt = 0;
  RING_TRIM_FASTPATH_DIV: SizeUInt = 8; // kept for parity; currently not used

procedure ring_clear_array;
var i: SizeUInt;
begin
  for i := 0 to High(RING_ITEMS) do
    RING_ITEMS[i] := '';
end;

procedure ring_reset_all;
begin
  RING_HEAD := 0;
  RING_COUNT := 0;
  RING_TOTAL_BYTES := 0;
  // keep capacity to avoid frequent reallocations
  if Length(RING_ITEMS) > 0 then
    ring_clear_array;
end;

procedure ring_ensure_capacity(minCap: SizeUInt);
var
  newCap, i: SizeUInt;
  newItems: array of string;
begin
  if RING_CAP >= minCap then Exit;
  newCap := RING_CAP;
  if newCap = 0 then newCap := 16;
  while newCap < minCap do newCap := newCap shl 1;
  SetLength(newItems, newCap);
  // Initial grow: when capacity was 0, there is nothing to move and using mod 0 would raise
  if (RING_CAP = 0) or (RING_COUNT = 0) then
  begin
    RING_ITEMS := newItems;
    RING_CAP := newCap;
    RING_HEAD := 0;
    Exit;
  end;
  // move existing items in order to newItems[0..RING_COUNT-1]
  for i := 0 to RING_COUNT - 1 do
    newItems[i] := RING_ITEMS[(RING_HEAD + i) mod RING_CAP];
  RING_ITEMS := newItems;
  RING_CAP := newCap;
  RING_HEAD := 0;
end;

procedure ring_drop_head_one;
var
  idx: SizeUInt;
  L: SizeUInt;
begin
  if RING_COUNT = 0 then Exit;
  idx := (RING_HEAD) mod RING_CAP;
  L := Length(RING_ITEMS[idx]);
  RING_ITEMS[idx] := '';
  Inc(RING_HEAD);
  if RING_HEAD >= RING_CAP then RING_HEAD := 0;
  Dec(RING_COUNT);
  if RING_TOTAL_BYTES >= L then Dec(RING_TOTAL_BYTES, L) else RING_TOTAL_BYTES := 0;
end;

function term_paste_ring_store_text(const aText: string): SizeUInt;
var
  tailIdx: SizeUInt;
  needDrop: SizeUInt;
begin
  // return current logical index before append (0-based)
  Result := RING_COUNT;
  if aText = '' then Exit;

  ring_ensure_capacity(RING_COUNT + 1);
  tailIdx := (RING_HEAD + RING_COUNT) mod RING_CAP;
  RING_ITEMS[tailIdx] := aText;
  Inc(RING_COUNT);
  Inc(RING_TOTAL_BYTES, Length(aText));

  if (RING_MAX_BYTES > 0) and (RING_TOTAL_BYTES > RING_MAX_BYTES) then
  begin
    if (RING_AUTO_KEEP_LAST > 0) and (Length(aText) <= RING_MAX_BYTES) then
    begin
      // keep only latest item
      ring_clear_array;
      RING_ITEMS[0] := aText;
      RING_HEAD := 0;
      RING_COUNT := 1;
      RING_TOTAL_BYTES := Length(aText);
      Exit;
    end;

    needDrop := RING_TOTAL_BYTES - RING_MAX_BYTES;
    while (RING_COUNT > 0) and (needDrop > 0) do
    begin
      needDrop := needDrop - Length(RING_ITEMS[RING_HEAD]);
      ring_drop_head_one;
    end;
  end;
end;

function term_paste_ring_get_text(aId: SizeUInt): string;
var idx: SizeUInt;
begin
  if aId >= RING_COUNT then Exit('');
  idx := (RING_HEAD + aId) mod RING_CAP;
  Result := RING_ITEMS[idx];
end;

procedure term_paste_ring_clear_all;
begin
  ring_reset_all;
end;

procedure term_paste_ring_trim_keep_last(aKeepLast: SizeUInt);
var toDrop: SizeUInt;
begin
  if (aKeepLast = 0) or (RING_COUNT <= aKeepLast) then Exit;
  toDrop := RING_COUNT - aKeepLast;
  while (toDrop > 0) and (RING_COUNT > 0) do
  begin
    ring_drop_head_one;
    Dec(toDrop);
  end;
end;

procedure term_paste_ring_set_auto_keep_last(aKeepLast: SizeUInt);
begin
  RING_AUTO_KEEP_LAST := aKeepLast;
end;

procedure term_paste_ring_set_max_bytes(aMaxBytes: SizeUInt);
begin
  RING_MAX_BYTES := aMaxBytes;
  // optional: enforce immediately
  while (RING_MAX_BYTES > 0) and (RING_TOTAL_BYTES > RING_MAX_BYTES) and (RING_COUNT > 0) do
    ring_drop_head_one;
end;

procedure term_paste_ring_set_trim_fastpath_div(aDivisor: SizeUInt);
begin
  if aDivisor = 0 then aDivisor := 1;
  RING_TRIM_FASTPATH_DIV := aDivisor;
end;

function term_paste_ring_get_count: SizeUInt;
begin
  Result := RING_COUNT;
end;

function term_paste_ring_get_total_bytes: SizeUInt;
begin
  Result := RING_TOTAL_BYTES;
end;

function term_paste_ring_get_auto_keep_last: SizeUInt;
begin
  Result := RING_AUTO_KEEP_LAST;
end;

function term_paste_ring_get_max_bytes: SizeUInt;
begin
  Result := RING_MAX_BYTES;
end;

function term_paste_ring_get_trim_fastpath_div: SizeUInt;
begin
  Result := RING_TRIM_FASTPATH_DIV;
end;

end.

