unit fafafa.core.span;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base;

type
  generic TReadOnlySpan<T> = record
  public type
    PElement = ^T;
  private
    FPtr: Pointer;
    FCount: SizeUInt;
  public
    class function FromPointer(aPtr: Pointer; aCount: SizeUInt): TReadOnlySpan; static; inline;
    function Count: SizeUInt; inline;
    function IsEmpty: Boolean; inline;
    function Get(aIndex: SizeUInt): T; inline;
    function TryGet(aIndex: SizeUInt; out aElement: T): Boolean; inline;
    function GetPtr(aIndex: SizeUInt): Pointer; inline;
    function SubSpan(aIndex, aCount: SizeUInt): TReadOnlySpan; inline;
  end;

  generic TReadOnlySpan2<T> = record
  public type
    TSpan = specialize TReadOnlySpan<T>;
  private
    FA: TSpan;
    FB: TSpan;
  public
    class function FromTwo(constref A, B: TSpan): TReadOnlySpan2; static; inline;
    function ASpan: TSpan; inline;
    function BSpan: TSpan; inline;
    function Count: SizeUInt; inline;
    function IsEmpty: Boolean; inline;
    function Get(aIndex: SizeUInt): T; inline;
    function TryGet(aIndex: SizeUInt; out aElement: T): Boolean; inline;
    function GetPtr(aIndex: SizeUInt): Pointer; inline;
    function GetBlock(aIndex: SizeUInt; out aPtr: Pointer; out aLen: SizeUInt): Boolean; inline;
    function SubSpan(aIndex, aCount: SizeUInt): TReadOnlySpan2;
  end;

implementation

class function TReadOnlySpan.FromPointer(aPtr: Pointer; aCount: SizeUInt): TReadOnlySpan;
begin
  Result.FPtr := aPtr;
  Result.FCount := aCount;
end;

function TReadOnlySpan.Count: SizeUInt; inline;
begin
  Result := FCount;
end;

function TReadOnlySpan.IsEmpty: Boolean; inline;
begin
  Result := FCount = 0;
end;

function TReadOnlySpan.Get(aIndex: SizeUInt): T; inline;
begin
  if aIndex >= FCount then
    raise EOutOfRange.Create('Span.Get: index out of range');
  Result := PElement(PByte(FPtr) + aIndex * SizeOf(T))^;
end;

function TReadOnlySpan.TryGet(aIndex: SizeUInt; out aElement: T): Boolean; inline;
begin
  if aIndex < FCount then
  begin
    aElement := PElement(PByte(FPtr) + aIndex * SizeOf(T))^;
    Exit(True);
  end;

  aElement := Default(T);
  Result := False;
end;

function TReadOnlySpan.GetPtr(aIndex: SizeUInt): Pointer; inline;
begin
  if aIndex >= FCount then
    raise EOutOfRange.Create('Span.GetPtr: index out of range');
  Result := Pointer(PByte(FPtr) + aIndex * SizeOf(T));
end;

function TReadOnlySpan.SubSpan(aIndex, aCount: SizeUInt): TReadOnlySpan; inline;
begin
  if aCount = 0 then
    Exit(FromPointer(nil, 0));

  if (aIndex >= FCount) or (aCount > (FCount - aIndex)) then
    raise EOutOfRange.Create('Span.SubSpan: range out of bounds');

  Result := FromPointer(Pointer(PByte(FPtr) + aIndex * SizeOf(T)), aCount);
end;

class function TReadOnlySpan2.FromTwo(constref A, B: TReadOnlySpan2.TSpan): TReadOnlySpan2;
begin
  Result.FA := A;
  Result.FB := B;
end;

function TReadOnlySpan2.ASpan: TReadOnlySpan2.TSpan; inline;
begin
  Result := FA;
end;

function TReadOnlySpan2.BSpan: TReadOnlySpan2.TSpan; inline;
begin
  Result := FB;
end;

function TReadOnlySpan2.Count: SizeUInt; inline;
begin
  Result := FA.Count + FB.Count;
end;

function TReadOnlySpan2.IsEmpty: Boolean; inline;
begin
  Result := (FA.Count = 0) and (FB.Count = 0);
end;

function TReadOnlySpan2.Get(aIndex: SizeUInt): T; inline;
var
  LASize: SizeUInt;
begin
  LASize := FA.Count;
  if aIndex < LASize then
    Exit(FA.Get(aIndex));

  aIndex := aIndex - LASize;
  if aIndex < FB.Count then
    Exit(FB.Get(aIndex));

  raise EOutOfRange.Create('Span2.Get: index out of range');
end;

function TReadOnlySpan2.TryGet(aIndex: SizeUInt; out aElement: T): Boolean; inline;
var
  LASize: SizeUInt;
begin
  LASize := FA.Count;
  if aIndex < LASize then
    Exit(FA.TryGet(aIndex, aElement));

  aIndex := aIndex - LASize;
  if aIndex < FB.Count then
    Exit(FB.TryGet(aIndex, aElement));

  aElement := Default(T);
  Result := False;
end;

function TReadOnlySpan2.GetPtr(aIndex: SizeUInt): Pointer; inline;
var
  LASize: SizeUInt;
begin
  LASize := FA.Count;
  if aIndex < LASize then
    Exit(FA.GetPtr(aIndex));

  aIndex := aIndex - LASize;
  if aIndex < FB.Count then
    Exit(FB.GetPtr(aIndex));

  raise EOutOfRange.Create('Span2.GetPtr: index out of range');
end;

function TReadOnlySpan2.GetBlock(aIndex: SizeUInt; out aPtr: Pointer; out aLen: SizeUInt): Boolean; inline;
var
  LASize: SizeUInt;
begin
  LASize := FA.Count;
  if aIndex < LASize then
  begin
    aPtr := FA.GetPtr(aIndex);
    aLen := LASize - aIndex;
    Exit(True);
  end;

  aIndex := aIndex - LASize;
  if aIndex < FB.Count then
  begin
    aPtr := FB.GetPtr(aIndex);
    aLen := FB.Count - aIndex;
    Exit(True);
  end;

  aPtr := nil;
  aLen := 0;
  Result := False;
end;

function TReadOnlySpan2.SubSpan(aIndex, aCount: SizeUInt): TReadOnlySpan2;
var
  LTotal: SizeUInt;
  LASize: SizeUInt;
  LSubA: TSpan;
  LSubB: TSpan;
begin
  if aCount = 0 then
    Exit(FromTwo(TSpan.FromPointer(nil, 0), TSpan.FromPointer(nil, 0)));

  LTotal := Count;
  if (aIndex >= LTotal) or (aCount > (LTotal - aIndex)) then
    raise EOutOfRange.Create('Span2.SubSpan: range out of bounds');

  LASize := FA.Count;
  if aIndex < LASize then
  begin
    if aIndex + aCount <= LASize then
    begin
      LSubA := FA.SubSpan(aIndex, aCount);
      LSubB := TSpan.FromPointer(nil, 0);
      Exit(FromTwo(LSubA, LSubB));
    end;

    LSubA := FA.SubSpan(aIndex, LASize - aIndex);
    LSubB := FB.SubSpan(0, aCount - LSubA.Count);
    Exit(FromTwo(LSubA, LSubB));
  end;

  aIndex := aIndex - LASize;
  LSubA := TSpan.FromPointer(nil, 0);
  LSubB := FB.SubSpan(aIndex, aCount);
  Result := FromTwo(LSubA, LSubB);
end;

end.
