unit fafafa.core.endian;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

type
  {**
   * TEndianness
   *
   * 基础端序枚举。
   * `enNative` 代表调用点要求“按当前平台本机端序解释”。
   *}
  TEndianness = (enLittleEndian, enBigEndian, enNative);

function NativeEndianness: TEndianness; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function ResolveEndianness(aEndianness: TEndianness): TEndianness; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsLittleEndian(aEndianness: TEndianness = enNative): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsBigEndian(aEndianness: TEndianness = enNative): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function ByteSwap16(aValue: Word): Word; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function ByteSwap32(aValue: DWord): DWord; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function ByteSwap64(aValue: QWord): QWord; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function NativeEndianness: TEndianness;
begin
  {$IFDEF ENDIAN_LITTLE}
  Result := enLittleEndian;
  {$ELSE}
  Result := enBigEndian;
  {$ENDIF}
end;

function ResolveEndianness(aEndianness: TEndianness): TEndianness;
begin
  if aEndianness = enNative then
    Result := NativeEndianness
  else
    Result := aEndianness;
end;

function IsLittleEndian(aEndianness: TEndianness): Boolean;
begin
  Result := ResolveEndianness(aEndianness) = enLittleEndian;
end;

function IsBigEndian(aEndianness: TEndianness): Boolean;
begin
  Result := ResolveEndianness(aEndianness) = enBigEndian;
end;

function ByteSwap16(aValue: Word): Word;
begin
  Result := (aValue shr 8) or (aValue shl 8);
end;

function ByteSwap32(aValue: DWord): DWord;
begin
  Result :=
    ((aValue and DWord($000000FF)) shl 24) or
    ((aValue and DWord($0000FF00)) shl 8) or
    ((aValue and DWord($00FF0000)) shr 8) or
    ((aValue and DWord($FF000000)) shr 24);
end;

function ByteSwap64(aValue: QWord): QWord;
begin
  Result :=
    ((aValue and QWord($00000000000000FF)) shl 56) or
    ((aValue and QWord($000000000000FF00)) shl 40) or
    ((aValue and QWord($0000000000FF0000)) shl 24) or
    ((aValue and QWord($00000000FF000000)) shl 8) or
    ((aValue and QWord($000000FF00000000)) shr 8) or
    ((aValue and QWord($0000FF0000000000)) shr 24) or
    ((aValue and QWord($00FF000000000000)) shr 40) or
    ((aValue and QWord($FF00000000000000)) shr 56);
end;

end.
