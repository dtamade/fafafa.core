unit fafafa.core.simd.search;

{$mode objfpc}{$H+}
{$IFDEF CPUX86_64}{$asmmode intel}{$ENDIF}

interface

// 返回 haystack 中 needle 第一次出现的位置（0-based），未找到返回 -1
// 约定：nlen=0 返回 0；nlen>len 返回 -1
function BytesIndexOf_Scalar(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
{$IFDEF CPUX86_64}
function BytesIndexOf_SSE2(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
function BytesIndexOf_AVX2(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
{$ENDIF}
{$IFDEF CPUAARCH64}
function BytesIndexOf_NEON(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
{$ENDIF}

// 解析器常用助手（先标量实现，后续可切 SIMD）
// 返回 CRLF ("\r\n") 的起始索引；若仅有 '\n'，返回其索引；未找到返回 -1
function FindEOL_Scalar(hay: Pointer; len: SizeUInt): PtrInt;
// 返回第一个不属于集合 set[0..setLen-1] 的位置；未找到返回 -1
function FindFirstNotOf_Scalar(hay: Pointer; len: SizeUInt; setPtr: Pointer; setLen: SizeUInt): PtrInt;
  // 前缀判断：StartsWith/StartsWithI（标量原型）
  function StartsWith_Scalar(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): Boolean;
  function StartsWithI_Scalar(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): Boolean;



implementation

uses
  fafafa.core.simd.mem,
  fafafa.core.simd.text;

// 简单 BMH（Boyer–Moore–Horspool）字节搜索，适合一般场景
function BytesIndexOf_Scalar(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
var
  h: PByte; n: PByte; i: SizeUInt; last: Byte; skip: array[0..255] of SizeUInt;
  pos: SizeUInt; j: SizeUInt;
begin
  if nlen = 0 then Exit(0);
  if (len = 0) or (nlen > len) then Exit(-1);
  h := PByte(hay); n := PByte(ned);
  last := n[nlen-1];
  for i := 0 to 255 do skip[i] := nlen;
  if nlen >= 2 then
    for i := 0 to nlen-2 do
      skip[n[i]] := nlen-1-i;
  pos := 0;
  while pos <= len - nlen do
  begin
    if h[pos + nlen - 1] = last then
    begin
      // 比较其余部分
      j := 0;
      while (j < nlen-1) and (h[pos + j] = n[j]) do Inc(j);
      if j = nlen-1 then Exit(PtrInt(pos));
    end;
    pos += skip[h[pos + nlen - 1]];
  end;
  Result := -1;
end;

{$IFDEF CPUX86_64}
function BytesIndexOf_SSE2(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
var
  h, n: PByte;
  last: Byte;
  searchPos: SizeUInt;
  rel: PtrInt;
  i: SizeUInt;
  base: PByte;
  needMiddleCheck: Boolean;
  midStart: SizeUInt;
  baseIdx: SizeUInt;
begin
  if nlen = 0 then Exit(0);
  if (len = 0) or (nlen > len) then Exit(-1);
  h := PByte(hay); n := PByte(ned);
  last := n[nlen-1];
  // 小长度分支：直接走稳妥路径，确保正确性
  if nlen = 1 then
    Exit(BytesIndexOf_Scalar(hay, len, ned, nlen));
  if nlen < 16 then
    Exit(BytesIndexOf_Scalar(hay, len, ned, nlen));
  // 从第一个可能对齐的位置开始（候选的尾部）
  searchPos := nlen - 1;
  while searchPos < len do
  begin
    // 在 [searchPos, len) 范围查找下一个 last
    rel := MemFindByte_SSE2(@h[searchPos], len - searchPos, last);
    if rel < 0 then Exit(-1);
    i := searchPos + SizeUInt(rel); // 候选匹配的“尾”位置

    // 安全边界检查：确保 base 指向有效的起始位置
    if i < nlen - 1 then
    begin
      searchPos := i + 1; Continue;
    end;
    baseIdx := i - (nlen - 1);
    base := @h[baseIdx];

    // 快速预检查：首/尾 16B（当长度足够）
    if nlen >= 16 then
    begin
      if not MemEqual_SSE2(base, @n[0], 16) then
      begin
        searchPos := i + 1; Continue;
      end;
      if nlen > 16 then
      begin
        if not MemEqual_SSE2(@base[nlen-16], @n[nlen-16], 16) then
        begin
          searchPos := i + 1; Continue;
        end;
      end;
    end;

    // 需要中段检查？（仅当 nlen > 32 且避免重复比较）
    needMiddleCheck := nlen > 32;
    if needMiddleCheck then
    begin
      // 比较中间段，选取起点 16..(nlen-16-16) 的中位
      // 这里取 midStart = 16 + (nlen-32) div 2
      midStart := 16 + SizeUInt((nlen - 32) div 2);
      if not MemEqual_SSE2(@base[midStart], @n[midStart], 16) then
      begin
        searchPos := i + 1; Continue;
      end;
    end;

    // 最终完整比较（去除已比较的块可减少长度，但为清晰保持一次 CompareByte）
    if CompareByte(base^, n^, nlen) = 0 then
      Exit(PtrInt(baseIdx));

    // 下一次从 i+1 的尾部继续
    searchPos := i + 1;
  end;
  Result := -1;
end;

function BytesIndexOf_AVX2(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
var
  h, n: PByte;
  last: Byte;
  searchPos: SizeUInt;
  rel: PtrInt;
  i: SizeUInt;
  base: PByte;
  needMid32: Boolean;
  midStart32: SizeUInt;
  baseIdx: SizeUInt;
begin
  if nlen = 0 then Exit(0);
  if (len = 0) or (nlen > len) then Exit(-1);
  // 小长度直接复用 SSE2 实现以保证正确性
  if nlen < 16 then Exit(BytesIndexOf_SSE2(hay, len, ned, nlen));
  h := PByte(hay); n := PByte(ned);
  last := n[nlen-1];
  searchPos := nlen - 1;
  while searchPos < len do
  begin
    // 临时：使用 SSE2 的 MemFindByte，待 AVX2 核心稳定后切回 AVX2
    rel := MemFindByte_AVX2(@h[searchPos], len - searchPos, last);
    if rel < 0 then Exit(-1);
    i := searchPos + SizeUInt(rel);

    // 安全边界检查：确保 base 指向有效的起始位置
    if i < nlen - 1 then
    begin
      searchPos := i + 1; Continue;
    end;
    baseIdx := i - (nlen - 1);
    base := @h[baseIdx];

    // AVX2 快速预检查：优先 32B，其次 16B
    if nlen >= 32 then
    begin
      if not MemEqual_AVX2(base, @n[0], 32) then
      begin
        searchPos := i + 1; Continue;
      end;
      if not MemEqual_AVX2(@base[nlen-32], @n[nlen-32], 32) then
      begin
        searchPos := i + 1; Continue;
      end;
    end
    else if nlen >= 16 then
    begin
      if not MemEqual_SSE2(base, @n[0], 16) then
      begin
        searchPos := i + 1; Continue;
      end;
      if nlen > 16 then
      begin
        if not MemEqual_SSE2(@base[nlen-16], @n[nlen-16], 16) then
        begin
          searchPos := i + 1; Continue;
        end;
      end;
    end;

    needMid32 := nlen > 64;
    if needMid32 then
    begin
      // 取中部 32B 快速否决
      midStart32 := 32 + SizeUInt((nlen - 64) div 2);
      if not MemEqual_AVX2(@base[midStart32], @n[midStart32], 32) then
      begin
        searchPos := i + 1; Continue;
      end;
    end;

    if CompareByte(base^, n^, nlen) = 0 then
      Exit(PtrInt(baseIdx));

    searchPos := i + 1;

end;
Result := -1;
end;

{$IFDEF CPUAARCH64}
function BytesIndexOf_NEON(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
var
  h, n: PByte;
  last: Byte;
  searchPos: SizeUInt;
  rel: PtrInt;
  i: SizeUInt;
  base: PByte;
  needMid16: Boolean;
  baseIdx: SizeUInt;
begin
  if nlen = 0 then Exit(0);
  if (len = 0) or (nlen > len) then Exit(-1);
  h := PByte(hay); n := PByte(ned);
  last := n[nlen-1];
  searchPos := nlen - 1;
  while searchPos < len do
  begin
    rel := MemFindByte_NEON(@h[searchPos], len - searchPos, last);
    if rel < 0 then Exit(-1);
    i := searchPos + SizeUInt(rel);

    // 安全边界检查：确保 base 指向有效的起始位置
    if i < nlen - 1 then
    begin
      searchPos := i + 1; Continue;
    end;
    baseIdx := i - (nlen - 1);
    base := @h[baseIdx];

    // 预检查：首/尾 16B（当长度足够）
    if nlen >= 16 then
    begin
      if not MemEqual_NEON(base, @n[0], 16) then
      begin
        searchPos := i + 1; Continue;
      end;
      if nlen > 16 then
      begin
        if not MemEqual_NEON(@base[nlen-16], @n[nlen-16], 16) then
        begin
          searchPos := i + 1; Continue;
        end;
      end;
    end;

    needMid16 := nlen > 32;
    if needMid16 then
    begin
      // 中段 16B 快速否决
      var midStart := 16 + SizeUInt((nlen - 32) shr 1);
      if not MemEqual_NEON(@base[midStart], @n[midStart], 16) then
      begin
        searchPos := i + 1; Continue;
      end;
    end;

    // 最终完整比较
    if CompareByte(base^, n^, nlen) = 0 then
      Exit(PtrInt(baseIdx));

    searchPos := i + 1;
  end;
  Result := -1;
end;

{$ENDIF}

// 标量：查找 EOL（支持 \r\n 或单独 \n）。优先返回最先出现的 EOL 起始位置
function FindEOL_Scalar(hay: Pointer; len: SizeUInt): PtrInt;
var p: PByte; i: SizeUInt;
begin
  if (len = 0) or (hay = nil) then Exit(-1);
  p := PByte(hay);
  i := 0;
  while i < len do
  begin
    if p[i] = Ord(#10) then Exit(PtrInt(i));              // '\n'
    if (p[i] = Ord(#13)) then                              // '\r'
    begin
      if (i+1 < len) and (p[i+1] = Ord(#10)) then Exit(PtrInt(i)); // '\r\n'
      // 独立的 '\r'，视为行结束也可返回 i，这里保持严格 CRLF：跳过
    end;
    Inc(i);
  end;
  Result := -1;
end;

// 标量：查找第一个不属于 set 的字节位置
function FindFirstNotOf_Scalar(hay: Pointer; len: SizeUInt; setPtr: Pointer; setLen: SizeUInt): PtrInt;
var p, s: PByte; i, j: SizeUInt; found: Boolean;
begin
  if (len = 0) or (hay = nil) then Exit(-1);
  if (setLen = 0) or (setPtr = nil) then Exit(0); // 空集合：第一个字节即不属于
  p := PByte(hay); s := PByte(setPtr);
  for i := 0 to len-1 do
  begin
    found := False;
    for j := 0 to setLen-1 do
      if p[i] = s[j] then begin found := True; Break; end;
    if not found then Exit(PtrInt(i));
  end;
  Result := -1;
end;

// 标量：StartsWith（完整前缀比较）
function StartsWith_Scalar(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): Boolean;
begin
  if nlen = 0 then Exit(True);
  if (ned = nil) or (nlen > len) or (hay = nil) then Exit(False);
  Result := CompareByte(PByte(hay)^, PByte(ned)^, nlen) = 0;
end;

// 标量：StartsWithI（ASCII 忽略大小写）
function StartsWithI_Scalar(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): Boolean;
begin
  if nlen = 0 then Exit(True);
  if (ned = nil) or (nlen > len) or (hay = nil) then Exit(False);
  Result := AsciiEqualIgnoreCase_Scalar(PByte(hay), PByte(ned), nlen);
end;




{$ENDIF}

end.

