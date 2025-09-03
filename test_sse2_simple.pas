unit test_sse2_simple;

{$mode delphi}
{$asmmode intel}

interface

type
  TM128 = record
    case Integer of
      0: (m128_u64: array[0..1] of UInt64);
      1: (m128_u32: array[0..3] of UInt32);
      2: (m128_u16: array[0..7] of UInt16);
      3: (m128_u8: array[0..15] of UInt8);
      4: (m128_i64: array[0..1] of Int64);
      5: (m128_i32: array[0..3] of Int32);
      6: (m128_i16: array[0..7] of Int16);
      7: (m128_i8: array[0..15] of Int8);
      8: (m128_f32: array[0..3] of Single);
      9: (m128_f64: array[0..1] of Double);
  end;

// 简单的测试函数
function simd_test_load(const Ptr: Pointer): TM128;
function simd_test_add_epi32(const a, b: TM128): TM128;

implementation

function simd_test_load(const Ptr: Pointer): TM128; assembler; nostackframe;
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqa xmm0, [rcx]
  {$ELSE}
    movdqa xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movdqa xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_test_add_epi32(const a, b: TM128): TM128; assembler; nostackframe;
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqa xmm0, [rcx]
    movdqa xmm1, [rdx]
    paddd xmm0, xmm1
  {$ELSE}
    movdqa xmm0, [rdi]
    movdqa xmm1, [rsi]
    paddd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movdqa xmm0, [eax]
    movdqa xmm1, [edx]
    paddd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

end.
