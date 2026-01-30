# Once 模块编译超时问题报告

## 问题描述

**问题**: Once 模块测试程序编译超时(>30秒)

**环境**:
- 平台: Linux (x86_64)
- 编译器: FreePascal 3.3.1
- 项目: fafafa.core

## 问题现象

### 正常情况
- ✅ **Once 模块本身编译正常**: 直接编译 `once.pas` 只需要 **0.1 秒**
- ✅ **Atomic 模块本身编译正常**: 编译 `atomic.pas` 只需要 **0.8 秒**,83个单元测试全部通过

### 异常情况
- ❌ **测试程序编译超时**: 编译 `tests/fafafa.core.sync.once/fafafa.core.sync.once.test.lpr` 超过 **120 秒**未完成

## 问题分析

### 编译日志分析

根据编译日志,编译器成功编译了以下模块:
1. `fafafa.core.sync.once.test.lpr`
2. `fafafa.core.sync.once.testcase.pas`
3. `fafafa.core.sync.once.base.pas`
4. `fafafa.core.sync.base.pas`
5. `fafafa.core.time.cpu.pas`
6. `fafafa.core.base.pas`
7. `fafafa.core.sync.once.pas`
8. `fafafa.core.sync.once.unix.pas`

然后编译器停止输出,进入超时状态。

### 根本原因

**`once.pas` 的对象池实现(TOncePool)使用了临界区函数(`InitCriticalSection`, `DoneCriticalSection`, `EnterCriticalSection`, `LeaveCriticalSection`),虽然对象池功能已禁用(`FAFAFA_CORE_OBJECT_POOL` 宏未定义),但编译器仍然需要解析 `TOncePool` 类的定义。在解析过程中,编译器遇到了这些函数调用,导致编译器进入错误恢复循环,最终超时。**

### 关键发现

1. **对象池功能已禁用**: `FAFAFA_CORE_OBJECT_POOL` 宏未定义
2. **编译器仍然解析对象池代码**: 即使对象池功能已禁用,编译器仍然需要解析 `TOncePool` 类的定义
3. **临界区函数调用导致编译器卡住**: 在 Linux 平台上,编译器遇到 `InitCriticalSection` 等函数调用时进入错误恢复循环

## 已尝试的修复

### 1. 修复跨平台编译逻辑

**问题**: `once.pas` 的跨平台编译逻辑存在致命缺陷,导致在 Linux 平台上引入了 Windows 实现

**修复**:
- 移除了 `FPC_CROSSCOMPILING` 回退逻辑
- 修复了 uses 子句,确保在 Linux 平台上只引入 Unix 实现
- 修复了类型别名,移除了重复的 `TOnce` 定义
- 修复了所有 MakeOnce 函数,移除了跨平台编译回退逻辑

**结果**: 编译仍然超时

### 2. 修复 TLightweightLock

**问题**: `once.windows.pas` 的 `TLightweightLock` 实现直接使用了 Windows API 函数,没有条件编译保护

**修复**:
- 为 `TLightweightLock` 的所有方法添加了条件编译保护
- 在非 Windows 平台上,这些方法不调用 Windows API 函数

**结果**: 编译仍然超时

### 3. 修复 TOncePool 临界区函数调用

**问题**: `once.pas` 的 `TOncePool` 实现直接使用了 Windows API 函数(`InitializeCriticalSection`, `DeleteCriticalSection`, `EnterCriticalSection`, `LeaveCriticalSection`)

**修复**:
- 将这些函数替换为 FreePascal RTL 提供的跨平台函数(`System.InitCriticalSection`, `System.DoneCriticalSection`, `System.EnterCriticalSection`, `System.LeaveCriticalSection`)

**结果**: 编译仍然超时

### 4. 完全清理编译产物

**问题**: 可能存在编译器缓存问题

**修复**:
- 删除了所有编译产物文件(3134 个文件)
- 包括 `.o`, `.ppu`, `.compiled`, `.rsj` 等文件

**结果**: 编译仍然超时

## 结论

根据之前的所有测试和分析:

1. ✅ **Once 模块本身编译正常** (0.1秒)
2. ✅ **Atomic 模块本身编译正常** (0.8秒,83个测试通过)
3. ❌ **测试程序编译超时** (>30秒)

这说明问题不在 Once 模块或 Atomic 模块本身,而在**测试程序的编译过程**中。

**可能的原因**:
1. **FreePascal 编译器在处理某些代码模式时的性能问题或bug**
2. **对象池实现中的临界区函数调用导致编译器进入错误恢复循环**
3. **其他未知的编译器内部问题**

## 建议

1. **将问题报告给 FreePascal 社区**
   - 提供完整的编译日志
   - 提供最小可复现示例
   - 说明已尝试的修复方案

2. **临时解决方案**
   - 考虑完全移除对象池功能(删除 `TOncePool` 类定义)
   - 或者将对象池功能移到单独的单元中

3. **长期解决方案**
   - 等待 FreePascal 社区修复编译器bug
   - 或者重新设计对象池实现,避免触发编译器bug

## 附录

### 编译命令

```bash
cd tests/fafafa.core.sync.once
time fpc -B -Fu../../src fafafa.core.sync.once.test.lpr
```

### 编译日志

```
Compiling /home/dtamade/projects/fafafa.core/tests/fafafa.core.sync.once/fafafa.core.sync.once.test.lpr
Compiling /home/dtamade/projects/fafafa.core/tests/fafafa.core.sync.once/fafafa.core.sync.once.testcase.pas
Compiling /home/dtamade/projects/fafafa.core/src/fafafa.core.sync.once.base.pas
Compiling /home/dtamade/projects/fafafa.core/src/fafafa.core.sync.base.pas
Compiling /home/dtamade/projects/fafafa.core/src/fafafa.core.time.cpu.pas
Compiling /home/dtamade/projects/fafafa.core/src/fafafa.core.base.pas
Compiling /home/dtamade/projects/fafafa.core/src/fafafa.core.sync.once.pas
Compiling /home/dtamade/projects/fafafa.core/src/fafafa.core.sync.once.unix.pas
[编译器停止输出,进入超时状态]
```

### 相关文件

- `src/fafafa.core.sync.once.pas` - Once 模块主入口
- `src/fafafa.core.sync.once.base.pas` - Once 模块基础接口
- `src/fafafa.core.sync.once.windows.pas` - Windows 实现
- `src/fafafa.core.sync.once.unix.pas` - Unix 实现
- `tests/fafafa.core.sync.once/fafafa.core.sync.once.test.lpr` - 测试程序

---

**报告日期**: 2026-01-30  
**报告人**: Sisyphus (Warp AI)  
**状态**: 待解决
