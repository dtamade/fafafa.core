unit fafafa.core.simd.bitset;

{$mode objfpc}{$H+}
{$IFDEF CPUX86_64}{$asmmode intel}{$ENDIF}
{$ifdef FAFAFA_SIMD_NO_ASM}
  {$define DISABLE_X86_ASM}
{$endif}


interface

function BitsetPopCount_Scalar(p: Pointer; bitLen: SizeUInt): SizeUInt;
{$IFDEF CPUX86_64}
function BitsetPopCount_Popcnt(p: Pointer; bitLen: SizeUInt): SizeUInt; // 64-bit POPCNT 快路径
{$ENDIF}

implementation

function BitsetPopCount_Scalar(p: Pointer; bitLen: SizeUInt): SizeUInt;
var
  i, byteLen: SizeUInt;
  pb: PByte;
  v: Byte;
  count: SizeUInt;
const
  // 预计算 0..255 的 bitcount 表
  LUT: array[0..255] of Byte = (
    0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8
  );
begin
  byteLen := (bitLen + 7) div 8;
  pb := PByte(p);
  count := 0;
  for i := 0 to byteLen-1 do
  begin
    v := pb[i];
    if (i = byteLen-1) and (bitLen mod 8 <> 0) then
      v := v and (Byte($FF) shr (8 - (bitLen mod 8)));
    Inc(count, LUT[v]);
  end;
  Result := count;
end;

{$IFDEF CPUX86_64}
function BitsetPopCount_Popcnt(p: Pointer; bitLen: SizeUInt): SizeUInt;
var
  qCount, byteLen, remBytes: SizeUInt;
  tailBits: SizeUInt;
  i: SizeUInt;
  acc: UInt64;
  ptr: PByte;
  t: QWord;
  b: Byte;
  tmp: QWord;
begin
  acc := 0;
  byteLen := bitLen div 8;
  tailBits := bitLen and 7;
  ptr := PByte(p);

  // 处理完整 8 字节块
  qCount := byteLen div 8;
  for i := 0 to qCount-1 do
  begin
    t := PQWord(ptr)^;
    {$IFNDEF DISABLE_X86_ASM}
    asm
      mov     rax, t
      popcnt  rax, rax
      mov     tmp, rax
    end;
    acc := acc + tmp;
    {$ELSE}
    acc := acc + {%H-}PopCnt(QWord(PQWord(ptr)^));
    {$ENDIF}
    Inc(ptr, 8);
  end;

  // 处理余下不足 8 的完整字节（0..7）
  remBytes := byteLen and 7;
  if remBytes <> 0 then
  begin
    t := 0;
    for i := 0 to remBytes-1 do
      t := t or (QWord(ptr[i]) shl (i*8));
    {$IFNDEF DISABLE_X86_ASM}
    asm
      mov     rax, t
      popcnt  rax, rax
      mov     tmp, rax
    end;
    acc := acc + tmp;
    {$ELSE}
    acc := acc + {%H-}PopCnt(t);
    {$ENDIF}
    Inc(ptr, remBytes);
  end;

  // 处理最后不足 8 的尾部位
  if tailBits <> 0 then
  begin
    b := ptr^ and (Byte($FF) shr (8 - tailBits));
    {$IFNDEF DISABLE_X86_ASM}
    asm
      movzx   rax, b
      popcnt  rax, rax
      mov     tmp, rax
    end;
    acc := acc + tmp;
    {$ELSE}
    acc := acc + {%H-}PopCnt(b);
    {$ENDIF}
  end;

  Result := acc;
end;
{$ENDIF}

end.

