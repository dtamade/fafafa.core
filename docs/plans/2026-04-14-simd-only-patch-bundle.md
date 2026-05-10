# SIMD-only Patch Bundle

> Status: historical baseline.
>
> This document is kept for drift comparison, template reuse, or local design history.
> It is not part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.


**Goal:** 在仓库整体工作区很脏的前提下，把当前 `simd` 收口相关改动整理成可 review、可 stage、可 cherry-pick 的单独 patch bundle，避免下轮又回到“到底哪些文件属于 SIMD 主线”的混乱状态。

**Scope rule:** 这份清单只服务 `simd` 主线；不替代 `closeout.md`，也不把非 SIMD 文件混进来。

---

## Bundle A: 当前 x86 bounded frontier + smoke/closeout 封板最小集

这组是**本轮最小可收口集合**，包含当前 x86 bounded implementation frontier 封板资料，以及把它固化成日常可复跑入口所需的 runner / 文档最小集合：

- `tests/fafafa.core.simd/BuildOrTest.sh`
- `tests/fafafa.core.simd/buildOrTest.bat`
- `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- `docs/fafafa.core.simd.checklist.md`
- `docs/fafafa.core.simd.closeout.md`
- `docs/fafafa.core.simd.implementation-matrix.md`
- `docs/plans/2026-04-14-simd-x86-implementation-frontier.md`
- `docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md`
- `docs/plans/2026-04-14-simd-only-patch-bundle.md`

### Inspect

```bash
git diff -- \
  tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/buildOrTest.bat \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  docs/fafafa.core.simd.checklist.md \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md \
  docs/plans/2026-04-14-simd-x86-implementation-frontier.md \
  docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md \
  docs/plans/2026-04-14-simd-only-patch-bundle.md
```

### Stage

```bash
git add \
  tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/buildOrTest.bat \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  docs/fafafa.core.simd.checklist.md \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md \
  docs/plans/2026-04-14-simd-x86-implementation-frontier.md \
  docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md \
  docs/plans/2026-04-14-simd-only-patch-bundle.md
```

### Verify

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
git diff --check -- \
  tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/buildOrTest.bat \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  docs/fafafa.core.simd.checklist.md \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md \
  docs/plans/2026-04-14-simd-x86-implementation-frontier.md \
  docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md \
  docs/plans/2026-04-14-simd-only-patch-bundle.md
```

### Suggested commit

```bash
git commit -m "simd: add x86 impl smoke and seal bounded frontier"
```

---

## Bundle B: SIMD 主线完整集合

如果要把当前 worktree 内的 **SIMD 主线** 一次性整体抽出来，优先使用下面这些 pathspec，而不是从 `git status` 里人工挑：

```bash
git add -- \
  'src/fafafa.core.simd*' \
  'tests/fafafa.core.simd*' \
  'docs/fafafa.core.simd*' \
  'docs/plans/2026-04-14-simd-*' \
  examples/example_simd_dispatch.pas
```

### Why these paths

- `src/fafafa.core.simd*`：SIMD runtime / backend / facade / register / dataplane 主线
- `tests/fafafa.core.simd*`：runner、checker、DispatchAPI / DataPlane / runtime 证据
- `docs/fafafa.core.simd*`：closeout / checklist / matrix / interface / public ABI 文档
- `docs/plans/2026-04-14-simd-*`：当前 active SIMD 收口计划，不把历史 plan 混进来
- `examples/example_simd_dispatch.pas`：SIMD 入口示例，属于主线辅助材料

---

## 明确排除项

下面这些不要因为“顺手”混进 SIMD bundle：

- `backlog.md`
- `task_plan.md` / `findings.md` / `progress.md`
- 非 SIMD 的 `docs/fafafa.core.*`
- 非 SIMD 的 `src/fafafa.core.*`
- 生成物 / 噪音目录：
  - `tests/fafafa.core.simd/__pycache__/`
  - `tests/fafafa.core.simd/nonx86.optin/`
  - `tests/fafafa.core.simd/logs/`

如果要处理这些，请另开 bundle，不要污染当前 SIMD closeout patch。

---

## 收口准则

- 优先提交 **Bundle A**，因为它最小、证据最集中、review 成本最低。
- 只有在你明确要交付整轮 SIMD 主线时，才扩大到 **Bundle B**。
- 如果 `git diff --stat` 里出现非 SIMD 文件，先回滚 pathspec 选择，不要继续扩大提交面。
