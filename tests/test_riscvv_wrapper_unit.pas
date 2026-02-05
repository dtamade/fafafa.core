unit test_riscvv_wrapper_unit;

{$mode objfpc}{$H+}

// =============================================================
// RISC-V V 正确的 ABI 包装模式演示
// =============================================================
// 这个单元展示了如何正确地将 RVV ASM 与 dispatch 系统集成
//
// 关键发现:
// - function(...): TRecord + nostackframe 在 RISC-V 上 ABI 不确定
// - procedure(const a, b; var r) + nostackframe 工作正常
//   ABI: a0=&a, a1=&b, a2=&r
// - 使用包装函数将 procedure 转换为 function 签名
// =============================================================

interface

uses
  fafafa.core.simd.base;

// 这些函数可以注册到 dispatch table
function RVVAddF32x4(const a, b: TVecF32x4): TVecF32x4;
function RVVSubF32x4(const a, b: TVecF32x4): TVecF32x4;
function RVVMulF32x4(const a, b: TVecF32x4): TVecF32x4;
function RVVDivF32x4(const a, b: TVecF32x4): TVecF32x4;
function RVVAbsF32x4(const a: TVecF32x4): TVecF32x4;
function RVVNegF32x4(const a: TVecF32x4): TVecF32x4;
function RVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;

implementation

// =============================================================
// 内部 ASM Procedures (使用正确的 RISC-V ABI)
// =============================================================

// 双参数: a0=&a, a1=&b, a2=&r
procedure _AddF32x4_ASM(const a, b: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0   // e32, m1, ta, ma
  vle32.v v0, (a0)         // 从 a 加载
  vle32.v v1, (a1)         // 从 b 加载
  vfadd.vv v0, v0, v1      // 加法
  vse32.v v0, (a2)         // 存储到 r
end;

procedure _SubF32x4_ASM(const a, b: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse32.v v0, (a2)
end;

procedure _MulF32x4_ASM(const a, b: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vse32.v v0, (a2)
end;

procedure _DivF32x4_ASM(const a, b: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfdiv.vv v0, v0, v1
  vse32.v v0, (a2)
end;

// 单参数: a0=&a, a1=&r
procedure _AbsF32x4_ASM(const a: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsgnjx.vv v0, v0, v0   // abs = sign xor
  vse32.v v0, (a1)
end;

procedure _NegF32x4_ASM(const a: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsgnjn.vv v0, v0, v0   // neg = sign not
  vse32.v v0, (a1)
end;

// 三参数: a0=&a, a1=&b, a2=&c, a3=&r
procedure _FmaF32x4_ASM(const a, b, c: TVecF32x4; var r: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)        // a
  vle32.v v1, (a1)        // b
  vle32.v v2, (a2)        // c
  vfmacc.vv v2, v0, v1    // c += a*b
  vse32.v v2, (a3)        // 存储到 r
end;

// =============================================================
// 外部包装函数 (符合 dispatch table 签名)
// =============================================================

function RVVAddF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  _AddF32x4_ASM(a, b, Result);
end;

function RVVSubF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  _SubF32x4_ASM(a, b, Result);
end;

function RVVMulF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  _MulF32x4_ASM(a, b, Result);
end;

function RVVDivF32x4(const a, b: TVecF32x4): TVecF32x4;
begin
  _DivF32x4_ASM(a, b, Result);
end;

function RVVAbsF32x4(const a: TVecF32x4): TVecF32x4;
begin
  _AbsF32x4_ASM(a, Result);
end;

function RVVNegF32x4(const a: TVecF32x4): TVecF32x4;
begin
  _NegF32x4_ASM(a, Result);
end;

function RVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
begin
  _FmaF32x4_ASM(a, b, c, Result);
end;

end.
