# fafafa.core.time.tick 测试报告（修订版）

## 概述

本报告描述 `fafafa.core.time.tick` 当前基于 ITick 接口与工厂函数的测试与构建状况。历史上“记录式 TTick”相关描述已废弃，本报告已纠正并与现状对齐。

## 目录与项目

- 测试目录：`tests/fafafa.core.time.tick/`
  - `fafafa.core.time.tick.test.lpi`
  - `fafafa.core.time.tick.test.lpr`
  - `fafafa.core.time.tick.test.testcase.pas`（统一集中所有用例）
- 产物目录：`bin/$(TargetCPU)-$(TargetOS)/`
- 单元输出：`lib/$(TargetCPU)-$(TargetOS)/`

## 测试用例（ITick）

- 单一测试类：`TTest_Tick_All`
- 用例总数：17（Win64/x86_64 实测）
- 覆盖点：
  - 类型名与可用类型：`GetTickTypeName`、`GetAvailableTickTypes`、`HasHardwareTick`
  - 工厂一致性：`MakeStdTick/MakeHDTick/MakeHWTick/MakeBestTick/MakeTick`
  - 单调性与前进性：不同类型的 `Tick()` 进位、单调属性受平台/宏控制
  - 并发健壮性：并行工厂调用、多线程下类型稳定
  - 异常路径：硬件计时器不可用时抛出 `ETickNotAvailable`

实测输出示例（Win64/x86_64）：

```
Time:00.063 N:17 E:0 F:0 I:0
```

备注：Windows 标准计时器（GetTickCount64）分辨率较粗，测试已为其预留 2ms 等待，避免偶发“不前进”误报。

## 实现与宏要点

- 平台实现：
  - Windows：QPC / GetTickCount64（`fafafa.core.time.tick.windows`）
  - Unix/Linux：`CLOCK_MONOTONIC` / `gettimeofday`（`fafafa.core.time.tick.unix`）
  - macOS：`mach_absolute_time` / `mach_timebase_info`（`fafafa.core.time.tick.darwin`）
- 硬件计时器：
  - x86_64/i386：TSC 路径，使用本地最小 CPUID/HasCPUID 实现，去除 `simd.cpuinfo` 依赖；i386 单元命名为 `hardware.i386`
  - AArch64/ARMv7‑A：架构通用计时器（需 `FAFAFA_USE_ARCH_TIMER`）
  - RISC‑V：`time/timeh` 或 `cycle/cycleh`（需 `FAFAFA_CORE_USE_RISCV_*` 宏）

## 构建与运行

- LPI 已配置区分输出：

```xml
<Target>
  <Filename Value="bin/$(TargetCPU)-$(TargetOS)/fafafa.core.time.tick.test"/>
</Target>
<UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>
```

- 本地构建（示例）：

```
lazbuild tests/fafafa.core.time.tick/fafafa.core.time.tick.test.lpi --build-mode=Debug
tests/fafafa.core.time.tick/bin/x86_64-win64/fafafa.core.time.tick.test.exe --all --format=plain
```

- 交叉构建：可用 `build_cross_targets.bat`（按需配置交叉工具链与 sysroot），或直接 `--os/--cpu` 结合 NDK/SDK（Android 属 Unix 路径）。

## 文档与示例

- ITick 用法示例与 Stopwatch 集成请参考：`docs/fafafa.core.time.md`
- 例子：`examples/fafafa.core.time.tick/` 已更新为 `ITick + TStopwatch` 风格

## 更正说明

- 移除所有“记录式 TTick”与其统计；当前实现基于 ITick 接口与工厂方法
- 纠正测试数量与结构（单类 17 项，而非多类 39 项）
- 纠正构建脚本引用：如需批量交叉构建，请用 `build_cross_targets.bat`

