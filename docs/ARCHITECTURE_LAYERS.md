# fafafa.core 架构分层文档

本文档描述 fafafa.core 框架的模块分层架构。分层原则是：**低层模块不依赖高层模块，同层模块间允许依赖**。

## 分层总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Layer 3: Applications                          │
│                         (用户应用层，依赖下层所有模块)                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                              Layer 2: Features                              │
│   crypto, json, process, socket, lockfree, fs, ...                         │
│                         (高级功能模块，依赖 Layer 0/1)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                              Layer 1: Services                              │
│   collections, math, io, time, thread, ...                                 │
│                         (服务模块，依赖 Layer 0)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                              Layer 0: Foundation                            │
│   base, atomic, option, result, mem.allocator, simd                        │
│                         (基础模块，仅依赖 RTL)                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Layer 0: Foundation（基础层）

**原则**: 仅依赖 Free Pascal RTL，不依赖框架内其他模块（同层除外）。

| 模块 | 文件 | 描述 | 依赖 |
|------|------|------|------|
| **base** | `fafafa.core.base.pas` | 基础类型、异常、工具函数 | RTL |
| **atomic** | `fafafa.core.atomic*.pas` | 原子操作、内存屏障 | RTL |
| **option** | `fafafa.core.option*.pas` | Rust 风格 Option<T> 类型 | base |
| **result** | `fafafa.core.result*.pas` | Rust 风格 Result<T,E> 类型 | base |
| **mem.allocator** | `fafafa.core.mem.allocator*.pas` | 内存分配器接口 | base |
| **simd** | `fafafa.core.simd*.pas` (59个文件) | SIMD 向量运算 | atomic, RTL Math |

### Layer 0 依赖图

```
                    ┌─────────┐
                    │   RTL   │
                    └────┬────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌────────┐      ┌────────┐      ┌────────┐
    │  base  │      │ atomic │      │RTL Math│
    └───┬────┘      └───┬────┘      └───┬────┘
        │               │               │
        ▼               │               │
   ┌─────────┐          │               │
   │ option  │          │               │
   │ result  │          │               │
   │mem.alloc│          │               │
   └─────────┘          │               │
                        ▼               │
                   ┌────────┐           │
                   │  simd  │◄──────────┘
                   └────────┘
```

### 测试状态

| 模块 | 测试状态 | 测试数 | 备注 |
|------|----------|--------|------|
| base | ✅ PASS | - | 基础测试 |
| atomic | ✅ PASS | - | 原子操作测试 |
| option | ✅ PASS | 63 | 含契约检查测试 |
| result | ✅ PASS | - | Result 类型测试 |
| simd | ✅ PASS | - | SIMD 后端测试 |

---

## Layer 1: Services（服务层）

**原则**: 可依赖 Layer 0 模块，不依赖 Layer 2。

| 模块 | 文件 | 描述 | 依赖 |
|------|------|------|------|
| **math** | `fafafa.core.math*.pas` | 数学运算、安全整数 | base, simd |
| **collections** | `fafafa.core.collections*.pas` | 集合类型 (Vec, HashMap, VecDeque) | base, mem.allocator |
| **io** | `fafafa.core.io*.pas` | IO 接口和实现 | base |
| **bytes** | `fafafa.core.bytes.pas` | 字节缓冲区操作 | base, io |
| **thread** | `fafafa.core.thread*.pas` | 线程、线程池 | base, atomic, sync |
| **sync** | `fafafa.core.sync*.pas` | 同步原语 (Mutex, RWLock, Barrier, etc.) | base, atomic |
| **time** | `fafafa.core.time*.pas` | 时间、时钟、定时器 | base, thread |

### Layer 1 依赖图

```
Layer 0
   │
   ▼
┌──────────────────────────────────────────────────┐
│                    Layer 1                        │
│                                                   │
│  ┌──────┐    ┌─────────────┐    ┌──────────┐     │
│  │ math │    │ collections │    │    io    │     │
│  └──┬───┘    └──────┬──────┘    └────┬─────┘     │
│     │               │                │           │
│     │               │                ▼           │
│     │               │           ┌────────┐       │
│     │               │           │ bytes  │       │
│     │               │           └────────┘       │
│     │               │                            │
│  ┌──┴───┐    ┌──────┴──────┐    ┌──────────┐    │
│  │ simd │◄───│ sync        │◄───│  thread  │    │
│  └──────┘    └─────────────┘    └────┬─────┘    │
│                                      │          │
│                                      ▼          │
│                                 ┌────────┐      │
│                                 │  time  │      │
│                                 └────────┘      │
└──────────────────────────────────────────────────┘
```

---

## Layer 2: Features（功能层）

**原则**: 可依赖 Layer 0/1 模块。

| 模块 | 文件 | 描述 | 依赖 |
|------|------|------|------|
| **crypto** | `fafafa.core.crypto*.pas` | 密码学 (AES, SHA, ChaCha20, etc.) | base, simd, bytes |
| **json** | `fafafa.core.json*.pas` | JSON 解析/序列化 | base, collections |
| **process** | `fafafa.core.process*.pas` | 进程管理 | base, io, thread |
| **socket** | `fafafa.core.socket*.pas` | 网络套接字 | base, io |
| **fs** | `fafafa.core.fs*.pas` | 文件系统操作 | base, io |
| **lockfree** | `fafafa.core.lockfree*.pas` | 无锁数据结构 | base, atomic, mem |
| **mem** | `fafafa.core.mem*.pas` (除 allocator) | 高级内存管理 | base, mem.allocator, atomic |

---

## 分层规则

### 1. 依赖方向

```
Layer N 只能依赖 Layer N-1, N-2, ... 0
Layer N 不能依赖 Layer N+1, N+2, ...
```

### 2. 同层依赖

同层模块间可以互相依赖，但需避免循环依赖：
- ✅ `math` → `simd` (单向)
- ❌ `math` ↔ `simd` (双向循环)

### 3. RTL 依赖

所有层都可以依赖 Free Pascal RTL：
- `SysUtils`, `Classes`, `Math`, `BaseUnix`, `Windows` 等

### 4. 接口优先

跨层交互优先使用接口（interface）而非具体类型：
- `IAllocator` 替代 `TAllocator`
- `IReader`/`IWriter` 替代具体流类型

---

## 分层变更历史

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-02-05 | simd → Layer 0 | 解耦 simd 与 math 的循环依赖，simd 改用 RTL Math |
| 2026-02-05 | 添加 FAFAFA_CORE_CONTRACTS | 框架控制的契约检查宏 |

---

## 附录：模块文件清单

### Layer 0 文件统计

| 模块 | 文件数 | 代码行数 (约) |
|------|--------|--------------|
| base | 1 | ~1,500 |
| atomic | 3 | ~3,000 |
| option | 2 | ~800 |
| result | 2 | ~600 |
| mem.allocator | 3 | ~1,500 |
| simd | 59 | ~25,000 |
| **合计** | **70** | **~32,400** |

### 解耦修改清单 (2026-02-05)

以下文件中的 `fafafa.core.math` 已替换为 RTL `Math`：

1. `fafafa.core.simd.pas` - 删除无用的 math 引用
2. `fafafa.core.simd.scalar.pas` - Math 替换
3. `fafafa.core.simd.sse2.pas` - Math 替换
4. `fafafa.core.simd.neon.pas` - Math 替换
5. `fafafa.core.simd.utils.pas` - Math 替换
6. `fafafa.core.simd.riscvv.pas` - Math 替换
7. `fafafa.core.simd.intrinsics.avx.pas` - Math 替换
8. `fafafa.core.simd.intrinsics.sse2.pas` - Math 替换
9. `fafafa.core.simd.intrinsics.sse41.pas` - Math 替换
10. `fafafa.core.simd.intrinsics.sse.pas` - Math 替换
11. `fafafa.core.simd.imageproc.pas` - Math 替换
