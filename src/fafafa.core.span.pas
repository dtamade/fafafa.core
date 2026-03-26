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

end.
