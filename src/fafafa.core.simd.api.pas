unit fafafa.core.simd.api;

{$mode objfpc}{$H+}

interface

uses
  // 基于已存在的对外稳定类型与全局函数变量
  fafafa.core.simd,
  fafafa.core.mem; // 复用已落地的 Fill/Copy/Zero 等安全实现（先落地，后替换为 SIMD）

type
  // 过程类型（用于 Fill/Copy/Move/Zero 的可插拔绑定）
  TMemCopyProc = procedure(aSrc, aDst: Pointer; aSize: SizeUInt);
  TMemMoveProc = procedure(aSrc, aDst: Pointer; aSize: SizeUInt);
  TMemFillProc = procedure(aDst: Pointer; aSize: SizeUInt; aValue: Byte);
  TMemZeroProc = procedure(aDst: Pointer; aSize: SizeUInt);

  // 内存域 SIMD 操作集合
  TSimdMemOps = record
    // 对比/差异
    Equal:     TMemEqualFunc;
    DiffRange: TMemDiffRangeFunc;
    // 扫描
    FindByte:  TMemFindByteFunc;
    // 复制/移动/填充
    Copy:      TMemCopyProc;   // 允许重叠（memmove 语义）
    Move:      TMemMoveProc;   // 同上（与 Copy 等价，便于语义区分）
    Fill:      TMemFillProc;
    Zero:      TMemZeroProc;
  end;

  // 搜索域
  TSimdSearchOps = record
    BytesIndexOf: TBytesIndexOfFunc;
    // 解析器助手（当前为标量实现占位）
    FindEOL: function(hay: Pointer; len: SizeUInt): PtrInt;
    StartsWith: function(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): Boolean;
    StartsWithI: function(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): Boolean;
    FindFirstNotOf: function(hay: Pointer; len: SizeUInt; setPtr: Pointer; setLen: SizeUInt): PtrInt;
  end;

  // 文本域（ASCII/UTF-8）
  TSimdTextOps = record
    ToLowerAscii:        TAsciiCaseProc;
    ToUpperAscii:        TAsciiCaseProc;
    AsciiEqualIgnoreCase: TAsciiIeqFunc;
    Utf8Validate:        TUtf8ValidateFunc;
  end;

  // 位操作域
  TSimdBitOps = record
    PopCount: TPopCountFunc;
  end;

  // 聚合（便于一次性捕获当前已绑定的全部实现）
  TSimdOps = record
    Mem:    TSimdMemOps;
    Search: TSimdSearchOps;
    Text:   TSimdTextOps;
    Bit:    TSimdBitOps;
  end;

// 获取当前激活 Profile 下的已绑定实现（快照）
procedure SimdGetMemOps(out ops: TSimdMemOps);
procedure SimdGetSearchOps(out ops: TSimdSearchOps);
procedure SimdGetTextOps(out ops: TSimdTextOps);
procedure SimdGetBitOps(out ops: TSimdBitOps);
procedure SimdGetOps(out ops: TSimdOps);
function  SimdOps: TSimdOps; inline;

implementation

uses
  fafafa.core.simd.search; // 引入标量助手占位实现

procedure SimdGetMemOps(out ops: TSimdMemOps);
begin
  // 来自 fafafa.core.simd 的函数变量（在初始化时按 Profile 绑定）
  ops.Equal     := MemEqual;
  ops.DiffRange := MemDiffRange;
  ops.FindByte  := MemFindByte;
  // 复制/移动/填充/清零：先复用已落地的安全实现，后续可替换为 SIMD 微内核
  ops.Copy      := @fafafa.core.mem.Copy; // 允许重叠
  ops.Move      := @fafafa.core.mem.Copy; // 允许重叠（语义同 memmove）
  ops.Fill      := @fafafa.core.mem.Fill;
  ops.Zero      := @fafafa.core.mem.Zero;
end;

procedure SimdGetSearchOps(out ops: TSimdSearchOps);
begin
  ops.BytesIndexOf   := BytesIndexOf;
  // 解析器助手：当前使用标量占位，后续在 SIMD 稳定后替换
  ops.FindEOL        := @FindEOL_Scalar;
  ops.FindFirstNotOf := @FindFirstNotOf_Scalar;
  ops.StartsWith     := @StartsWith_Scalar;
  ops.StartsWithI    := @StartsWithI_Scalar;
end;



procedure SimdGetTextOps(out ops: TSimdTextOps);
begin
  ops.ToLowerAscii         := ToLowerAscii;
  ops.ToUpperAscii         := ToUpperAscii;
  ops.AsciiEqualIgnoreCase := AsciiIEqual;
  ops.Utf8Validate         := Utf8Validate;
end;

procedure SimdGetBitOps(out ops: TSimdBitOps);
begin
  ops.PopCount := BitsetPopCount;
end;

procedure SimdGetOps(out ops: TSimdOps);
begin
  SimdGetMemOps(ops.Mem);
  SimdGetSearchOps(ops.Search);
  SimdGetTextOps(ops.Text);
  SimdGetBitOps(ops.Bit);
end;

function SimdOps: TSimdOps; inline;
begin
  SimdGetOps(Result);
end;

end.

