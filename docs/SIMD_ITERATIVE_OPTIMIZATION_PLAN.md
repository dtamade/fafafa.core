# SIMD 真正优化 - 迭代开发计划

> **NOTE (INTERNAL)**：本文档为内部规划记录，内容可能与当前实现不一致。  
> 对外口径请以 `docs/fafafa.core.simd*.md` 与 `src/fafafa.core.simd.STABLE` 为准。

## 目标
将所有后端从 "Dispatch 注册 100%" 提升到 "真正 SIMD 优化 100%"

## 当前状态 (2026-02-05)

| 后端 | ASM 实现 | Scalar 回退 | 真正优化率 | 目标 |
|------|----------|-------------|-----------|------|
| SSE2 | 37 | 多数 | ~20% | 90%+ |
| AVX2 | 395 | 20 | ~95% | 98%+ |
| AVX-512 | 24 | 继承 | ~15% | 80%+ |
| NEON | 117 | 389 | ~25% | 90%+ |
| RISC-V V | 19 | 多数 | ~5% | 70%+ |

## 迭代周期设计

每个迭代周期 (Iteration) 聚焦一个后端的一类操作，确保：
1. 完整的 ASM 实现
2. 单元测试覆盖
3. 性能基准验证

---

## Iteration 1: SSE2 核心操作 ASM 化

### 1.1 F32x4 算术 (8 函数)
- [ ] `SSE2AddF32x4` - addps
- [ ] `SSE2SubF32x4` - subps
- [ ] `SSE2MulF32x4` - mulps
- [ ] `SSE2DivF32x4` - divps
- [ ] `SSE2MinF32x4` - minps
- [ ] `SSE2MaxF32x4` - maxps
- [ ] `SSE2AbsF32x4` - andps (mask)
- [ ] `SSE2SqrtF32x4` - sqrtps

### 1.2 F64x2 算术 (8 函数)
- [ ] `SSE2AddF64x2` - addpd
- [ ] `SSE2SubF64x2` - subpd
- [ ] `SSE2MulF64x2` - mulpd
- [ ] `SSE2DivF64x2` - divpd
- [ ] `SSE2MinF64x2` - minpd
- [ ] `SSE2MaxF64x2` - maxpd
- [ ] `SSE2AbsF64x2` - andpd (mask)
- [ ] `SSE2SqrtF64x2` - sqrtpd

### 1.3 I32x4 算术 (6 函数)
- [ ] `SSE2AddI32x4` - paddd
- [ ] `SSE2SubI32x4` - psubd
- [ ] `SSE2MulI32x4` - 仿真 (SSE2 无 pmulld)
- [ ] `SSE2AndI32x4` - pand
- [ ] `SSE2OrI32x4` - por
- [ ] `SSE2XorI32x4` - pxor

### 1.4 比较操作 (12 函数)
- [ ] `SSE2CmpEqF32x4` - cmpeqps
- [ ] `SSE2CmpLtF32x4` - cmpltps
- [ ] `SSE2CmpLeF32x4` - cmpleps
- [ ] `SSE2CmpEqI32x4` - pcmpeqd
- [ ] `SSE2CmpGtI32x4` - pcmpgtd
- [ ] ... (更多)

**验证**: `bash tests/fafafa.core.simd/BuildOrTest.sh`

---

## Iteration 2: SSE2 扩展操作

### 2.1 Load/Store (8 函数)
- [ ] `SSE2LoadF32x4` - movups
- [ ] `SSE2LoadF32x4Aligned` - movaps
- [ ] `SSE2StoreF32x4` - movups
- [ ] `SSE2StoreF32x4Aligned` - movaps
- [ ] 对应 F64x2, I32x4 版本

### 2.2 Shuffle/Blend (6 函数)
- [ ] `SSE2ShuffleF32x4` - shufps
- [ ] `SSE2ShuffleI32x4` - pshufd
- [ ] `SSE2UnpackLowF32x4` - unpcklps
- [ ] `SSE2UnpackHighF32x4` - unpckhps

### 2.3 规约操作 (8 函数)
- [ ] `SSE2ReduceAddF32x4` - haddps (需 SSE3) 或仿真
- [ ] `SSE2ReduceMinF32x4`
- [ ] `SSE2ReduceMaxF32x4`
- [ ] 对应 F64x2 版本

---

## Iteration 3: SSE2 窄整数类型

### 3.1 I16x8 操作 (16 函数)
- [ ] `SSE2AddI16x8` - paddw
- [ ] `SSE2SubI16x8` - psubw
- [ ] `SSE2MulI16x8` - pmullw
- [ ] `SSE2MinI16x8` - pminsw
- [ ] `SSE2MaxI16x8` - pmaxsw
- [ ] ... (位运算、比较)

### 3.2 I8x16 操作 (11 函数)
- [ ] `SSE2AddI8x16` - paddb
- [ ] `SSE2SubI8x16` - psubb
- [ ] `SSE2MinI8x16` - pminsb (SSE4.1) 或仿真
- [ ] `SSE2MaxI8x16` - pmaxsb (SSE4.1) 或仿真

### 3.3 无符号版本 (U16x8, U8x16)
- 使用 pminu*/pmaxu* 或符号翻转技巧

---

## Iteration 4: AVX-512 核心操作

### 4.1 F32x16 算术 (8 函数)
- [ ] `AVX512AddF32x16` - vaddps zmm
- [ ] `AVX512SubF32x16` - vsubps zmm
- [ ] `AVX512MulF32x16` - vmulps zmm
- [ ] `AVX512DivF32x16` - vdivps zmm
- [ ] `AVX512MinF32x16` - vminps zmm
- [ ] `AVX512MaxF32x16` - vmaxps zmm
- [ ] `AVX512AbsF32x16` - vandps zmm (mask)
- [ ] `AVX512SqrtF32x16` - vsqrtps zmm

### 4.2 F64x8 算术 (8 函数)
- 对应 F64 版本

### 4.3 I32x16 算术 (10 函数)
- [ ] `AVX512AddI32x16` - vpaddd zmm
- [ ] `AVX512SubI32x16` - vpsubd zmm
- [ ] `AVX512MulI32x16` - vpmulld zmm
- [ ] ... (位运算)

### 4.4 Mask 操作 (k 寄存器)
- [ ] `AVX512MaskAnd` - kandd
- [ ] `AVX512MaskOr` - kord
- [ ] `AVX512MaskNot` - knotd
- [ ] `AVX512MaskPopCount` - kpopcntd

---

## Iteration 5: NEON 核心操作

### 5.1 F32x4 算术 (8 函数)
- [ ] `NEONAddF32x4` - fadd v.4s
- [ ] `NEONSubF32x4` - fsub v.4s
- [ ] `NEONMulF32x4` - fmul v.4s
- [ ] `NEONDivF32x4` - fdiv v.4s
- [ ] `NEONMinF32x4` - fmin v.4s
- [ ] `NEONMaxF32x4` - fmax v.4s
- [ ] `NEONAbsF32x4` - fabs v.4s
- [ ] `NEONSqrtF32x4` - fsqrt v.4s

### 5.2 I32x4 算术 (10 函数)
- [ ] `NEONAddI32x4` - add v.4s
- [ ] `NEONSubI32x4` - sub v.4s
- [ ] `NEONMulI32x4` - mul v.4s
- [ ] ... (位运算)

### 5.3 比较和选择 (12 函数)
- [ ] `NEONCmpEqF32x4` - fcmeq v.4s
- [ ] `NEONCmpLtF32x4` - fcmlt v.4s
- [ ] `NEONSelectF32x4` - bsl v.16b

---

## Iteration 6: NEON 256-bit 仿真

### 6.1 F32x8 = 2×F32x4
- [ ] 所有 F32x8 操作使用 2 个 NEON 指令实现
- [ ] 确保正确的内存对齐

### 6.2 I32x8 = 2×I32x4
- [ ] 对应整数版本

---

## Iteration 7-10: RISC-V V 实现

### 挑战
- vsetvli 配置复杂
- 不同 VLEN 的兼容性
- 编译器支持有限

### 策略
- 先实现 VLEN=128 版本
- 使用条件编译处理不同 VLEN

---

## 迭代执行模板

每个迭代执行时：

```
1. 读取本文档对应 Iteration 章节
2. 实现该章节列出的所有函数
3. 每个函数必须:
   - 使用真正的 SIMD 汇编指令
   - 在 RegisterXXXBackend 中注册
   - 有对应的单元测试
4. 运行测试验证
5. 更新本文档标记完成 [x]
6. 如有问题，记录到下一迭代
```

## 验收标准

每个后端达到以下标准视为"真正完成":

| 指标 | 标准 |
|------|------|
| ASM 覆盖率 | ≥90% 的 dispatch 操作有真正 ASM |
| Scalar 回退 | ≤10% |
| 测试通过 | 100% |
| 内存泄漏 | 0 |
| 性能提升 | 相比 Scalar ≥3x |

---

## 当前迭代

**下一个迭代**: Iteration 1 - SSE2 核心操作 ASM 化

**预计迭代次数**: 10-15 次

**每次迭代时间**: 1-2 个会话
