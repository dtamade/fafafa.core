# Backlog: fafafa.core 长期迭代维护

> 目标：把“长期维护工作”可视化、可迭代、可回溯。  
> 规则：每轮迭代只做 1–3 个条目；其余留在 backlog（避免 WIP 过多）。

## 工作方式（planning-with-files）
- 选题：从本 backlog 选 1–3 项 → 写入仓库根的 `task_plan.md`
- 过程：发现/结论 → `findings.md`；命令/输出/测试结果 → `progress.md`
- 收尾：将三文件归档到 `plans/archive/YYYY-MM-DD-<topic>/`，并在本条目下补归档链接

## Now（进行中）
- [ ] **P0 / layer0+layer1+layer2 自主维护推进**：建立“每轮自主发现 1 个任务 + 完成 1 个子任务”的连续闭环机制（不中断）  
  进度：batch1 已完成“脚本入口规范化 + Layer2 首轮失败矩阵”；batch2 已完成“process/socket 编译阻断修复与回归路径打通”（`process` 编译通过，`socket` 编译通过）；当前状态：`yaml PASS`，`toml/xml` 仍为断言失败，`socket` 在本沙箱因禁网触发运行期失败。
- [ ] **P0 / sync**：继续 Layer1 验证：修复 `Condvar` / `Barrier` / `Once` / `Spin` 并补回归  
  进度：`tests/fafafa.core.sync` 在 `FAFAFA_FORCE_NAMED_SYNC_TESTS=1` 下全链路 `46/46 PASS`；`parkinglot` 性能断言抗抖已加；`named*` 在 `/dev/shm` 不可写环境自动 `SKIP`（可强制运行）
- [ ] **P1 / repo**：梳理并最小化“运行产物进入版本库”的风险（例如已跟踪的 logs/reports）  
  进度：已完成八批清理，累计去追踪 **601** 项（`tests/` 67 + `examples/` 147 + `bin/` 2 + `reference/lockfree-develop` 53 + `reference/xxHash-dev` 89 + `reference/DCPcrypt` 92 + `reference/tomlc99-master` 151），并补充 `.gitignore` 防回潮

## Next（下一步）
- [ ] **P0 / layer0+layer1+layer2 自主维护推进（batch3）**：按“公共根因优先”拆解 `toml` 断言失败并做最小修复
- [ ] **P0 / layer0+layer1+layer2 自主维护推进（batch4）**：按 writer/reader/stream-chunk 分组拆解 `xml` 断言失败
- [ ] **P0 / layer0+layer1+layer2 自主维护推进（batch5）**：将 `socket` 测试拆分为“编译验证 + 受限环境运行基线”两套口径
- [ ] **P0 / simd (deep-clean) follow-up**：在已完成两轮收敛基础上，推进 P1/P2（256-bit 类型/测试、NEON/RVV 覆盖、intrinsics 文档）  
  参考：`plans/archive/2026-02-06-layer0-layer1-simd-deep-clean/`
- [ ] **P0 / layer0+layer1 (sweep) follow-up**：将 sweep 从 Linux 基线扩展到更多平台条件/模块组合（按失败点拆批）  
  参考：`plans/archive/2026-02-06-layer0-layer1-simd-deep-clean/`

## Icebox（低优先级 / 待定）
- [ ] 维护文档与示例（按模块补齐最小可运行 example 与对应测试）
- [ ] CI 结构化输出（JUnit/JSON）统一化与稳定路径约定落地

## Done（已完成）
- [x] 2026-02-07：layer0/layer1/layer2 自主维护推进 batch1（脚本入口规范化 + Layer2 首轮失败矩阵）（归档：`plans/archive/2026-02-07-layer012-autonomous-maintenance-batch1/`）
- [x] 2026-02-07：layer0/layer1/layer2 自主维护推进 batch2（`process`/`socket` 编译阻断修复；`toml`/`xml` 失败类型分流；受限环境口径确认）（归档：`plans/archive/2026-02-07-layer012-autonomous-maintenance-batch2/`）
- [x] 2026-02-06：`run_all_tests` runner 改进 + FS/SIMD 0 warnings/hints 回归 + 关键模块回归（归档：`plans/archive/2026-02-06-fafafa-core/`）
- [x] 2026-02-06：Layer0/Layer1 基线梳理 + SIMD DoD + 过期引用/脚本收敛 + 回归验证（归档：`plans/archive/2026-02-06-layer0-layer1-simd/`）
- [x] 2026-02-06：Layer0/Layer1 sweep + SIMD deep-clean 第一批闭环（thread/threadpool/parkinglot 修复 + Layer0/1 Linux 基线回归）（归档：`plans/archive/2026-02-06-layer0-layer1-simd-deep-clean/`）
- [x] 2026-02-06：sync follow-up + repo hygiene 第一批（NamedEvent 受限环境稳健性修复 + `tests/` 日志产物去追踪 58 项）（归档：`plans/archive/2026-02-06-sync-repo-hygiene-batch1/`）
- [x] 2026-02-06：repo hygiene 第二批（`tests/fafafa.core.crypto/reports` XML/TXT 产物去追踪 9 项，累计 67 项）（归档：`plans/archive/2026-02-06-sync-repo-hygiene-batch2/`）
- [x] 2026-02-06：sync + repo hygiene 第三批（`sync` 聚合 46/46 PASS；`parkinglot` 性能断言稳健化；`named*` 受限环境脚本级 SKIP；`examples/` 运行产物去追踪 147 项，累计 214 项）（归档：`plans/archive/2026-02-06-sync-repo-hygiene-batch3/`）
- [x] 2026-02-07：sync + repo hygiene 第四批（`FAFAFA_FORCE_NAMED_SYNC_TESTS=1` 下 `sync` 全链路 46/46 PASS；root `bin/` 运行产物去追踪 2 项，累计 216 项）（归档：`plans/archive/2026-02-07-sync-repo-hygiene-batch4/`）
- [x] 2026-02-07：repo hygiene 第五批（`reference/lockfree-develop` 去追踪 53 项；全仓 ignored-but-tracked 从 3051 降至 2996；累计 269 项）（归档：`plans/archive/2026-02-07-sync-repo-hygiene-batch5/`）
- [x] 2026-02-07：repo hygiene 第六批（`reference/xxHash-dev` 去追踪 89 项；全仓 ignored-but-tracked 从 2996 降至 2907；累计 358 项）（归档：`plans/archive/2026-02-07-sync-repo-hygiene-batch6/`）
- [x] 2026-02-07：repo hygiene 第七批（`reference/DCPcrypt` 去追踪 92 项；全仓 ignored-but-tracked 从 2907 降至 2815；累计 450 项）（归档：`plans/archive/2026-02-07-sync-repo-hygiene-batch7/`）
- [x] 2026-02-07：repo hygiene 第八批（`reference/tomlc99-master` 去追踪 151 项；全仓 ignored-but-tracked 从 2815 降至 2664；累计 601 项）（归档：`plans/archive/2026-02-07-sync-repo-hygiene-batch8/`）

## SIMD Autonomous Program Board（长期）

### Done
- [x] **SIMD-B01**：AVX2 缺失实现补齐（已完成）
- [x] **SIMD-B02**：AVX2 边界覆盖第一轮（scale/负索引/掩码/imm8）
- [x] **SIMD-B03**：`gather_epi64` / `gather_pd` 负索引与参数防御测试补齐

### Queue
- [ ] **SIMD-B07**：Windows `.bat` 执行证据补齐

### SIMD Program Board Update (2026-02-07 06:10)
- [x] **SIMD-B04**：pack/unpack 极值组合与 lane 隔离测试补齐（已完成）。
- [ ] **SIMD-B05**：cpuinfo runner 参数矩阵回归（当前 active）。

### SIMD Program Board Update (2026-02-07 06:15)
- [x] **SIMD-B05**：cpuinfo runner 参数矩阵回归与兼容修复（已完成）。
- [ ] **SIMD-B06**：SIMD 文档与测试清单一致性校对（当前 active）。

### SIMD Program Board Update (2026-02-07 06:19)
- [x] **SIMD-B06**：SIMD 文档与测试清单一致性回补（已完成）。
- [ ] **SIMD-B07**：Windows `.bat` 执行证据补齐（当前 active，需 Windows 环境实跑）。

### SIMD Program Board Update (2026-02-07 06:22)
- [~] **SIMD-B07**：已完成脚本口径统一与 Linux 侧回归；剩余 Windows 实机执行证据。

### SIMD Program Board Update (2026-02-07 06:32)
- [x] **SIMD-B08**：SIMD 主入口 suite 清单一致性守护（已完成）。
- [~] **SIMD-B07**：Windows `.bat` 执行证据补齐（剩余 Windows 实机验证）。
- [ ] **SIMD-B09**：NEON/RVV 可移植 smoke 口径建立（当前 active）。

### SIMD Program Board Update (2026-02-07 06:35)
- [x] **SIMD-B09**：NEON/RVV 可移植 smoke 口径建立（已完成）。
- [ ] **SIMD-B10**：SIMD 固化回归门禁脚本与 DoD（当前 active）。
- [~] **SIMD-B07**：Windows `.bat` 执行证据补齐（待 Windows 环境实跑）。

### SIMD Program Board Update (2026-02-07 06:46)
- [x] **SIMD-B10**：SIMD 固化回归门禁脚本与 DoD（已完成，`gate` 6/6 PASS）。
- [~] **SIMD-B07**：Windows `.bat` 执行证据补齐（唯一剩余项，待 Windows 环境实跑）。

### SIMD Program Board Update (2026-02-07 06:56)
- [~] **SIMD-B07**：`.bat` runner 已完成与 Linux gate 口径对齐（含 `check/gate`），待 Windows 实机日志证据完成闭环。
- [~] **SIMD-B07**：已补 `collect_windows_b07_evidence.bat` 一键收证脚本；待在 Windows 执行并归档日志。

### SIMD Program Board Update (2026-02-07 07:28)
- [~] **SIMD-B07**：已在 Linux gate 中加入 `.bat` 关键签名静态校验，防止 Windows runner 漂移；剩余项仅为 Windows 实机证据采集。

### SIMD Program Board Update (2026-02-07 07:37)
- [~] **SIMD-B07**：已补证据校验器 `verify_windows_b07_evidence.sh` 并接入 gate 可选分支；剩余项仅为生成并验证 Windows 实机日志。

### SIMD Program Board Update (2026-02-07 07:43)
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。
- [x] **SIMD-B11(candidate)**：补 `avx2_setzero_si256` 专项回归测试并通过 gate 全链路。

### SIMD Program Board Update (2026-02-07 08:06)
- [~] **SIMD-B07**：`check` 分支已对齐 parity 校验，B07 守护覆盖面进一步收紧；剩余项仍仅为 Windows 实机日志证据。

### SIMD Program Board Update (2026-02-07 08:33)
- [~] **SIMD-B07**：文档回归口径已对齐（含 `check/gate`、Windows 证据采集/校验与无日志 `SKIP` 语义）；剩余项仍仅为 Windows 实机日志证据。

### SIMD Program Board Update (2026-02-07 08:43)
- [~] **SIMD-B07**：Linux runner 已补 `Invalid option` 防线，与 Windows runner 参数防御口径对齐；剩余项仍仅为 Windows 实机日志证据。

### SIMD Program Board Update (2026-02-07 08:49)
- [~] **SIMD-B07**：已补 cpuinfo Linux runner parity 静态守护（含 `--list-suites` 转译/`Invalid option`/heap leak 关键签名），剩余项仍仅为 Windows 实机日志证据。

### SIMD Program Board Update (2026-02-07 08:57)
- [x] **SIMD-B12(candidate)**：新增变量移位语义测试（count 边界 + 符号行为），并通过 gate 全链路。
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。

### SIMD Program Board Update (2026-02-07 09:12)
- [x] **SIMD-B13(candidate)**：新增 `gather_epi64/gather_pd` 多 scale 语义测试，并通过 gate 全链路。
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。

### Done (SIMD 增量)
- [x] 2026-02-07：**SIMD-B10** 完成（`tests/fafafa.core.simd/BuildOrTest.sh gate` 门禁收敛，修复 `avx2_setzero_si256` 初始化 hint，6/6 通过）。

### SIMD Program Board Update (2026-02-07 09:23)
- [x] **SIMD-B14(candidate)**：`cpuinfo.x86` Linux runner parity 静态守护补齐并通过全链路回归。
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。

### SIMD Program Board Update (2026-02-07 09:41)
- [x] **SIMD-B15(candidate)**：AVX2 构造/载入/广播接口语义测试补齐并通过回归。
- [x] **SIMD-B16(candidate)**：benchmark 计时/基线口径修复 + `perf-smoke` 落地。
- [ ] **SIMD-B17(candidate)**：`VecF32x4Dot` 路径性能专项优化（目标 >= 1.00x）。
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。

### SIMD Program Board Update (2026-02-07 10:00)
- [~] **SIMD-B17(candidate)**：`VecF32x4Dot` 性能专项已完成首轮优化并接近持平（约 0.98x），继续收敛到稳定 >=1.00x。

### SIMD Program Board Update (2026-02-07 10:13)
- [~] **SIMD-B17(candidate)**：第二轮完成，`VecF32x4Dot` 提升至约 `0.99x`，继续收敛。
- [ ] **SIMD-B18(candidate)**：Dot 性能评估口径拆分（4-lane 微算子 vs 批量向量），建立双轨 DoD。

### SIMD Program Board Update (2026-02-07 10:38)
- [x] **SIMD-B17(candidate)**：`VecF32x4Dot` 性能专项收敛完成（5 次采样中位数约 `1.01x`，达到稳定 >= `1.00x` 目标）。
- [x] **SIMD-B18(candidate)**：Dot 评估口径拆分完成（`VecF32x4Dot` 微算子 + `VecF32x8DotBatch` 批量吞吐双轨）。
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。
- [ ] **SIMD-B19(candidate)**：`DotF32x8` API 路径专项优化与批量口径对齐（避免 API 与批量吞吐结论偏离）。

### SIMD Program Board Update (2026-02-07 11:19)
- [x] **SIMD-B19(candidate)**：`DotF32x8` API 路径专项优化完成，并与批量口径对齐（API/Batch 均稳定 > `1.00x`）。
- [x] **SIMD-B17(candidate)**：状态保持 completed（`VecF32x4Dot` 持续稳定 >= `1.00x`）。
- [~] **SIMD-B07**：状态不变（仅剩 Windows 实机日志证据）。
- [ ] **SIMD-B20(candidate)**：Windows 证据闭环自动化（日志采集 + Linux 校验 + 归档模板）。
