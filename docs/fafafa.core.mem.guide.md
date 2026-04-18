# fafafa.core.mem 使用指南

这份指南只讲当前还适合直接继承的用法，不再重复历史 closeout、固定性能数字或过时目录结构。

## 当前 source-of-truth

先看：

1. `docs/fafafa.core.mem.md`
2. `src/fafafa.core.mem.pas`
3. `src/fafafa.core.mem.allocator.foundation.pas`
4. `src/fafafa.core.mem.allocator.pas`
5. `src/fafafa.core.mem.memPool.pas`
6. `src/fafafa.core.mem.stackPool.pas`
7. `src/fafafa.core.mem.pool.slab.pas`

## 先选哪一层

### 只需要基础内存操作

用 `fafafa.core.mem`、`fafafa.core.mem.alloc`、`fafafa.core.mem.aligned`。

适合：

- 显式分配 / 释放
- 对齐分配
- `Fill`、`Copy`、`Zero` 这类基础操作

### 需要固定块池

用 `fafafa.core.mem.memPool`。

适合：

- 等大小对象
- 节点池
- 生命周期相对独立的重复分配

### 需要作用域式顺序分配

用 `fafafa.core.mem.stackPool` 和 `fafafa.core.mem.stack_scope_helpers`。

适合：

- 一次性批处理
- 临时解析缓冲
- 明确的 mark / restore 语义

### 需要多尺寸小对象分配

用 `fafafa.core.mem.pool.slab`。

适合：

- 小对象频繁分配 / 释放
- 需要 fallback 大对象路径
- 需要只读统计快照

### 需要并发变体

直接 uses 对应并发或分片子单元：

- `fafafa.core.mem.blockpool.concurrent`
- `fafafa.core.mem.blockpool.sharded`
- `fafafa.core.mem.pool.slab.concurrent`
- `fafafa.core.mem.pool.slab.sharded`

不要把默认的 `TMemPool`、`TStackPool`、`TSlabPool` 误当成通用线程安全实现。

### 需要 strict L0 allocator contract

优先用 `fafafa.core.mem.allocator.foundation`。

适合：

- 只想依赖 allocator contract + minimal backend
- 不希望把 `mimalloc` / `crtAllocator` 之类可选后端带进 strict L0 依赖面
- 为 `base` / `option` / `result` / `atomic` 一类基础模块提供最小 allocator 入口

## 当前推荐用法

### 分配器优先

```pascal
uses
  fafafa.core.mem,
  fafafa.core.mem.allocator.foundation;

var
  LAllocator: IAllocator;
  LPtr: Pointer;
begin
  LAllocator := GetRtlAllocator;
  LPtr := LAllocator.GetMem(1024);
  try
    Fill(LPtr, 1024, $5A);
  finally
    LAllocator.FreeMem(LPtr);
  end;
end;
```

### StackPool 作用域恢复

```pascal
uses
  fafafa.core.mem.stackPool,
  fafafa.core.mem.stack_scope_helpers;

var
  LPool: TStackPool;
  LGuard: TStackScopeGuard;
  LPtr: Pointer;
begin
  LPool := TStackPool.Create(4096);
  try
    LGuard := TStackScopeGuard.Enter(LPool);
    try
      LPtr := LPool.Alloc(256, 16);
      Fill(LPtr, 256, $11);
    finally
      LGuard.Leave;
    end;
  finally
    LPool.Free;
  end;
end;
```

### SlabPool 配合只读统计

```pascal
uses
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.stats;

var
  LPool: TSlabPool;
  LStats: TSlabPoolStats;
  LPtr: Pointer;
begin
  LPool := TSlabPool.Create(4096);
  try
    LPtr := LPool.Alloc(64);
    try
      LStats := GetSlabPoolStats(LPool);
    finally
      LPool.Free(LPtr);
    end;
  finally
    LPool.Free;
  end;
end;
```

## 当前使用约束

- `Destroy`、`Clear`、`Reset` 这类生命周期动作，应在没有并发访问时执行。
- `fafafa.core.mem.interfaces` 当前是补充合同，不应替代对具体类行为的理解。
- `fafafa.core.mem.allocator.foundation` 是 strict L0 入口；如果需要可选后端，再显式使用 `fafafa.core.mem.allocator`。
- `mimalloc` 相关模块属于可选集成，能否启用取决于当前环境和构建配置。
- `mapped` / `shared memory` 相关旧示例仍可用于追背景，但今天的框架边界优先去 `fs` 域理解。

## 当前验证入口

测试入口：

- Windows: `tests\\fafafa.core.mem\\BuildOrTest.bat test`
- Linux/macOS: `bash tests/fafafa.core.mem/BuildOrTest.sh`

示例入口：

- Windows: `examples\\fafafa.core.mem\\BuildAndRun.bat release run`
- Linux/macOS: `./examples/fafafa.core.mem/BuildAndRun.sh release run`

更详细的脚本差异和目录说明，直接看：

- `tests/fafafa.core.mem/README.md`
- `examples/fafafa.core.mem/README.md`
- `docs/mem/guides/directory-structure.md`

## 当前边界

- 这份指南只覆盖当前 still-supported 的入口，不对旧报告中的“全部完成”“100%”“工业级+”做继承性背书。
- 若文档与源码冲突，以源码和当前测试入口为准。
- 若需要追溯旧阶段材料，请改看 `docs/mem/README.md` 下的 reports / legacy。
