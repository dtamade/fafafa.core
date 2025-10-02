unit fafafa.core.simd.memutils;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

// === Aligned Memory Allocation ===

// Allocate aligned memory
function AlignedAlloc(size: NativeUInt; alignment: NativeUInt): Pointer;

// Free aligned memory
procedure AlignedFree(ptr: Pointer);

// Reallocate aligned memory
function AlignedRealloc(ptr: Pointer; newSize: NativeUInt; alignment: NativeUInt): Pointer;

// === Alignment Utilities ===

// Check if pointer is aligned to specified boundary
function IsAligned(ptr: Pointer; alignment: NativeUInt): Boolean; inline;

// Align pointer up to next boundary
function AlignUp(ptr: Pointer; alignment: NativeUInt): Pointer; inline;
function AlignUpSize(size: NativeUInt; alignment: NativeUInt): NativeUInt; inline;

// Get alignment of pointer (largest power of 2 that divides address)
function GetAlignment(ptr: Pointer): NativeUInt;

// === Memory Operations ===

// Fast aligned memory copy (requires both src and dst to be aligned)
procedure AlignedMemCopy(src, dst: Pointer; size: NativeUInt; alignment: NativeUInt);

// Fast aligned memory fill
procedure AlignedMemFill(dst: Pointer; size: NativeUInt; value: Byte; alignment: NativeUInt);

// Memory prefetch hints
procedure Prefetch(ptr: Pointer); inline;
procedure PrefetchNTA(ptr: Pointer); inline;  // Non-temporal (won't pollute cache)

// === Aligned Array Helper ===
type
  // RAII-style aligned array
  TAlignedArray<T> = record
  private
    FData: Pointer;
    FSize: NativeUInt;
    FAlignment: NativeUInt;
    FOwnsMemory: Boolean;
  public
    // Create aligned array
    class function Create(count: NativeUInt; alignment: NativeUInt = 32): TAlignedArray<T>; static;
    
    // Create from existing aligned memory (doesn't take ownership)
    class function FromPointer(ptr: Pointer; count: NativeUInt; alignment: NativeUInt): TAlignedArray<T>; static;
    
    // Destroy and free memory
    procedure Free;
    
    // Properties
    function GetData: Pointer; inline;
    function GetItem(index: NativeUInt): T; inline;
    procedure SetItem(index: NativeUInt; const value: T); inline;
    function GetCount: NativeUInt; inline;
    function GetAlignment: NativeUInt; inline;
    function IsValid: Boolean; inline;
    
    // Array access
    property Data: Pointer read GetData;
    property Items[index: NativeUInt]: T read GetItem write SetItem; default;
    property Count: NativeUInt read GetCount;
    property Alignment: NativeUInt read GetAlignment;
  end;

// === Constants ===
const
  // Common alignment values
  SIMD_ALIGN_16 = 16;   // SSE alignment
  SIMD_ALIGN_32 = 32;   // AVX alignment  
  SIMD_ALIGN_64 = 64;   // AVX-512 alignment
  SIMD_ALIGN_CACHE = 64; // Cache line alignment

implementation

uses
  {$IFDEF WINDOWS}
  Windows
  {$ENDIF}
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF};

// === Platform-specific aligned allocation ===

{$IFDEF WINDOWS}

function AlignedAlloc(size: NativeUInt; alignment: NativeUInt): Pointer;
begin
  Result := _aligned_malloc(size, alignment);
  if Result = nil then
    raise EOutOfMemory.CreateFmt('Failed to allocate %d bytes with %d alignment', [size, alignment]);
end;

procedure AlignedFree(ptr: Pointer);
begin
  if ptr <> nil then
    _aligned_free(ptr);
end;

function AlignedRealloc(ptr: Pointer; newSize: NativeUInt; alignment: NativeUInt): Pointer;
begin
  Result := _aligned_realloc(ptr, newSize, alignment);
  if (Result = nil) and (newSize > 0) then
    raise EOutOfMemory.CreateFmt('Failed to reallocate %d bytes with %d alignment', [newSize, alignment]);
end;

{$ELSE} // UNIX/Linux

function AlignedAlloc(size: NativeUInt; alignment: NativeUInt): Pointer;
var
  originalPtr: Pointer;
  alignedPtr: Pointer;
  offset: NativeUInt;
begin
  // Allocate extra space for alignment and storing original pointer
  originalPtr := GetMem(size + alignment + SizeOf(Pointer));
  if originalPtr = nil then
    raise EOutOfMemory.CreateFmt('Failed to allocate %d bytes with %d alignment', [size, alignment]);
    
  // Calculate aligned address
  alignedPtr := AlignUp(Pointer(NativeUInt(originalPtr) + SizeOf(Pointer)), alignment);
  
  // Store original pointer just before aligned memory
  PPointer(NativeUInt(alignedPtr) - SizeOf(Pointer))^ := originalPtr;
  
  Result := alignedPtr;
end;

procedure AlignedFree(ptr: Pointer);
var
  originalPtr: Pointer;
begin
  if ptr <> nil then
  begin
    // Retrieve original pointer
    originalPtr := PPointer(NativeUInt(ptr) - SizeOf(Pointer))^;
    FreeMem(originalPtr);
  end;
end;

function AlignedRealloc(ptr: Pointer; newSize: NativeUInt; alignment: NativeUInt): Pointer;
var
  newPtr: Pointer;
  oldSize: NativeUInt;
begin
  if ptr = nil then
  begin
    Result := AlignedAlloc(newSize, alignment);
    Exit;
  end;
  
  if newSize = 0 then
  begin
    AlignedFree(ptr);
    Result := nil;
    Exit;
  end;
  
  // Allocate new aligned memory
  newPtr := AlignedAlloc(newSize, alignment);
  
  // Copy old data (we don't know the old size, so copy conservatively)
  // In a real implementation, you'd want to track allocation sizes
  oldSize := newSize; // Simplified - assume same size for now
  Move(ptr^, newPtr^, oldSize);
  
  // Free old memory
  AlignedFree(ptr);
  
  Result := newPtr;
end;

{$ENDIF}

// === Alignment Utilities ===

function IsAligned(ptr: Pointer; alignment: NativeUInt): Boolean;
begin
  Result := (NativeUInt(ptr) and (alignment - 1)) = 0;
end;

function AlignUp(ptr: Pointer; alignment: NativeUInt): Pointer;
var
  addr: NativeUInt;
begin
  addr := NativeUInt(ptr);
  addr := (addr + alignment - 1) and not (alignment - 1);
  Result := Pointer(addr);
end;

function AlignUpSize(size: NativeUInt; alignment: NativeUInt): NativeUInt;
begin
  Result := (size + alignment - 1) and not (alignment - 1);
end;

function GetAlignment(ptr: Pointer): NativeUInt;
var
  addr: NativeUInt;
begin
  addr := NativeUInt(ptr);
  if addr = 0 then
  begin
    Result := 0;
    Exit;
  end;
  
  // Find largest power of 2 that divides address
  Result := 1;
  while (addr and Result) = 0 do
    Result := Result shl 1;
end;

// === Memory Operations ===

procedure AlignedMemCopy(src, dst: Pointer; size: NativeUInt; alignment: NativeUInt);
begin
  {$IFDEF SIMD_DEBUG_ASSERTIONS}
  Assert(IsAligned(src, alignment), 'Source not aligned');
  Assert(IsAligned(dst, alignment), 'Destination not aligned');
  {$ENDIF}
  
  // Use optimized copy for aligned memory
  // For now, just use Move - could be optimized with SIMD
  Move(src^, dst^, size);
end;

procedure AlignedMemFill(dst: Pointer; size: NativeUInt; value: Byte; alignment: NativeUInt);
begin
  {$IFDEF SIMD_DEBUG_ASSERTIONS}
  Assert(IsAligned(dst, alignment), 'Destination not aligned');
  {$ENDIF}
  
  // Use optimized fill for aligned memory
  FillChar(dst^, size, value);
end;

procedure Prefetch(ptr: Pointer);
begin
  // Platform-specific prefetch instructions would go here
  // For now, this is a no-op
  {$IFDEF SIMD_X86_AVAILABLE}
  // Could use: asm prefetcht0 [ptr] end;
  {$ENDIF}
end;

procedure PrefetchNTA(ptr: Pointer);
begin
  // Non-temporal prefetch
  {$IFDEF SIMD_X86_AVAILABLE}
  // Could use: asm prefetchnta [ptr] end;
  {$ENDIF}
end;

// === TAlignedArray Implementation ===

class function TAlignedArray<T>.Create(count: NativeUInt; alignment: NativeUInt): TAlignedArray<T>;
begin
  Result.FSize := count;
  Result.FAlignment := alignment;
  Result.FOwnsMemory := True;
  
  if count > 0 then
    Result.FData := AlignedAlloc(count * SizeOf(T), alignment)
  else
    Result.FData := nil;
end;

class function TAlignedArray<T>.FromPointer(ptr: Pointer; count: NativeUInt; alignment: NativeUInt): TAlignedArray<T>;
begin
  Result.FData := ptr;
  Result.FSize := count;
  Result.FAlignment := alignment;
  Result.FOwnsMemory := False;
end;

procedure TAlignedArray<T>.Free;
begin
  if FOwnsMemory and (FData <> nil) then
  begin
    AlignedFree(FData);
    FData := nil;
  end;
  FSize := 0;
end;

function TAlignedArray<T>.GetData: Pointer;
begin
  Result := FData;
end;

function TAlignedArray<T>.GetItem(index: NativeUInt): T;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if index >= FSize then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..%d]', [index, FSize - 1]);
  {$ENDIF}
  
  Result := (PArray<T>(FData))[index];
end;

procedure TAlignedArray<T>.SetItem(index: NativeUInt; const value: T);
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if index >= FSize then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..%d]', [index, FSize - 1]);
  {$ENDIF}
  
  (PArray<T>(FData))[index] := value;
end;

function TAlignedArray<T>.GetCount: NativeUInt;
begin
  Result := FSize;
end;

function TAlignedArray<T>.GetAlignment: NativeUInt;
begin
  Result := FAlignment;
end;

function TAlignedArray<T>.IsValid: Boolean;
begin
  Result := FData <> nil;
end;

end.


