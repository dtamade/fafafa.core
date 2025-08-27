# Walk/Scandir 轻量性能优化计划（规划文档，无实现）

目的：在不改变对外行为的前提下，提出 Walk/Scandir 的轻量优化思路，后续解冻时择机实施。

## 现状观察（从代码与现有 perf）
- 高层 Walk 使用 fs_scandir_each 包装；已具备：
  - 复用目录的已知 Stat（InternalWalkEx aHasStat=true 时）
  - 稳定排序（可带来一定开销）
  - PreFilter（无 stat）/PostFilter（有 stat）分层
- 现有 perf（基线）：顺序读写与随机读；遍历非主项

## 热点猜测
- 目录项枚举 + 额外分配（TStringList/封装器）
- 对目录项的重复 stat（非必要时可避免）
- Windows 下 FindFirstFileEx 可选 flags 未充分利用
- 字符串拼接与 Normalize/Resolve 次数

## 轻量优化思路（不改契约）
1) Scandir 流水式回调（扩散至 Walk）：
   - 优先使用 fs_scandir_each 直通回调，避免中间集合（现已使用，巩固该路径）

2) 目录 stat 复用（已具备，扩展到子分支）：
   - 当父目录条目类型已知为目录且 aHasStat=True，可在递归时传递已知 stat，避免对目录的二次 lstat

3) Windows: FindFirstFileEx 优化：
   - Flag: FIND_FIRST_EX_LARGE_FETCH 以减少系统调用次数（Win7+）
   - 避免请求不必要的额外信息

4) 分配与字符串：
   - 预分配小缓冲区避免频繁扩容
   - AppendPath 走堆栈短缓冲（ShortString / 堆栈数组 + SetString）
   - 仅在需要 normalize 的边界路径调用 Normalize

5) 过滤下沉：
   - 将 PreFilter 放在 scandir_each 内层，最大程度减少后续开销

## 验收与风险
- 验收：perf 基准在相同数据集下 ≥ baseline 的 95%，无回归
- 风险：排序稳定性 vs 性能；Dirent 类型在不同平台的取值差异

## 计划
- P0：在不动 Walk 契约的前提下，审视 fs_scandir_each 的 flags 使用（Windows），和 stat 传递路径
- P1：仅在本地分支做实验，跑 tests + perf；若全绿且 ≥95% 基线，再提 PR

— 仅规划文档，未做实现改动

