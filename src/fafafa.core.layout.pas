unit fafafa.core.layout;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.bits;

type
  {**
   * TMemLayout
   *
   * Rust-style memory layout descriptor.
   * 以 `Size + Align` 表达一块内存的布局需求。
   *}
  TMemLayout = record
  private
    FSize: SizeUInt;
    FAlign: SizeUInt;
  public
    property Size: SizeUInt read FSize;
    property Align: SizeUInt read FAlign;

    class function Create(aSize: SizeUInt; aAlign: SizeUInt = 0): TMemLayout; static;
    class function TryCreate(aSize: SizeUInt; aAlign: SizeUInt; out aLayout: TMemLayout): Boolean; static;
    generic class function ForType<T>: TMemLayout; static;
    generic class function ForArray<T>(aCount: SizeUInt): TMemLayout; static;

    function IsValid: Boolean; inline;
    function IsZeroSized: Boolean; inline;
    function AlignedSize: SizeUInt; inline;
    function Extend(const aNext: TMemLayout): TMemLayout;
    function Pad(aAlign: SizeUInt): TMemLayout;

    class function Empty: TMemLayout; static; inline;
    class function DefaultAlign: SizeUInt; static; inline;
  end;

  {**
   * TAllocCaps
   *
   * Allocator capability descriptor.
   * 只表达分配器的真实能力，不掺杂策略层语义。
   *}
  TAllocCaps = record
    ZeroOnAlloc: Boolean;
    ThreadSafe: Boolean;
    KnowsSize: Boolean;
    NativeAligned: Boolean;
    CanRealloc: Boolean;
    MaxAlign: SizeUInt;

    class function Create(
      aZeroOnAlloc: Boolean = False;
      aThreadSafe: Boolean = False;
      aKnowsSize: Boolean = False;
      aNativeAligned: Boolean = False;
      aCanRealloc: Boolean = True;
      aMaxAlign: SizeUInt = 0
    ): TAllocCaps; static;

    class function Default: TAllocCaps; static; inline;
    class function ForSystemHeap: TAllocCaps; static;
    function SupportsLayout(const aLayout: TMemLayout): Boolean;
  end;

const
  MEM_DEFAULT_ALIGN = SizeOf(Pointer);
  MEM_CACHE_LINE_SIZE = 64;
  MEM_PAGE_SIZE = 4096;

function TryNextPowerOfTwo(aValue: SizeUInt; out aResult: SizeUInt): Boolean;

implementation

const
  {$IFDEF CPU64}
  LAYOUT_MAX_POWER_OF_TWO: SizeUInt = SizeUInt(1) shl 63;
  {$ELSE}
  LAYOUT_MAX_POWER_OF_TWO: SizeUInt = SizeUInt(1) shl 31;
  {$ENDIF}

function TryNextPowerOfTwo(aValue: SizeUInt; out aResult: SizeUInt): Boolean;
begin
  if aValue = 0 then
  begin
    aResult := 1;
    Exit(True);
  end;

  if fafafa.core.bits.IsPowerOfTwo(aValue) then
  begin
    aResult := aValue;
    Exit(True);
  end;

  if aValue > LAYOUT_MAX_POWER_OF_TWO then
  begin
    aResult := 0;
    Exit(False);
  end;

  aResult := fafafa.core.bits.NextPowerOfTwo(aValue);
  Result := True;
end;

class function TMemLayout.Create(aSize: SizeUInt; aAlign: SizeUInt): TMemLayout;
begin
  Result.FSize := aSize;

  if aAlign = 0 then
    Result.FAlign := MEM_DEFAULT_ALIGN
  else if fafafa.core.bits.IsPowerOfTwo(aAlign) then
    Result.FAlign := aAlign
  else if not TryNextPowerOfTwo(aAlign, Result.FAlign) then
    Result.FAlign := LAYOUT_MAX_POWER_OF_TWO;
end;

class function TMemLayout.TryCreate(aSize: SizeUInt; aAlign: SizeUInt; out aLayout: TMemLayout): Boolean;
var
  LAlign: SizeUInt;
begin
  aLayout.FSize := aSize;

  if aAlign = 0 then
  begin
    aLayout.FAlign := MEM_DEFAULT_ALIGN;
    Exit(True);
  end;

  if fafafa.core.bits.IsPowerOfTwo(aAlign) then
  begin
    aLayout.FAlign := aAlign;
    Exit(True);
  end;

  Result := TryNextPowerOfTwo(aAlign, LAlign);
  if Result then
    aLayout.FAlign := LAlign
  else
    aLayout.FAlign := 0;
end;

generic class function TMemLayout.ForType<T>: TMemLayout;
begin
  Result.FSize := SizeOf(T);
  if SizeOf(T) >= MEM_DEFAULT_ALIGN then
    Result.FAlign := MEM_DEFAULT_ALIGN
  else if fafafa.core.bits.IsPowerOfTwo(SizeOf(T)) then
    Result.FAlign := SizeOf(T)
  else
    Result.FAlign := fafafa.core.bits.NextPowerOfTwo(SizeOf(T));
end;

generic class function TMemLayout.ForArray<T>(aCount: SizeUInt): TMemLayout;
var
  LElementSize: SizeUInt;
  LElementAlign: SizeUInt;
begin
  LElementSize := SizeOf(T);

  if LElementSize >= MEM_DEFAULT_ALIGN then
    LElementAlign := MEM_DEFAULT_ALIGN
  else if fafafa.core.bits.IsPowerOfTwo(LElementSize) then
    LElementAlign := LElementSize
  else
    LElementAlign := fafafa.core.bits.NextPowerOfTwo(LElementSize);

  Result.FAlign := LElementAlign;

  if aCount = 0 then
    Result.FSize := 0
  else
    Result.FSize := fafafa.core.bits.AlignUp(LElementSize, LElementAlign) * aCount;
end;

function TMemLayout.IsValid: Boolean;
begin
  Result := fafafa.core.bits.IsPowerOfTwo(FAlign);
end;

function TMemLayout.IsZeroSized: Boolean;
begin
  Result := FSize = 0;
end;

function TMemLayout.AlignedSize: SizeUInt;
begin
  Result := fafafa.core.bits.AlignUp(FSize, FAlign);
end;

function TMemLayout.Extend(const aNext: TMemLayout): TMemLayout;
var
  LNewAlign: SizeUInt;
  LPaddedSize: SizeUInt;
begin
  if aNext.FAlign > FAlign then
    LNewAlign := aNext.FAlign
  else
    LNewAlign := FAlign;

  LPaddedSize := fafafa.core.bits.AlignUp(FSize, aNext.FAlign);

  Result.FSize := LPaddedSize + aNext.FSize;
  Result.FAlign := LNewAlign;
end;

function TMemLayout.Pad(aAlign: SizeUInt): TMemLayout;
var
  LAlign: SizeUInt;
begin
  if fafafa.core.bits.IsPowerOfTwo(aAlign) then
    LAlign := aAlign
  else if not TryNextPowerOfTwo(aAlign, LAlign) then
    LAlign := LAYOUT_MAX_POWER_OF_TWO;

  Result.FSize := fafafa.core.bits.AlignUp(FSize, LAlign);

  if LAlign > FAlign then
    Result.FAlign := LAlign
  else
    Result.FAlign := FAlign;
end;

class function TMemLayout.Empty: TMemLayout;
begin
  Result.FSize := 0;
  Result.FAlign := 1;
end;

class function TMemLayout.DefaultAlign: SizeUInt;
begin
  Result := MEM_DEFAULT_ALIGN;
end;

class function TAllocCaps.Create(
  aZeroOnAlloc: Boolean;
  aThreadSafe: Boolean;
  aKnowsSize: Boolean;
  aNativeAligned: Boolean;
  aCanRealloc: Boolean;
  aMaxAlign: SizeUInt
): TAllocCaps;
begin
  Result.ZeroOnAlloc := aZeroOnAlloc;
  Result.ThreadSafe := aThreadSafe;
  Result.KnowsSize := aKnowsSize;
  Result.NativeAligned := aNativeAligned;
  Result.CanRealloc := aCanRealloc;
  Result.MaxAlign := aMaxAlign;
end;

class function TAllocCaps.Default: TAllocCaps;
begin
  Result := TAllocCaps.Create;
end;

class function TAllocCaps.ForSystemHeap: TAllocCaps;
begin
  Result := TAllocCaps.Create(
    False,
    True,
    False,
    False,
    True,
    MEM_DEFAULT_ALIGN
  );
end;

function TAllocCaps.SupportsLayout(const aLayout: TMemLayout): Boolean;
begin
  if not aLayout.IsValid then
    Exit(False);

  if NativeAligned then
  begin
    if (MaxAlign > 0) and (aLayout.Align > MaxAlign) then
      Result := False
    else
      Result := True;
  end
  else
    Result := aLayout.Align <= MEM_DEFAULT_ALIGN;
end;

end.
