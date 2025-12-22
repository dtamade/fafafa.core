{
  fafafa.core.id.v8 — UUID version 8 (Custom)

  RFC 9562 定义的自定义 UUID 格式:
  - 用户提供全部 122 位有效载荷
  - 仅设置版本位 (0x8x) 和变体位 (10xx)
  - 适用于将现有标识符嵌入 UUID 格式

  Layout (128 bits):
    - custom_a: bits 0-47 (48 bits) - 用户数据
    - ver: bits 48-51 (4 bits) - 版本 (1000 = 8)
    - custom_b: bits 52-63 (12 bits) - 用户数据
    - var: bits 64-65 (2 bits) - 变体 (10 = RFC 4122)
    - custom_c: bits 66-127 (62 bits) - 用户数据
}

unit fafafa.core.id.v8;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id;

type
  { 用于构建 v8 UUID 的数据结构 }
  TUuidV8Data = record
    CustomA: array[0..5] of Byte;   // 48 bits (6 bytes)
    CustomB: array[0..1] of Byte;   // 12 bits (使用高 12 位)
    CustomC: array[0..7] of Byte;   // 62 bits (使用高 62 位)
  end;

{ 从原始字节创建 UUID v8 }
function UuidV8(const Data: array of Byte): TUuid128;

{ 从结构化数据创建 UUID v8 }
function UuidV8_FromData(const Data: TUuidV8Data): TUuid128;

{ 从 64 位整数对创建 UUID v8 }
function UuidV8_FromInt64(High, Low: Int64): TUuid128;

{ 从哈希值创建 UUID v8 (截断或填充到 128 位) }
function UuidV8_FromHash(const Hash: array of Byte): TUuid128;

{ 验证 UUID 是否为 v8 }
function IsUuidV8(const U: TUuid128): Boolean;

{ 提取 v8 UUID 的自定义数据 }
function UuidV8_ExtractData(const U: TUuid128): TUuidV8Data;

{ 提取为 64 位整数对 }
procedure UuidV8_ExtractInt64(const U: TUuid128; out High, Low: Int64);

implementation

function UuidV8(const Data: array of Byte): TUuid128;
var
  I, Len: Integer;
begin
  // 初始化为零
  FillChar(Result[0], 16, 0);

  // 复制数据 (最多 16 字节)
  Len := Length(Data);
  if Len > 16 then
    Len := 16;
  for I := 0 to Len - 1 do
    Result[I] := Data[I];

  // 设置版本 8 (byte 6 的高 4 位)
  Result[6] := (Result[6] and $0F) or $80;

  // 设置变体 RFC 4122 (byte 8 的高 2 位 = 10)
  Result[8] := (Result[8] and $3F) or $80;
end;

function UuidV8_FromData(const Data: TUuidV8Data): TUuid128;
begin
  // bytes 0-5: CustomA (48 bits)
  Move(Data.CustomA[0], Result[0], 6);

  // bytes 6-7: version (4 bits) + CustomB (12 bits)
  // byte 6: version (high 4 bits) + CustomB high 4 bits
  // byte 7: CustomB low 8 bits
  Result[6] := $80 or ((Data.CustomB[0] shr 4) and $0F);
  Result[7] := ((Data.CustomB[0] and $0F) shl 4) or ((Data.CustomB[1] shr 4) and $0F);

  // byte 8: variant (2 bits) + CustomC high 6 bits
  Result[8] := $80 or ((Data.CustomC[0] shr 2) and $3F);

  // bytes 9-15: CustomC remaining bits
  Result[9] := ((Data.CustomC[0] and $03) shl 6) or ((Data.CustomC[1] shr 2) and $3F);
  Result[10] := ((Data.CustomC[1] and $03) shl 6) or ((Data.CustomC[2] shr 2) and $3F);
  Result[11] := ((Data.CustomC[2] and $03) shl 6) or ((Data.CustomC[3] shr 2) and $3F);
  Result[12] := ((Data.CustomC[3] and $03) shl 6) or ((Data.CustomC[4] shr 2) and $3F);
  Result[13] := ((Data.CustomC[4] and $03) shl 6) or ((Data.CustomC[5] shr 2) and $3F);
  Result[14] := ((Data.CustomC[5] and $03) shl 6) or ((Data.CustomC[6] shr 2) and $3F);
  Result[15] := ((Data.CustomC[6] and $03) shl 6) or ((Data.CustomC[7] shr 2) and $3F);
end;

function UuidV8_FromInt64(High, Low: Int64): TUuid128;
var
  H, L: QWord;
begin
  H := QWord(High);
  L := QWord(Low);

  // Pack High into bytes 0-7
  Result[0] := Byte((H shr 56) and $FF);
  Result[1] := Byte((H shr 48) and $FF);
  Result[2] := Byte((H shr 40) and $FF);
  Result[3] := Byte((H shr 32) and $FF);
  Result[4] := Byte((H shr 24) and $FF);
  Result[5] := Byte((H shr 16) and $FF);
  Result[6] := Byte((H shr 8) and $FF);
  Result[7] := Byte(H and $FF);

  // Pack Low into bytes 8-15
  Result[8] := Byte((L shr 56) and $FF);
  Result[9] := Byte((L shr 48) and $FF);
  Result[10] := Byte((L shr 40) and $FF);
  Result[11] := Byte((L shr 32) and $FF);
  Result[12] := Byte((L shr 24) and $FF);
  Result[13] := Byte((L shr 16) and $FF);
  Result[14] := Byte((L shr 8) and $FF);
  Result[15] := Byte(L and $FF);

  // 设置版本 8
  Result[6] := (Result[6] and $0F) or $80;

  // 设置变体 RFC 4122
  Result[8] := (Result[8] and $3F) or $80;
end;

function UuidV8_FromHash(const Hash: array of Byte): TUuid128;
var
  I, Len: Integer;
begin
  // 初始化为零
  FillChar(Result[0], 16, 0);

  // 复制哈希数据
  Len := Length(Hash);
  if Len > 16 then
    Len := 16;
  for I := 0 to Len - 1 do
    Result[I] := Hash[I];

  // 设置版本 8
  Result[6] := (Result[6] and $0F) or $80;

  // 设置变体 RFC 4122
  Result[8] := (Result[8] and $3F) or $80;
end;

function IsUuidV8(const U: TUuid128): Boolean;
begin
  // 版本 8 = byte 6 高 4 位为 1000 (0x8)
  // 变体 RFC 4122 = byte 8 高 2 位为 10
  Result := ((U[6] shr 4) = 8) and ((U[8] shr 6) = 2);
end;

function UuidV8_ExtractData(const U: TUuid128): TUuidV8Data;
begin
  // Extract CustomA (bytes 0-5)
  Move(U[0], Result.CustomA[0], 6);

  // Extract CustomB from bytes 6-7 (skip version bits)
  Result.CustomB[0] := ((U[6] and $0F) shl 4) or ((U[7] shr 4) and $0F);
  Result.CustomB[1] := (U[7] and $0F) shl 4;

  // Extract CustomC from bytes 8-15 (skip variant bits)
  Result.CustomC[0] := ((U[8] and $3F) shl 2) or ((U[9] shr 6) and $03);
  Result.CustomC[1] := ((U[9] and $3F) shl 2) or ((U[10] shr 6) and $03);
  Result.CustomC[2] := ((U[10] and $3F) shl 2) or ((U[11] shr 6) and $03);
  Result.CustomC[3] := ((U[11] and $3F) shl 2) or ((U[12] shr 6) and $03);
  Result.CustomC[4] := ((U[12] and $3F) shl 2) or ((U[13] shr 6) and $03);
  Result.CustomC[5] := ((U[13] and $3F) shl 2) or ((U[14] shr 6) and $03);
  Result.CustomC[6] := ((U[14] and $3F) shl 2) or ((U[15] shr 6) and $03);
  Result.CustomC[7] := (U[15] and $3F) shl 2;
end;

procedure UuidV8_ExtractInt64(const U: TUuid128; out High, Low: Int64);
begin
  // Extract High from bytes 0-7
  High := (Int64(U[0]) shl 56) or (Int64(U[1]) shl 48) or
          (Int64(U[2]) shl 40) or (Int64(U[3]) shl 32) or
          (Int64(U[4]) shl 24) or (Int64(U[5]) shl 16) or
          (Int64(U[6]) shl 8) or Int64(U[7]);

  // Extract Low from bytes 8-15
  Low := (Int64(U[8]) shl 56) or (Int64(U[9]) shl 48) or
         (Int64(U[10]) shl 40) or (Int64(U[11]) shl 32) or
         (Int64(U[12]) shl 24) or (Int64(U[13]) shl 16) or
         (Int64(U[14]) shl 8) or Int64(U[15]);
end;

end.
