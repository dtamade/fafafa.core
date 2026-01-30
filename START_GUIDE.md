# 启动指南（Layer1 单 Agent）

**阅读时间**: 2 分钟

---

## 快速启动

### Step 1：选定目标模块（建议一次只做一个）

例如：`fafafa.core.atomic` / `fafafa.core.sync.mutex` / `fafafa.core.sync.rwlock`。

### Step 2：阅读关键文档（先对齐规则）

- `docs/layer1/LAYER1_INTERFACE_REVIEW_REPORT.md`（Layer1 问题与接口审查结论）
- `docs/standards/DIRECTORY_STANDARDS.md`、`docs/standards/ENGINEERING_STANDARDS.md`（目录/工程规范）
- `AGENTS.md`（本仓库 Agent 约束）

---

### Step 3：开始开发（只改模块边界内的文件）

```bash
# 1) 编译检查（零 warning/hint 约束见工程规范）
lazbuild -B -vewnhibq <path-to>.lpi

# 2) 单模块测试（优先用 tests/<module>/BuildOrTest.*）
bash tests/fafafa.core.<module>/BuildOrTest.sh

# 3) Layer1 过滤回归（提交前）
STOP_ON_FAIL=1 bash tests/run_all_tests.sh <module...>
```

## 关键原则

1. **按模块边界开发**：尽量不混改多个模块
2. **共享文件少动**：脚本/索引等改动尽量集中处理
3. **先跑脚本再提交**：以 `BuildOrTest.*` / `run_all_tests.*` 结果为准

---

## 完成标准

每个模块在 `workings/` 写一份简短记录：
- 改动的文件列表（路径级别）
- 自检命令与结果（测试/HeapTrc/编译检查）
- 需要后续统一处理的共享文件变更点（如有）

---

**预计节奏**: 逐模块推进 → 过滤回归 → 全量回归

**最后更新**: 2026-01-20
