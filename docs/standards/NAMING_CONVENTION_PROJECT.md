# fafafa.core 项目命名约定

本文档定义 fafafa.core 项目的统一命名约定。

> 本文件位置：`docs/standards/NAMING_CONVENTION_PROJECT.md`

## 设计理念

fafafa.core 采用**混合命名风格**策略，在不同抽象层次使用不同的命名约定：

- **高层 API**：遵循 Pascal/Delphi 传统，使用 PascalCase
- **底层 API**：遵循 C/Rust 风格，使用 snake_case，以保持与标准库的 API 兼容性

这种设计在保持 Pascal 传统的同时，为跨语言开发者提供了熟悉的底层接口。

---

## 命名约定总览

| 类别 | 约定 | 示例 | 适用范围 |
|------|------|------|----------|
| **文件名** | 小写 + 点分隔 | `fafafa.core.collections.hashmap.pas` | 全部 |
| **接口** | PascalCase + `I` 前缀 | `IHashMap`, `IVec`, `IMutex` | 全部 |
| **类** | PascalCase + `T` 前缀 | `THashMap`, `TVec`, `TLazyLock` | 全部 |
| **记录类型** | PascalCase + `T` 前缀 | `TAtomicInt32`, `TBarrierWaitResult` | 全部 |
| **异常** | PascalCase + `E` 前缀 | `ELazyLockError`, `EMutexPoisonError` | 全部 |
| **枚举** | PascalCase + `T` 前缀 | `TLazyState`, `TOnceLockState` | 全部 |
| **枚举值** | 小写前缀 + PascalCase（或 snake_case，取决于模块层级） | `lsUninit`, `olsSet`, `mo_seq_cst` | 全部 |
| **私有字段** | PascalCase + `F` 前缀 | `FValue`, `FState`, `FInitializer` | 全部 |
| **参数** | camelCase + `a` 前缀 | `aKey`, `aValue`, `aInitializer` | 全部 |
| **局部变量** | PascalCase + `L` 前缀 | `LIndex`, `LCount`, `LResult` | 全部 |
| **常量** | UPPER_SNAKE_CASE | `MAX_FORMAT_LENGTH`, `SONYFLAKE_DEFAULT_EPOCH` | 全部 |
| **高层方法** | PascalCase | `GetValue`, `TrySet`, `IsInitialized` | 集合、同步、高层 API |
| **底层方法** | snake_case | `is_lock_free`, `test_and_set`, `clear` | 原子操作、C 绑定、SIMD |
| **全局函数（高层）** | PascalCase | `Test`, `NotifyStart`, `ClearRegisteredTests` | 测试框架、工具函数 |
| **全局函数（底层）** | snake_case | `termui_attr_preset_info`, `posix_spawnp` | 终端 API、POSIX 绑定 |

---

## 详细规范

### 1. 类型命名

#### 1.1 接口（Interface）

**规则**：`I` + PascalCase

```pascal
IHashMap<K,V>
IVec<T>
IMutex
IBarrier
ISynchronizable
```

**理由**：遵循 Delphi/Object Pascal 传统，`I` 前缀清晰标识接口类型。

#### 1.2 类（Class）

**规则**：`T` + PascalCase

```pascal
THashMap<K,V>
TVec<T>
TLazyLock<T>
TMutexGuard<T>
```

**理由**：`T` 前缀是 Pascal 传统，表示"Type"。

#### 1.3 记录类型（Record）

**规则**：`T` + PascalCase

```pascal
TAtomicInt32
TAtomicFlag
TBarrierWaitResult
TDuration
```

**理由**：与类保持一致，使用 `T` 前缀。

#### 1.4 异常（Exception）

**规则**：`E` + PascalCase + 描述性后缀

```pascal
ELazyLockError
ELazyLockPoisoned
EMutexPoisonError
EOnceLockEmpty
```

**理由**：`E` 前缀是 Delphi 传统，表示"Exception"。

#### 1.5 枚举（Enum）

**规则**：
- 枚举类型：`T` + PascalCase
- 枚举值：小写前缀（2-3字母）+ PascalCase（或 snake_case，用于底层/C 风格 API）

```pascal
TLazyState = (
  lsUninit,       // ls = LazyState
  lsInitializing,
  lsInitialized,
  lsPoisoned
);

TOnceLockState = (
  olsUnset,       // ols = OnceLockState
  olsSetting,
  olsSet,
  olsPoisoned
);

memory_order_t = (
  mo_relaxed,     // mo = memory_order
  mo_consume,
  mo_acquire,
  mo_release,
  mo_acq_rel,
  mo_seq_cst
);
```

**理由**：
- 枚举值使用小写前缀避免命名冲突
- 前缀通常是类型名的缩写（2-3个字母）
- 保持可读性的同时提供命名空间隔离

---

### 2. 方法命名

#### 2.1 高层方法（PascalCase）

**适用范围**：
- 集合类型（`TVec`, `THashMap`, `TVecDeque` 等）
- 同步原语（`TMutex`, `TRWLock`, `TBarrier` 等）
- 高层容器（`TLazyLock`, `TOnceLock` 等）
- 业务逻辑 API

**示例**：
```pascal
// 集合操作
function GetValue: T;
function TryGetValue(const aKey: K; out aValue: V): Boolean;
procedure SetValue(const aValue: T);
function IsEmpty: Boolean;
function GetCapacity: SizeUint;

// 同步操作
function Lock: TMutexGuard<T>;
function TryLock: TMutexGuard<T>;
function IsInitialized: Boolean;
function IsPoisoned: Boolean;
procedure ClearPoison;

// 容器操作
function GetOrInit(aInitializer: TInitFunc): T;
function TrySet(const aValue: T): Boolean;
```

**理由**：符合 Pascal/Delphi 传统，对 Pascal 开发者友好。

#### 2.2 底层方法（snake_case）

**适用范围**：
- 原子操作（`fafafa.core.atomic.*`）
- C API 绑定（`fafafa.core.process.unix.inc`）
- SIMD 内联函数（`fafafa.core.simd.intrinsics.*`）
- 终端底层 API（`fafafa.core.term.*`）

**示例**：
```pascal
// 原子操作（模仿 C++ std::atomic）
class function is_lock_free: Boolean;
function test_and_set(aOrder: memory_order_t): Boolean;
procedure clear(aOrder: memory_order_t);
function test(aOrder: memory_order_t): Boolean;

// POSIX API 绑定
function posix_spawnp(var pid: TPid; ...): LongInt;
function posix_spawn_file_actions_init(var actions: Pointer): LongInt;

// SIMD 内联函数
function sse42_cmpestrm(const a: TM128; ...): TM128;
function avx2_add_epi32(const a, b: TM256): TM256;

// 终端 API
function term_is_windows_terminal: Boolean;
function termui_attr_preset_info: TUiAttr;
```

**理由**：
1. **API 兼容性**：与 C++/Rust 标准库保持一致（如 `std::atomic::is_lock_free()`）
2. **跨语言可读性**：熟悉 C/Rust 的开发者能立即理解
3. **语义边界**：snake_case 清晰标识底层/系统级接口

---

### 3. 字段和参数命名

#### 3.1 私有字段

**规则**：`F` + PascalCase

```pascal
private
  FValue: T;
  FState: TLazyState;
  FInitializer: TInit;
  FCapacity: SizeUint;
```

**理由**：`F` 前缀表示"Field"，是 Delphi 传统。

#### 3.2 参数

**规则**：`a` + camelCase

```pascal
	constructor Create(aInitializer: TInit);
	procedure SetValue(const aValue: T);
	function TryGetValue(const aKey: K; out aValue: V): Boolean;
```

**理由**：`a` 前缀表示参数（Argument），避免与字段名冲突；同时与本仓库通用规范保持一致。

---

### 4. 常量命名

**规则**：UPPER_SNAKE_CASE

```pascal
const
  MAX_FORMAT_LENGTH = 256;
  SONYFLAKE_DEFAULT_EPOCH = 1409529600000;
  FNV_OFFSET_BASIS = $811C9DC5;
  JULIAN_DAY_EPOCH = 2440588;
```

**理由**：遵循 C/Pascal 传统，全大写表示编译时常量。

---

### 5. 文件命名

**规则**：小写 + 点分隔

```
fafafa.core.collections.hashmap.pas
fafafa.core.sync.mutex.base.pas
fafafa.core.atomic.base.pas
fafafa.core.sync.barrier.unix.pas
```

**理由**：
- 小写避免跨平台文件系统问题
- 点分隔清晰表达模块层次结构

---

## 命名风格决策矩阵

| 场景 | 使用 PascalCase | 使用 snake_case |
|------|----------------|----------------|
| 集合类方法 | ✅ `GetValue`, `TrySet` | ❌ |
| 同步原语方法 | ✅ `Lock`, `IsPoisoned` | ❌ |
| 原子操作方法 | ❌ | ✅ `is_lock_free`, `test_and_set` |
| C API 绑定 | ❌ | ✅ `posix_spawnp` |
| SIMD 函数 | ❌ | ✅ `sse42_cmpestrm` |
| 终端 API | ❌ | ✅ `term_is_windows_terminal` |
| 测试框架 | ✅ `Test`, `NotifyStart` | ❌ |
| 类型名 | ✅ `THashMap`, `IVec` | ❌ |
| 字段名 | ✅ `FValue`, `FState` | ❌ |
| 参数名 | ✅ `aKey`, `aValue` | ❌ |
| 常量名 | ❌ | ✅ `MAX_LENGTH` |

---

## 特殊模块约定

### fafafa.core.time 模块

时间模块使用特殊的方法前缀约定：

| 前缀 | 用途 | 示例 |
|------|------|------|
| `From*` | 静态工厂方法 | `TDuration.FromMs(1000)` |
| `As*` | 单位转换（同类型） | `duration.AsMs` |
| `To*` | 类型转换或格式化 | `date.ToISO8601` |

详见：[docs/NAMING_CONVENTION.md](./NAMING_CONVENTION.md)

---

## 命名约定的演进

### 历史遗留问题

某些模块可能存在命名不一致的情况，这些是历史原因造成的：

1. **`TTimeOfDay.ToMilliseconds`**：使用 `To*` 而非 `As*`
   - 原因：与 `ToTime`、`ToDuration` 保持一致
   - 状态：保留现状，避免 Breaking Change

### 未来方向

- 新代码严格遵循本文档约定
- 旧代码在重大版本更新时逐步迁移
- 优先保持 API 稳定性，避免不必要的破坏性变更

---

## 常见问题（FAQ）

### Q1: 为什么原子操作使用 snake_case？

**A**: 为了与 C++ `std::atomic` 和 Rust `std::sync::atomic` 保持 API 兼容性。这使得熟悉这些语言的开发者能够无缝迁移知识。

示例对比：
```cpp
// C++
std::atomic<int> counter;
if (counter.is_lock_free()) { ... }

// fafafa.core
var counter: TAtomicInt32;
if TAtomicInt32.is_lock_free() then ...
```

### Q2: 什么时候使用 PascalCase，什么时候使用 snake_case？

**A**: 遵循"抽象层次原则"：
- **高层抽象**（集合、同步、业务逻辑）→ PascalCase
- **底层抽象**（原子操作、系统调用、硬件指令）→ snake_case

### Q3: 为什么不统一为 PascalCase？

**A**: 统一为 PascalCase 会：
1. 破坏与 C++/Rust 标准库的 API 兼容性
2. 降低跨语言开发者的可读性
3. 需要大量重构（影响 `fafafa.core.atomic.*`, `fafafa.core.term.*`, `fafafa.core.simd.*`）

### Q4: 新模块应该使用哪种风格？

**A**: 根据模块性质决定：
- **高层业务逻辑模块**：PascalCase（如新的集合类型、同步原语）
- **底层系统接口模块**：snake_case（如新的 C 绑定、SIMD 指令）

---

## 相关文档

- [docs/NAMING_CONVENTION.md](./NAMING_CONVENTION.md) - 时间模块命名约定
- [CLAUDE.md](../CLAUDE.md) - 项目开发指南
- [docs/BestPractices-Cheatsheet.md](./BestPractices-Cheatsheet.md) - 最佳实践速查表

---

## 变更历史

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-01-19 | 1.0.0 | 初始版本，文档化混合命名风格策略 |

---

**维护者**: fafafaStudio
**最后更新**: 2026-01-19
