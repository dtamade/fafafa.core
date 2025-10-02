unit fafafa.core.simd.api;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

// === SIMD 门面函数 API ===
// 这些是高级用户接口，提供运行时派发到最�?SIMD 实现

// === 内存操作函数 ===

// 内存比较
function MemEqual(a, b: Pointer; len: SizeUInt): LongBool; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 字节查找
function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 差异范围检�?function MemDiffRange(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 内存复制
procedure MemCopy(src, dst: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 内存设置
procedure MemSet(dst: Pointer; len: SizeUInt; value: Byte); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 内存反转
procedure MemReverse(p: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// === 统计函数 ===

// 字节求和
function SumBytes(p: Pointer; len: SizeUInt): UInt64; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 最值查�?procedure MinMaxBytes(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// 字节计数
function CountByte(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// === 文本处理函数 ===

// UTF-8 验证
function Utf8Validate(p: Pointer; len: SizeUInt): Boolean; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// ASCII 忽略大小写比�?function AsciiIEqual(a, b: Pointer; len: SizeUInt): Boolean; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// ASCII 转小�?procedure ToLowerAscii(p: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// ASCII 转大�?procedure ToUpperAscii(p: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// === 搜索函数 ===

// 字节序列搜索
function BytesIndexOf(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

// === 位集函数 ===

// 位集合人口计�?function BitsetPopCount(p: Pointer; byteLen: SizeUInt): SizeUInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}

implementation

uses
  fafafa.core.simd.scalar;

// === 内存操作函数实现 ===

function MemEqual(a, b: Pointer; len: SizeUInt): LongBool;
begin
  // 目前使用标量实现，后续会添加 SIMD 派发
  Result := MemEqual_Scalar(a, b, len);
end;

function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;

function MemDiffRange(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  Result := MemDiffRange_Scalar(a, b, len, firstDiff, lastDiff);
end;

procedure MemCopy(src, dst: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dst, len);
end;

procedure MemSet(dst: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(dst, len, value);
end;

procedure MemReverse(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

// === 统计函数实现 ===

function SumBytes(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := SumBytes_Scalar(p, len);
end;

procedure MinMaxBytes(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

function CountByte(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := CountByte_Scalar(p, len, value);
end;

// === 文本处理函数实现 ===

function Utf8Validate(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function AsciiIEqual(a, b: Pointer; len: SizeUInt): Boolean;
begin
  Result := AsciiIEqual_Scalar(a, b, len);
end;

procedure ToLowerAscii(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

// === 搜索函数实现 ===

function BytesIndexOf(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

// === 位集函数实现 ===

function BitsetPopCount(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, byteLen);
end;

end.


