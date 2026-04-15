# fafafa.core.mem 快速入门

这份 quickstart 只保留当前最短上手路径。
如果你只关心 strict L0 allocator contract，请先回 `docs/fafafa.core.l0.foundation.md`、`docs/fafafa.core.l0.roadmap.md` 和 `docs/ARCHITECTURE_LAYERS.md`；本页只负责 mem 域上手导航。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `docs/fafafa.core.mem.md`
5. `docs/fafafa.core.mem.guide.md`
6. `src/fafafa.core.mem.allocator.base.pas`
7. `src/fafafa.core.mem.allocator.foundation.pas`
8. `src/fafafa.core.mem.pas`
9. `tests/fafafa.core.mem/README.md`
10. `examples/fafafa.core.mem/README.md`

## 5 分钟上手

### 1. 先跑当前测试入口

Windows:

```bat
tests\fafafa.core.mem\BuildOrTest.bat test
```

Linux/macOS:

```bash
bash tests/fafafa.core.mem/BuildOrTest.sh
```

说明：

- Windows 脚本当前走 `tests_mem.lpi`。
- Linux/macOS 脚本当前走 `tests_mem_allocator_only.lpi`。

## 2. 跑最小示例

Windows:

```bat
examples\fafafa.core.mem\BuildAndRun.bat release run
```

Linux/macOS:

```bash
./examples/fafafa.core.mem/BuildAndRun.sh release run
```

说明：

- `BuildAndRun.sh` 省略模式参数时默认走 `Debug`。
- `BuildAndRun.bat` 需要显式给出 `debug` 或 `release`。

## 3. 选对入口

- 只要基础分配器和内存操作：`fafafa.core.mem`
- 只要 strict L0 allocator contract：`fafafa.core.mem.allocator.base`
- 还需要最小 concrete backend / convenience facade：`fafafa.core.mem.allocator.foundation`
- 需要兼容 / 扩展 allocator 聚合入口：`fafafa.core.mem.allocator`
- 固定块池：`fafafa.core.mem.memPool`
- 作用域式分配：`fafafa.core.mem.stackPool`
- 多尺寸小对象：`fafafa.core.mem.pool.slab`
- 只读统计：`fafafa.core.mem.stats`
- 接口化补充：`fafafa.core.mem.interfaces`

## 4. 最小示例

```pascal
uses
  fafafa.core.mem,
  fafafa.core.mem.allocator.foundation;

var
  LAllocator: IAllocator;
  LPtr: Pointer;
begin
  LAllocator := GetRtlAllocator;
  LPtr := LAllocator.GetMem(256);
  try
    Fill(LPtr, 256, $33);
  finally
    LAllocator.FreeMem(LPtr);
  end;
end;
```

说明：

- 示例里用 `foundation` 是为了直接拿到 `GetRtlAllocator`。
- 该接口的 strict L0 contract 仍以 `src/fafafa.core.mem.allocator.base.pas` 为准。

## 下一步

- 想看推荐用法：`docs/fafafa.core.mem.guide.md`
- 想看架构和边界：`docs/fafafa.core.mem.architecture.md`
- 想看 allocator contract + 低层 facade 测试入口：`tests/fafafa.core.mem.allocator.foundation/README.md`
- 想看历史材料：`docs/mem/README.md`
