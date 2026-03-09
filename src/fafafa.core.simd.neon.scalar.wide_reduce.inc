// === 256-bit & 512-bit Reduction Operations (NEON ASM) ===

{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}

// --- F32x8 Reduction (256-bit = 2 × F32x4) ---

function NEONReduceAddF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  // a.lo in x0..x1, a.hi in x2..x3
  // Load lo (x0..x1) into v0
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Load hi (x2..x3) into v1
  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Combine lo + hi
  fadd  v0.4s, v0.4s, v1.4s

  // Horizontal sum (pairwise)
  faddp v0.4s, v0.4s, v0.4s
  faddp s0, v0.2s
end;

function NEONReduceMinF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Element-wise min
  fmin  v0.4s, v0.4s, v1.4s

  // Pairwise min reduction
  fminp v0.4s, v0.4s, v0.4s
  fminp s0, v0.2s
end;

function NEONReduceMaxF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmax  v0.4s, v0.4s, v1.4s

  fmaxp v0.4s, v0.4s, v0.4s
  fmaxp s0, v0.2s
end;

function NEONReduceMulF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Multiply lo × hi element-wise
  fmul  v0.4s, v0.4s, v1.4s

  // Extract and multiply lanes
  mov   s1, v0.s[1]
  mov   s2, v0.s[2]
  mov   s3, v0.s[3]
  fmul  s0, s0, s1
  fmul  s0, s0, s2
  fmul  s0, s0, s3
end;

// --- F64x4 Reduction (256-bit = 2 × F64x2) ---

function NEONReduceAddF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  // a.lo in x0..x1, a.hi in x2..x3
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  // Sum all lanes
  fadd  d0, d0, d1
  fadd  d2, d2, d3
  fadd  d0, d0, d2
end;

function NEONReduceMinF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  fmin  d0, d0, d1
  fmin  d2, d2, d3
  fmin  d0, d0, d2
end;

function NEONReduceMaxF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  fmax  d0, d0, d1
  fmax  d2, d2, d3
  fmax  d0, d0, d2
end;

function NEONReduceMulF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  fmul  d0, d0, d1
  fmul  d2, d2, d3
  fmul  d0, d0, d2
end;

// --- F32x16 Reduction (512-bit = 2 × F32x8) ---

function NEONReduceAddF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  // a.lo (F32x8) in x0..x3, a.hi (F32x8) in x4..x7
  // Load lo.lo into v0
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Load lo.hi into v1
  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Load hi.lo into v4
  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  // Load hi.hi into v5
  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  // Combine all 4 F32x4 vectors
  fadd  v0.4s, v0.4s, v1.4s
  fadd  v4.4s, v4.4s, v5.4s
  fadd  v0.4s, v0.4s, v4.4s

  // Horizontal sum
  faddp v0.4s, v0.4s, v0.4s
  faddp s0, v0.2s
end;

function NEONReduceMinF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  fmin  v0.4s, v0.4s, v1.4s
  fmin  v4.4s, v4.4s, v5.4s
  fmin  v0.4s, v0.4s, v4.4s

  fminp v0.4s, v0.4s, v0.4s
  fminp s0, v0.2s
end;

function NEONReduceMaxF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  fmax  v0.4s, v0.4s, v1.4s
  fmax  v4.4s, v4.4s, v5.4s
  fmax  v0.4s, v0.4s, v4.4s

  fmaxp v0.4s, v0.4s, v0.4s
  fmaxp s0, v0.2s
end;

function NEONReduceMulF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  // Multiply all 4 vectors
  fmul  v0.4s, v0.4s, v1.4s
  fmul  v4.4s, v4.4s, v5.4s
  fmul  v0.4s, v0.4s, v4.4s

  // Extract and multiply lanes
  mov   s1, v0.s[1]
  mov   s2, v0.s[2]
  mov   s3, v0.s[3]
  fmul  s0, s0, s1
  fmul  s0, s0, s2
  fmul  s0, s0, s3
end;

// --- F64x8 Reduction (512-bit = 2 × F64x4) ---

function NEONReduceAddF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  // a.lo (F64x4) in x0..x3, a.hi (F64x4) in x4..x7
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  // Sum all 8 lanes
  fadd  d0, d0, d1
  fadd  d2, d2, d3
  fadd  d4, d4, d5
  fadd  d6, d6, d7
  fadd  d0, d0, d2
  fadd  d4, d4, d6
  fadd  d0, d0, d4
end;

function NEONReduceMinF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  fmin  d0, d0, d1
  fmin  d2, d2, d3
  fmin  d4, d4, d5
  fmin  d6, d6, d7
  fmin  d0, d0, d2
  fmin  d4, d4, d6
  fmin  d0, d0, d4
end;

function NEONReduceMaxF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  fmax  d0, d0, d1
  fmax  d2, d2, d3
  fmax  d4, d4, d5
  fmax  d6, d6, d7
  fmax  d0, d0, d2
  fmax  d4, d4, d6
  fmax  d0, d0, d4
end;

function NEONReduceMulF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  fmul  d0, d0, d1
  fmul  d2, d2, d3
  fmul  d4, d4, d5
  fmul  d6, d6, d7
  fmul  d0, d0, d2
  fmul  d4, d4, d6
  fmul  d0, d0, d4
end;

