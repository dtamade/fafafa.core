# fafafa.core.simd 收尾与回归矩阵

这份文档给下一位维护者一个直接可用的结论：**现在模块是什么状态、日常改动该跑什么、发布前该补什么、还有哪些债没收完。**

如果你只想看最短版本：

- 公开 façade 和 ABI 边界可以按 stable surface 理解
- backend 成熟度并不完全相同，`sbRISCVV` 仍按 experimental / 受限成熟度看待
- experimental intrinsics 默认入口链已经隔离
- adapter wiring 现在有更强的自动校验，但还没有走到“自动生成 Pascal 代码”的程度

## 这一轮收了什么

这轮收尾主要完成了 5 组工作：

1. **文档 landing / API 名称纠偏**
   - 统一了 README、模块总览、API 文档的阅读入口
   - 修正了 `VecF32x4LoadAligned` / `VecF32x4StoreAligned` 等公开 façade 名称
   - 把历史草案文档明确标成“不要当真相源”

2. **cpuinfo 测试绿灯语义修正**
   - 把 `AssertTrue(..., True)` 形式的伪 skip 改成显式 skip
   - 避免“没测到”被统计成正常通过

3. **`cpuinfo.x86` 样本驱动测试增强**
   - 新增 vendor / brand / AVX / AVX2 / AVX-512 gating 的样本驱动测试
   - 抽出最小 pure helper seam，降低对当前宿主机的依赖

4. **stable / experimental 边界收口**
   - 明确 stable 的是公开 façade / ABI，而不是“每个 backend 都一样成熟”
   - 明确 `sbRISCVV` 仍是 experimental / 受限成熟度 backend
   - 明确 experimental intrinsics 默认不属于 stable surface

5. **adapter wiring 校验增强**
   - `backend.adapter.map.inc` 现在被明确为 adapter-managed slots 的事实真相源
   - `adapter-sync` 除了校验 `backend.iface <-> backend.adapter`，还会校验：
     - 映射里引用的 slot 是否真实存在于 `TSimdDispatchTable`
     - 这些 slot 是否被 `FillBaseDispatchTable` 覆盖

## 现在可以怎么理解这个模块

先把几个边界分开：

- **稳定面**：`fafafa.core.simd` / `fafafa.core.simd.api` 对外公开的 façade，以及 `TSimdDispatchTable` 这类已明确写进稳定约束的 ABI 边界
- **实现面**：`dispatch`、`cpuinfo`、各 backend 单元、`backend.iface` / `backend.adapter`
- **实验面**：experimental intrinsics，以及 `sbRISCVV` 这类仍在受限成熟度区间的 backend

这意味着：

- 正常使用者可以把公开 API 当作稳定入口
- 维护者不能把“façade stable”误读成“所有 backend 都同样成熟、同样覆盖、同样适合发布级承诺”
- 默认门禁会保护主链路，但不会自动替你证明“所有 experimental 路径都已发布级保证”

## 推荐回归命令矩阵

### Linux / macOS

#### 日常改动

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

这组命令适合：
- 文档同步
- façade 小修
- dispatch / cpuinfo 的局部修改
- backend 小范围修正

#### `cpuinfo` 便携路径

Run:
```bash
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_PlatformSpecific
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_LazyCPUInfo
```

#### `cpuinfo.x86` 样本驱动路径

Run:
```bash
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --suite=TTestCase_SampleDriven
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --suite=TTestCase_Global
```

#### adapter wiring / experimental boundary

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh adapter-sync
bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics
```

#### 发布前 / closeout

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

`gate-strict` 是发布门禁，不是日常快门禁。它会补上更重的 perf / repeat / evidence 路径。

### Windows

#### 日常改动

Run:
```bat
tests\fafafa.core.simd\buildOrTest.bat check
tests\fafafa.core.simd\buildOrTest.bat test --suite=TTestCase_DispatchAPI
tests\fafafa.core.simd\buildOrTest.bat test --suite=TTestCase_DirectDispatch
tests\fafafa.core.simd\buildOrTest.bat gate
```

#### `cpuinfo` 便携路径

Run:
```bat
tests\fafafa.core.simd.cpuinfo\buildOrTest.bat test --suite=TTestCase_PlatformSpecific
tests\fafafa.core.simd.cpuinfo\buildOrTest.bat test --suite=TTestCase_LazyCPUInfo
```

#### `cpuinfo.x86` 样本驱动路径

Run:
```bat
tests\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat test --suite=TTestCase_SampleDriven
tests\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat test --suite=TTestCase_Global
```

#### adapter wiring / experimental boundary

Run:
```bat
tests\fafafa.core.simd\buildOrTest.bat adapter-sync
tests\fafafa.core.simd\buildOrTest.bat experimental-intrinsics
```

#### 发布前 / closeout

Run:
```bat
tests\fafafa.core.simd\buildOrTest.bat gate-strict
```

## 还有哪些债没收完

这些不是“现在坏了”，而是后续最值得继续清理的地方：

1. **`dispatch / adapter` 还没走到真正的单一代码生成**
   - 现在已经有更强 checker
   - 但还没有做到“由一份源自动生成 Pascal 接线代码”

2. **`sbRISCVV` 仍是 experimental / 受限成熟度**
   - 口径已经统一
   - 但成熟度本身并没有因为文档收口而改变

3. **Windows 实机证据仍应继续补**
   - Windows 脚本口径已经对齐
   - 但脚本文案对齐不等于所有 Windows 实机场景都已重新验证

4. **非 x86 / QEMU 证据链仍然是发布前话题**
   - 日常快门禁不会默认把这些重路径都打开
   - closeout 时仍然应该靠 `gate-strict` 和对应 evidence 路径补强

## 维护时最容易踩的坑

- 把 `gate` 当成发布放行的唯一依据
- 把 stable façade 误读成“所有 backend 都同等稳定”
- 在 `backend.adapter.map.inc` 之外重复维护 adapter 映射
- 改了 dispatch slot，却忘了看 adapter-sync / base-fill 覆盖
- 在 `SSE2` 上继续激进物理拆分

## 一句话交接

今天这个模块更像这样：**公开 API 已经比以前更稳定、更可读、更可验证；但 backend 成熟度仍有层次，experimental 路径仍要单独看待。**
