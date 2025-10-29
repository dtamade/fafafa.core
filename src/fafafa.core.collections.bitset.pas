unit fafafa.core.collections.bitset;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base;

type
  {**
   * IBitSet
   *
   * @desc Efficient bit set collection for boolean flags
   * @note Uses UInt64 words for compact storage (1 bit per boolean vs 1 byte)
   *}
  IBitSet = interface(ICollection)
  ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    {**
     * SetBit
     *
     * @desc Sets a bit to 1 at the specified index
     * @param aIndex The bit index to set
     *}
    procedure SetBit(aIndex: SizeUInt);

    {**
     * ClearBit
     *
     * @desc Clears a bit to 0 at the specified index
     * @param aIndex The bit index to clear
     *}
    procedure ClearBit(aIndex: SizeUInt);

    {**
     * Test
     *
     * @desc Tests if a bit is set (1) at the specified index
     * @param aIndex The bit index to test
     * @return Boolean True if bit is set, False otherwise
     *}
    function Test(aIndex: SizeUInt): Boolean;

    {**
     * Flip
     *
     * @desc Toggles a bit at the specified index
     * @param aIndex The bit index to flip
     *}
    procedure Flip(aIndex: SizeUInt);

    {**
     * AndWith
     *
     * @desc Performs bitwise AND with another BitSet
     * @param aOther The other BitSet
     * @return IBitSet New BitSet containing the result
     *}
    function AndWith(const aOther: IBitSet): IBitSet;

    {**
     * OrWith
     *
     * @desc Performs bitwise OR with another BitSet
     * @param aOther The other BitSet
     * @return IBitSet New BitSet containing the result
     *}
    function OrWith(const aOther: IBitSet): IBitSet;

    {**
     * XorWith
     *
     * @desc Performs bitwise XOR with another BitSet
     * @param aOther The other BitSet
     * @return IBitSet New BitSet containing the result
     *}
    function XorWith(const aOther: IBitSet): IBitSet;

    {**
     * NotBits
     *
     * @desc Performs bitwise NOT (inversion)
     * @return IBitSet New BitSet containing the result
     *}
    function NotBits: IBitSet;

    {**
     * Cardinality
     *
     * @desc Counts the number of set bits (1s)
     * @return SizeUInt The count of set bits
     *}
    function Cardinality: SizeUInt;

    {**
     * SetAll
     *
     * @desc Sets all bits in the current capacity range to 1
     *}
    procedure SetAll;

    {**
     * ClearAll
     *
     * @desc Clears all bits to 0
     *}
    procedure ClearAll;

    {**
     * GetBitCapacity
     *
     * @desc Returns the total number of bits that can be stored
     * @return SizeUInt The bit capacity
     *}
    function GetBitCapacity: SizeUInt;

    property BitCapacity: SizeUInt read GetBitCapacity;
  end;

  {**
   * TBitSet
   *
   * @desc Implementation of IBitSet using UInt64 array
   *}
  TBitSet = class(TCollection, IBitSet)
  private
    FBits: array of UInt64;
    FBitCapacity: SizeUInt;  // Total bits capacity

    procedure EnsureCapacity(aIndex: SizeUInt);
    function PopCount(aValue: UInt64): SizeUInt; inline;

  public
    constructor Create; overload;
    constructor Create(aInitialCapacity: SizeUInt); overload;
    constructor Create(aAllocator: IAllocator); overload;
    constructor Create(aInitialCapacity: SizeUInt; aAllocator: IAllocator); overload;
    destructor Destroy; override;

    // IBitSet interface
    procedure SetBit(aIndex: SizeUInt);
    procedure ClearBit(aIndex: SizeUInt);
    function Test(aIndex: SizeUInt): Boolean;
    procedure Flip(aIndex: SizeUInt);
    function AndWith(const aOther: IBitSet): IBitSet;
    function OrWith(const aOther: IBitSet): IBitSet;
    function XorWith(const aOther: IBitSet): IBitSet;
    function NotBits: IBitSet;
    function Cardinality: SizeUInt;
    procedure SetAll;
    procedure ClearAll;
    function GetBitCapacity: SizeUInt;

    // ICollection interface
    function GetCount: SizeUInt;
    function IsEmpty: Boolean;
    procedure Clear;
    function PtrIter: TPtrIter;
    procedure SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt); override;
    function GetElementSize: SizeUInt;
    
    // Abstract methods from TCollection
    function IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean; override;
    procedure AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt); override;
    procedure AppendToUnChecked(const aDst: TCollection); override;

    property BitCapacity: SizeUInt read GetBitCapacity;
  end;

implementation

const
  BITS_PER_WORD = 64;

{ TBitSet }

constructor TBitSet.Create;
begin
  Create(64, nil);
end;

constructor TBitSet.Create(aInitialCapacity: SizeUInt);
begin
  Create(aInitialCapacity, nil);
end;

constructor TBitSet.Create(aAllocator: IAllocator);
begin
  Create(64, aAllocator);
end;

constructor TBitSet.Create(aInitialCapacity: SizeUInt; aAllocator: IAllocator);
var
  LWordCount: SizeUInt;
begin
  inherited Create(aAllocator);

  if aInitialCapacity = 0 then
    aInitialCapacity := 64;

  // Round up to nearest word boundary
  LWordCount := (aInitialCapacity + BITS_PER_WORD - 1) div BITS_PER_WORD;
  SetLength(FBits, LWordCount);
  FBitCapacity := LWordCount * BITS_PER_WORD;

  // Initialize to zero
  FillChar(FBits[0], Length(FBits) * SizeOf(UInt64), 0);
end;

destructor TBitSet.Destroy;
begin
  SetLength(FBits, 0);
  inherited;
end;

procedure TBitSet.EnsureCapacity(aIndex: SizeUInt);
var
  LRequiredWords, LOldLen, i: SizeUInt;
begin
  if aIndex < FBitCapacity then
    Exit;

  // Calculate required word count
  LRequiredWords := (aIndex + BITS_PER_WORD) div BITS_PER_WORD;
  LOldLen := Length(FBits);

  // Expand array
  SetLength(FBits, LRequiredWords);
  FBitCapacity := LRequiredWords * BITS_PER_WORD;

  // Zero out new words
  for i := LOldLen to LRequiredWords - 1 do
    FBits[i] := 0;
end;

function TBitSet.PopCount(aValue: UInt64): SizeUInt; inline;
begin
  // Software popcount implementation
  Result := 0;
  while aValue <> 0 do
  begin
    Result := Result + (aValue and 1);
    aValue := aValue shr 1;
  end;
end;

procedure TBitSet.SetBit(aIndex: SizeUInt);
var
  LWordIndex, LBitIndex: SizeUInt;
begin
  EnsureCapacity(aIndex);
  LWordIndex := aIndex div BITS_PER_WORD;
  LBitIndex := aIndex mod BITS_PER_WORD;
  FBits[LWordIndex] := FBits[LWordIndex] or (UInt64(1) shl LBitIndex);
end;

procedure TBitSet.ClearBit(aIndex: SizeUInt);
var
  LWordIndex, LBitIndex: SizeUInt;
begin
  if aIndex >= FBitCapacity then
    Exit;  // Bit is already 0 (doesn't exist)

  LWordIndex := aIndex div BITS_PER_WORD;
  LBitIndex := aIndex mod BITS_PER_WORD;
  FBits[LWordIndex] := FBits[LWordIndex] and not (UInt64(1) shl LBitIndex);
end;

function TBitSet.Test(aIndex: SizeUInt): Boolean;
var
  LWordIndex, LBitIndex: SizeUInt;
begin
  if aIndex >= FBitCapacity then
    Exit(False);

  LWordIndex := aIndex div BITS_PER_WORD;
  LBitIndex := aIndex mod BITS_PER_WORD;
  Result := (FBits[LWordIndex] and (UInt64(1) shl LBitIndex)) <> 0;
end;

procedure TBitSet.Flip(aIndex: SizeUInt);
var
  LWordIndex, LBitIndex: SizeUInt;
begin
  EnsureCapacity(aIndex);
  LWordIndex := aIndex div BITS_PER_WORD;
  LBitIndex := aIndex mod BITS_PER_WORD;
  FBits[LWordIndex] := FBits[LWordIndex] xor (UInt64(1) shl LBitIndex);
end;

function TBitSet.AndWith(const aOther: IBitSet): IBitSet;
var
  LResult: TBitSet;
  LMinWords, i: SizeUInt;
  LOtherBitSet: TBitSet;
begin
  LOtherBitSet := aOther as TBitSet;
  LMinWords := Length(FBits);
  if Length(LOtherBitSet.FBits) < LMinWords then
    LMinWords := Length(LOtherBitSet.FBits);

  LResult := TBitSet.Create(FBitCapacity, FAllocator);
  for i := 0 to LMinWords - 1 do
    LResult.FBits[i] := FBits[i] and LOtherBitSet.FBits[i];

  Result := LResult;
end;

function TBitSet.OrWith(const aOther: IBitSet): IBitSet;
var
  LResult: TBitSet;
  LMaxWords, i: SizeUInt;
  LOtherBitSet: TBitSet;
begin
  LOtherBitSet := aOther as TBitSet;
  LMaxWords := Length(FBits);
  if Length(LOtherBitSet.FBits) > LMaxWords then
    LMaxWords := Length(LOtherBitSet.FBits);

  LResult := TBitSet.Create(LMaxWords * BITS_PER_WORD, FAllocator);

  for i := 0 to Length(FBits) - 1 do
    LResult.FBits[i] := FBits[i];

  for i := 0 to Length(LOtherBitSet.FBits) - 1 do
    LResult.FBits[i] := LResult.FBits[i] or LOtherBitSet.FBits[i];

  Result := LResult;
end;

function TBitSet.XorWith(const aOther: IBitSet): IBitSet;
var
  LResult: TBitSet;
  LMaxWords, i: SizeUInt;
  LOtherBitSet: TBitSet;
begin
  LOtherBitSet := aOther as TBitSet;
  LMaxWords := Length(FBits);
  if Length(LOtherBitSet.FBits) > LMaxWords then
    LMaxWords := Length(LOtherBitSet.FBits);

  LResult := TBitSet.Create(LMaxWords * BITS_PER_WORD, FAllocator);

  for i := 0 to Length(FBits) - 1 do
    LResult.FBits[i] := FBits[i];

  for i := 0 to Length(LOtherBitSet.FBits) - 1 do
    LResult.FBits[i] := LResult.FBits[i] xor LOtherBitSet.FBits[i];

  Result := LResult;
end;

function TBitSet.NotBits: IBitSet;
var
  LResult: TBitSet;
  i: SizeUInt;
begin
  LResult := TBitSet.Create(FBitCapacity, FAllocator);
  for i := 0 to Length(FBits) - 1 do
    LResult.FBits[i] := not FBits[i];

  Result := LResult;
end;

function TBitSet.Cardinality: SizeUInt;
var
  i: SizeUInt;
begin
  Result := 0;
  for i := 0 to Length(FBits) - 1 do
    Result := Result + PopCount(FBits[i]);
end;

procedure TBitSet.SetAll;
var
  i: SizeUInt;
begin
  for i := 0 to Length(FBits) - 1 do
    FBits[i] := High(UInt64);
end;

procedure TBitSet.ClearAll;
begin
  if Length(FBits) > 0 then
    FillChar(FBits[0], Length(FBits) * SizeOf(UInt64), 0);
end;

function TBitSet.GetBitCapacity: SizeUInt;
begin
  Result := FBitCapacity;
end;

function TBitSet.GetCount: SizeUInt;
begin
  Result := Cardinality;
end;

function TBitSet.IsEmpty: Boolean;
begin
  Result := Cardinality = 0;
end;

procedure TBitSet.Clear;
begin
  ClearAll;
end;

function TBitSet.PtrIter: TPtrIter;
begin
  // BitSet uses UInt64 array, not suitable for generic pointer iteration
  // Callers should use specific methods like Test() to access bits
  FillChar(Result, SizeOf(TPtrIter), 0);
end;

procedure TBitSet.SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt);
var
  LByteCount: SizeUInt;
begin
  if (aDst = nil) or (aCount = 0) then
    Exit;

  LByteCount := aCount * SizeOf(UInt64);
  if LByteCount > Length(FBits) * SizeOf(UInt64) then
    LByteCount := Length(FBits) * SizeOf(UInt64);

  Move(FBits[0], aDst^, LByteCount);
end;

function TBitSet.GetElementSize: SizeUInt;
begin
  Result := SizeOf(UInt64);
end;

function TBitSet.IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean;
begin
  // BitSet uses dynamic array, no overlap possible
  Result := False;
end;

procedure TBitSet.AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt);
var
  i: SizeUInt;
  LSrcWords: ^UInt64;
begin
  if (aSrc = nil) or (aElementCount = 0) then
    Exit;

  LSrcWords := aSrc;
  for i := 0 to aElementCount - 1 do
  begin
    // Append by OR-ing words
    if i < Length(FBits) then
      FBits[i] := FBits[i] or LSrcWords[i];
    Inc(LSrcWords);
  end;
end;

procedure TBitSet.AppendToUnChecked(const aDst: TCollection);
var
  LDstBitSet: TBitSet;
  i: SizeUInt;
begin
  if aDst = nil then
    Exit;

  if aDst is TBitSet then
  begin
    LDstBitSet := TBitSet(aDst);
    for i := 0 to Length(FBits) - 1 do
    begin
      if i < Length(LDstBitSet.FBits) then
        LDstBitSet.FBits[i] := LDstBitSet.FBits[i] or FBits[i];
    end;
  end
  else
    raise EInvalidOperation.Create('Cannot append BitSet to incompatible container type');
end;

end.

