# fafafa.core.simd 下一步行动计划（历史草案）

> ⚠️ **这是一份历史草案。**
>
> 它保留在仓库里，主要用于追溯早期设计和推进背景；**不要**再把它当作当前 API、当前架构、当前测试入口或当前待办的真相源。
>
> 当前更可信的入口是：
>
> - `src/fafafa.core.simd.README.md`：模块 landing
> - `docs/fafafa.core.simd.md`：模块总览
> - `docs/fafafa.core.simd.api.md`：公开 API 参考
> - `docs/fafafa.core.simd.map.md` / `docs/fafafa.core.simd.maintenance.md` / `docs/fafafa.core.simd.checklist.md`：维护入口
>
> 注意（2026-02-06）：本文件是早期草案，部分内容已过时（例如：SSE2 后端已存在，类型单元已收敛为 `fafafa.core.simd.base`）。
> 当前建议以 `backlog.md` + `task_plan.md/findings.md/progress.md` 为主线，结合审计/回归文档做收敛式修复。
>
> 下文正文基本按历史状态保留，**不会**继续按当前实现逐段同步修订；如果你在后文看到旧 unit 名称、旧目录结构或旧阶段计划，请把它当作历史背景，而不是当前设计结论。

## 🎯 立即行动 (接下来 2 周)

### Phase 1.1: SSE2 后端实现 (优先级: 🔥🔥🔥)

#### 第一步: 创建 SSE2 后端骨架
```pascal
// 创建文件: src/fafafa.core.simd.x86.sse2.pas
unit fafafa.core.simd.x86.sse2;

{$I fafafa.core.settings.inc}
{$IFDEF SIMD_BACKEND_SSE2}

interface
uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// SSE2 内联汇编实现
function SSE2_AddF32x4(const a, b: TVecF32x4): TVecF32x4; inline;
function SSE2_MulF32x4(const a, b: TVecF32x4): TVecF32x4; inline;
// ... 其他函数

procedure RegisterSSE2Backend;

{$ENDIF} // SIMD_BACKEND_SSE2
end.
```

#### 第二步: 实现核心算术运算
```pascal
// 使用 SSE2 内联汇编
function SSE2_AddF32x4(const a, b: TVecF32x4): TVecF32x4;
asm
  {$IFDEF CPUX86_64}
  movups xmm0, [a]      // 加载向量 a
  movups xmm1, [b]      // 加载向量 b  
  addps  xmm0, xmm1     // 向量加法
  movups [Result], xmm0 // 存储结果
  {$ENDIF}
end;
```

#### 第三步: 性能验证
- 创建简单的性能测试
- 对比标量实现的加速比
- 验证结果正确性

### Phase 1.2: 测试框架基础 (优先级: 🔥🔥)

#### 创建基础测试结构
```pascal
// 创建文件: src/fafafa.core.simd.tests.basic.pas
unit fafafa.core.simd.tests.basic;

interface
uses
  fpcunit, testregistry,
  fafafa.core.simd;

type
  TSimdBasicTests = class(TTestCase)
  published
    procedure TestVecF32x4Add;
    procedure TestVecF32x4Mul;
    procedure TestBackendConsistency;
    procedure TestMemoryAlignment;
  end;

implementation
// 实现测试用例...
```

## 📋 详细任务清单

### Week 1: SSE2 基础实现

#### Day 1-2: 项目设置
- [ ] 创建 SSE2 后端文件结构
- [ ] 设置编译条件和平台检测
- [ ] 实现基础的向量加载/存储

#### Day 3-4: 算术运算
- [ ] 实现 Add/Sub/Mul/Div F32x4
- [ ] 添加内联汇编优化
- [ ] 验证与标量实现的一致性

#### Day 5-7: 比较和数学函数
- [ ] 实现比较运算 (CmpEq, CmpLt 等)
- [ ] 实现数学函数 (Abs, Sqrt, Min, Max)
- [ ] 添加聚合运算 (ReduceAdd, ReduceMin/Max)

### Week 2: 测试和优化

#### Day 8-10: 测试框架
- [ ] 创建基础测试套件
- [ ] 实现随机化测试
- [ ] 添加性能基准测试

#### Day 11-12: 优化和调试
- [ ] 性能分析和优化
- [ ] 修复发现的 bug
- [ ] 完善错误处理

#### Day 13-14: 文档和示例
- [ ] 编写 SSE2 后端文档
- [ ] 创建使用示例
- [ ] 更新主文档

## 🛠️ 技术实现细节

### SSE2 内联汇编模板
```pascal
// 算术运算模板
function SSE2_OpF32x4(const a, b: TVecF32x4; op: string): TVecF32x4;
asm
  {$IFDEF CPUX86_64}
  movups xmm0, [a]      // 加载 a
  movups xmm1, [b]      // 加载 b
  // op: addps, subps, mulps, divps
  movups [Result], xmm0 // 存储结果
  {$ELSE}
  // 32位实现或回退到标量
  {$ENDIF}
end;
```

### 性能测试模板
```pascal
procedure BenchmarkOperation(const name: string; op: TSimdOperation);
const
  ITERATIONS = 1000000;
var
  startTime, endTime: QWord;
  a, b, result: TVecF32x4;
begin
  // 预热
  a := VecF32x4Splat(1.5);
  b := VecF32x4Splat(2.5);
  
  // 测量
  startTime := GetTickCount64;
  for i := 1 to ITERATIONS do
    result := op(a, b);
  endTime := GetTickCount64;
  
  WriteLn(Format('%s: %.3f ms', [name, (endTime - startTime)]));
end;
```

### 正确性验证模板
```pascal
procedure VerifyConsistency(const name: string);
var
  a, b: TVecF32x4;
  scalarResult, simdResult: TVecF32x4;
  i: Integer;
begin
  // 生成随机测试数据
  for i := 0 to 3 do
  begin
    a.Data[i] := Random * 100 - 50;
    b.Data[i] := Random * 100 - 50;
  end;
  
  // 强制使用标量后端
  ForceBackend(sbScalar);
  scalarResult := VecF32x4Add(a, b);
  
  // 强制使用 SSE2 后端
  ForceBackend(sbSSE2);
  simdResult := VecF32x4Add(a, b);
  
  // 验证结果一致性
  for i := 0 to 3 do
    Assert(Abs(scalarResult.Data[i] - simdResult.Data[i]) < 1e-6);
end;
```

## 📊 成功标准

### Week 1 目标
- ✅ SSE2 后端能够编译通过
- ✅ 基础算术运算正确实现
- ✅ 与标量实现结果一致
- ✅ 初步性能提升 (>1.5x)

### Week 2 目标
- ✅ 完整的测试覆盖
- ✅ 性能优化完成 (>2x)
- ✅ 文档和示例完善
- ✅ 代码质量达标

## 🚧 潜在风险和应对

### 技术风险
1. **内联汇编兼容性**
   - 风险: 不同编译器版本的汇编语法差异
   - 应对: 提供多个实现版本，运行时检测

2. **性能不达预期**
   - 风险: 实际加速比低于预期
   - 应对: 分析瓶颈，优化内存访问模式

3. **正确性问题**
   - 风险: 浮点精度或边界条件错误
   - 应对: 大量随机测试，边界条件专项测试

### 项目风险
1. **时间估算偏差**
   - 风险: 实现复杂度超出预期
   - 应对: 分阶段交付，优先核心功能

2. **平台兼容性**
   - 风险: 不同平台的行为差异
   - 应对: 多平台并行测试

## 🎯 下一阶段预览

### Phase 1.2: AVX2 后端 (Week 3-4)
- 256位向量支持 (F32x8)
- FMA 指令集成
- Gather 操作实现

### Phase 1.3: ARM NEON 后端 (Week 5-6)
- AArch64 NEON 支持
- ARM 特有优化
- 跨架构一致性验证

这个行动计划将确保 fafafa.core.simd 在接下来的两周内取得实质性进展，为后续的高级功能开发奠定坚实基础。
