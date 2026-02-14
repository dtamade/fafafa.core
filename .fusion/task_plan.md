# SIMD 模块完善任务计划

**目标**: 完善 SIMD 模块，提升综合评分从 77.5% 到 85%+
**创建时间**: 2026-02-14
**执行模式**: Fusion 自主工作流

---

## 任务优先级

### Phase 1: 修复 P0 级文档问题（优先级: 🔥🔥🔥）

#### Task 1.1: 修复文档文件名引用错误
- **状态**: PENDING
- **优先级**: P0
- **描述**: 修复文档中 `fafafa.core.simd.types.pas` 引用为 `fafafa.core.simd.base.pas`
- **影响文件**:
  - `docs/fafafa.core.simd.md`
  - `docs/fafafa.core.simd.api.md`
  - `docs/fafafa.core.simd.cpuinfo.md`
- **验收标准**: 所有文档中不再引用 `simd.types`，改为 `simd.base`

#### Task 1.2: 补充 TSimdBackend 枚举文档
- **状态**: PENDING
- **优先级**: P0
- **描述**: 在文档中补充缺失的后端（SSE3/SSSE3/SSE41/SSE42/RISCVV）
- **影响文件**:
  - `docs/fafafa.core.simd.cpuinfo.md`
- **验收标准**: 文档列出所有 10 个后端

#### Task 1.3: 修复函数名不一致
- **状态**: PENDING
- **优先级**: P0
- **描述**: 统一文档和代码中的函数名（`IsBackendAvailable` vs `IsBackendAvailableOnCPU`）
- **影响文件**:
  - `docs/fafafa.core.simd.cpuinfo.md`
  - 相关示例代码
- **验收标准**: 文档和代码中函数名一致

### Phase 2: 完善 NEON 后端（优先级: 🔥🔥）

#### Task 2.1: 实现 I32x4 位运算
- **状态**: PENDING
- **优先级**: P1
- **描述**: 实现 And/Or/Xor/Not 操作
- **影响文件**:
  - `src/fafafa.core.simd.neon.pas`
- **验收标准**:
  - 实现 4 个位运算操作
  - 添加对应测试用例
  - 测试通过

#### Task 2.2: 实现 F64x2 数学函数
- **状态**: PENDING
- **优先级**: P1
- **描述**: 实现 Sqrt/Min/Max 操作
- **影响文件**:
  - `src/fafafa.core.simd.neon.pas`
- **验收标准**:
  - 实现 3 个数学函数
  - 添加对应测试用例
  - 测试通过

#### Task 2.3: 实现窄整数类型
- **状态**: PENDING
- **优先级**: P1
- **描述**: 实现 I16x8/I8x16/U16x8/U8x16 操作
- **影响文件**:
  - `src/fafafa.core.simd.neon.pas`
- **验收标准**:
  - 实现窄整数类型操作
  - 添加对应测试用例
  - 测试通过

#### Task 2.4: 实现饱和算术
- **状态**: PENDING
- **优先级**: P1
- **描述**: 实现 SatAdd/SatSub 操作
- **影响文件**:
  - `src/fafafa.core.simd.neon.pas`
- **验收标准**:
  - 实现饱和算术操作
  - 添加对应测试用例
  - 测试通过

### Phase 3: 补充缺失 API（优先级: 🔥）

#### Task 3.1: 实现 256-bit 浮点比较
- **状态**: PENDING
- **优先级**: P1
- **描述**: 实现 CmpEqF32x8, CmpLtF32x8, CmpLeF32x8, CmpGtF32x8, CmpGeF32x8
- **影响文件**:
  - `src/fafafa.core.simd.avx2.pas`
- **验收标准**:
  - 实现 5 个比较操作
  - 添加对应测试用例
  - 测试通过

#### Task 3.2: 实现 Select 操作
- **状态**: PENDING
- **优先级**: P1
- **描述**: 实现 SelectI32x4, SelectF32x8, SelectF64x4 操作
- **影响文件**:
  - `src/fafafa.core.simd.pas`
  - `src/fafafa.core.simd.sse2.pas`
  - `src/fafafa.core.simd.avx2.pas`
- **验收标准**:
  - 实现 3 个 Select 操作
  - 添加对应测试用例
  - 测试通过

### Phase 4: 完善文档（优先级: 🔥）

#### Task 4.1: 补充 TCPUInfo 字段文档
- **状态**: PENDING
- **优先级**: P1
- **描述**: 补充 Arch、LogicalCores、PhysicalCores、Cache、RISCV 等字段文档
- **影响文件**:
  - `docs/fafafa.core.simd.cpuinfo.md`
- **验收标准**: 所有 TCPUInfo 字段都有文档说明

#### Task 4.2: 补充 intrinsics 文档
- **状态**: PENDING
- **优先级**: P1
- **描述**: 补充 AVX2、NEON intrinsics 文档
- **影响文件**:
  - `docs/fafafa.core.simd.intrinsics.avx2.md`（需创建）
  - `docs/fafafa.core.simd.intrinsics.neon.md`（需创建）
- **验收标准**: AVX2 和 NEON intrinsics 有完整文档

---

## 执行策略

1. **TDD 流程**: 每个实现任务都遵循 RED → GREEN → REFACTOR 流程
2. **测试优先**: 先写失败测试，再实现功能
3. **增量提交**: 每完成一个任务就提交一次
4. **持续验证**: 每次修改后运行相关测试套件

---

## 成功标准

- [ ] 所有 P0 级文档问题修复
- [ ] NEON 后端覆盖率提升到 70%+
- [ ] 256-bit 浮点比较操作完整实现
- [ ] Select 操作完整实现
- [ ] 文档完整性提升到 9/10
- [ ] 综合审计评分提升到 85%+

---

## 风险与应对

1. **NEON 后端兼容性**: 多平台测试，提供回退方案
2. **时间估算偏差**: 分阶段交付，优先核心功能
3. **测试覆盖率**: 确保每个新功能都有对应测试

---

**下一步**: 开始执行 Task 1.1（修复文档文件名引用错误）
