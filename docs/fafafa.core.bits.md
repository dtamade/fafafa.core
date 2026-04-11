# fafafa.core.bits — 位级基础与对齐 Helper

> 当前 strict L0 边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> `fafafa.core.bits` 属于 strict non-SIMD L0，负责全框架可复用的 bit-level helper，而不是 `math` 域的附属工具。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `src/fafafa.core.bits.pas`
5. `tests/fafafa.core.bits/README.md`
6. `tests/fafafa.core.bits/BuildOrTest.sh`
7. `tests/fafafa.core.bits/BuildOrTest.bat`

## 当前兼容策略

- `fafafa.core.bits` 是当前 bit helper 的定义点。
- `fafafa.core.math.intutil` 继续保留 compat 角色，用于旧调用点平滑迁移，但不再是 strict L0 的 source-of-truth。
- 新代码应优先直接依赖 `fafafa.core.bits`，不要再把这组 helper 当作 `math` 特有语义。

## 目标

- 提供纯 RTL 依赖的整数位级与对齐 helper。
- 给 `layout`、allocator、collections、lockfree 等上层模块提供统一底座。
- 保持 API 小而硬，不掺杂策略层或服务层语义。

## 当前 API

- `DivRoundUp(aValue, aDivisor): SizeUInt`
  - 保持 ceil-div 语义；`aValue = 0` 时返回 `0`
- `IsPowerOfTwo(aValue): Boolean`
  - 判断一个非零值是否为 2 的幂
- `NextPowerOfTwo(aValue): SizeUInt`
  - 返回不小于输入值的下一个 2 的幂；`0 -> 1`
- `AlignUp(aValue, aAlignment): SizeUInt`
  - 按对齐值向上取整
- `AlignDown(aValue, aAlignment): SizeUInt`
  - 按对齐值向下取整
- `IsAligned(aValue, aAlignment): Boolean`
  - 判断值是否满足指定对齐

## 当前边界

- 这里承载的是 bit-level helper，不承载更高层的算术算法、数值函数或容器策略。
- 对齐 helper 默认面向“调用方传入合法对齐值”的低层语义，不负责上层参数策略判断。
- 如果你要看 compat 迁移关系，回 `src/fafafa.core.math.intutil.pas`；如果你要看真实 L0 合同，回本文件和 `src/fafafa.core.bits.pas`。

## 测试

- Linux/macOS：`bash tests/fafafa.core.bits/BuildOrTest.sh test`
- Windows：`tests\\fafafa.core.bits\\BuildOrTest.bat test`
- 当前测试入口会锁定 ceil-div、2 的幂判断、对齐取整与对齐判定语义。
