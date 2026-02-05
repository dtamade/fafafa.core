# FPC RISC-V V Extension (RVV) 支持报告

## 概述

成功为 Free Pascal Compiler (FPC) 添加了 RISC-V V 向量扩展支持，使得 fafafa.core.simd.riscvv.pas 可以编译为原生 RVV 汇编代码。

## 修改的 FPC 源文件

### 1. `/opt/fpcupdeluxe/fpcsrc/compiler/riscv/cpubase.pas`
- 添加 ~200 个 RVV 指令到 `TAsmOp` 枚举
- 包括向量配置、加载/存储、算术、比较、规约等指令
- 添加伪指令：`vnot.v`, `vfabs.v`, `vfneg.v`, `vmnot.m`, `vmsgt.vv`, `vmsgtu.vv`, `vmfgt.vv`, `vmfge.vv`

### 2. `/opt/fpcupdeluxe/fpcsrc/compiler/riscv/itcpugas.pas`
- 添加所有 RVV 指令的 GAS 字符串映射
- 修改 `gas_op2str` 数组字符串长度从 `string[8]` 到 `string[18]`

### 3. `/opt/fpcupdeluxe/fpcsrc/compiler/riscv/cpuinfo.inc`
- 添加 `CPURV_HAS_V` 标志到 `tcpuflags`

### 4. `/opt/fpcupdeluxe/fpcsrc/compiler/riscv64/cpuinfo.pas`
- 添加 `cpu_rv64gcv` CPU 类型
- 添加相应的能力集

### 5. `/opt/fpcupdeluxe/fpcsrc/compiler/riscv/agrvgas.pas`
- 添加 `'rv64gcv'` 到 `arch_str` 数组

### 6. `/opt/fpcupdeluxe/fpcsrc/compiler/riscv/nrvutil.pas`
- 添加 `_v1p0` 到 ELF attribute 字符串

## fafafa.core.simd.riscvv.pas 修改

### 汇编语法修复

1. **vsetivli 参数格式**：
   - 原：`vsetivli zero, 4, e32, m1, ta, ma`
   - 改：`vsetivli zero, 4, 0xD0`（数值编码）
   - 编码规则：`vtypei = ma[7] | ta[6] | sew[5:3] | lmul[2:0]`

2. **浮点寄存器别名**：
   - `fa0` → `f10`
   - `ft0` → `f0`, `ft1` → `f1`

3. **伪指令替换**：
   - `seq a0, a0, t0` → `xor a0, a0, t0` + `seqz a0, a0`
   - `snez a0, a0` → `sltu a0, zero, a0`

4. **vmerge.vim 掩码修正**：
   - 改用 v0 作为掩码寄存器
   - 使用 `vmerge.vvm` 代替立即数版本

5. **分支指令立即数**：
   - `blt a0, 8, label` → `li t2, 8` + `blt a0, t2, label`

## 编译命令

```bash
# 使用 RVV 支持编译 RISC-V V 后端
/opt/fpcupdeluxe/fpcsrc/compiler/ppcrossrv64_v \
  -CpRV64GCV \
  -XPriscv64-linux-gnu- \
  -dSIMD_BACKEND_RISCVV \
  -Fu/opt/fpcupdeluxe/fpc/lib/fpc/3.3.1/units/riscv64-linux \
  -Fi./src -Fu./src \
  -O3 \
  src/fafafa.core.simd.riscvv.pas
```

## 验证结果

### 生成的目标文件
- 文件：`fafafa.core.simd.riscvv.o` (370KB)
- 格式：ELF 64-bit LSB relocatable, UCB RISC-V, RVC, double-float ABI

### 示例指令输出
```asm
RISCVVADDF32X4:
   vsetivli  zero,4,e32,m1,ta,ma
   vle32.v   v0,(a0)
   vle32.v   v1,(a1)
   vfadd.vv  v0,v0,v1
   vse32.v   v0,(a0)
   ret
```

## 注意事项

1. **实验性支持**：RVV 后端仍处于实验阶段，API 可能变更
2. **FPC 补丁**：需要应用 FPC 补丁才能编译 RVV 代码
3. **运行时检测**：生产环境建议使用 HWCAP 进行运行时检测
4. **签名不兼容**：部分比较函数签名与 dispatch 表不兼容，已注释

## 补丁位置

FPC RVV 补丁：`/home/dtamade/projects/fafafa.core/docs/fpc_rvv_support.patch`

## QEMU 验证结果

### 测试环境
- **QEMU**: 10.0.7 用户模式
- **CPU 配置**: `-cpu rv64,v=true,vlen=128,vext_spec=v1.0`
- **系统根**: `/usr/riscv64-linux-gnu`

### 测试结果汇总

| 测试程序 | 测试数 | 通过 | 状态 |
|----------|--------|------|------|
| test_rvv_minimal | 2 | 2 | ✅ PASS |
| test_rvv_full | 7 | 7 | ✅ PASS |
| test_rvv_comprehensive | 29 | 29 | ✅ PASS |
| test_rvv_wide | 10 | 10 | ✅ PASS |
| **总计** | **48** | **48** | **✅ 100%** |

### 已验证的 RVV 指令

#### 浮点操作 (F32x4, F64x2)
- `vfadd.vv` - 向量浮点加法 ✅
- `vfsub.vv` - 向量浮点减法 ✅
- `vfmul.vv` - 向量浮点乘法 ✅
- `vfdiv.vv` - 向量浮点除法 ✅
- `vfsqrt.v` - 向量浮点平方根 ✅
- `vfmin.vv` - 向量浮点最小值 ✅
- `vfmax.vv` - 向量浮点最大值 ✅
- `vfsgnjn.vv` - 向量浮点取反 ✅
- `vfsgnjx.vv` - 向量浮点绝对值 ✅
- `vfmacc.vv` - 向量浮点 FMA ✅
- `vfredusum.vs` - 向量浮点规约求和 ✅

#### 整数操作 (I32x4, I64x2)
- `vadd.vv` - 向量整数加法 ✅
- `vsub.vv` - 向量整数减法 ✅
- `vmul.vv` - 向量整数乘法 ✅
- `vmin.vv` - 向量整数最小值 ✅
- `vmax.vv` - 向量整数最大值 ✅

#### 位操作
- `vand.vv` - 向量位与 ✅
- `vor.vv` - 向量位或 ✅
- `vxor.vv` - 向量位异或 ✅
- `vsll.vx` - 向量逻辑左移 ✅
- `vsrl.vx` - 向量逻辑右移 ✅

#### 宽向量操作 (LMUL > 1)
- F32x8 (256-bit, LMUL=2) ✅
- I32x8 (256-bit, LMUL=2) ✅
- F32x16 (512-bit, LMUL=4) ✅

#### 配置和加载/存储
- `vsetivli` - 设置向量长度 ✅
- `vle32.v` / `vle64.v` - 向量加载 ✅
- `vse32.v` / `vse64.v` - 向量存储 ✅

## 运行测试

```bash
# 运行所有 RVV 测试
cd /home/dtamade/projects/fafafa.core/tests
bash run_rvv_tests.sh

# 或单独运行
qemu-riscv64 -cpu rv64,v=true,vlen=128,vext_spec=v1.0 \
  -L /usr/riscv64-linux-gnu \
  ./test_rvv_comprehensive
```

## 日期

2026-02-06
