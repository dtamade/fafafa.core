# fafafa.core.collections.arr

## 模块定位
- 作为“基础顺序存储单元（TArray<T> 封装）”的抽象实现，是更高层 Vec/VecDeque 的基石
- 面向场景：
  - 与外部裸指针/已有内存进行零拷贝交互（按需）
  - 简单的顺序访问、块拷贝、区间读写
  - 作为其他容器的内部缓冲结构

## 设计要点
- 接口优先：实现 IArray<T>/IGenericCollection<T> 的必要成员
- 跨平台：仅依赖 fafafa.core.base/mem.utils/allocator
- 内存策略：
  - 允许通过 TAllocator 注入（池化/对齐/自定义分配）
  - 支持 Resize/OverWrite/Read/Swap/Fill/Zero 等常见操作
- 合同（Unchecked）：所有 `*UnChecked` 方法不做参数与边界检查，调用方保证范围合法

## 关键 API 速览（摘要）
- 读写：
  - Get/Put/GetPtr
  - OverWrite(aIndex; aSrc: Pointer|array of T|Collection; aCount)
  - Read(aIndex; aDst: Pointer|Array|Collection; aCount)
- 结构：
  - Resize/Ensure
  - Swap/Copy/Fill/Zero/Reverse（区间版本与 UnChecked 版本）
- 遍历与查询：ForEach/Contains/Find/FindIF/CountOf/CountIf 等（与 IArray<T> 一致）

提示：完整签名以源码为准（src/fafafa.core.collections.arr.pas），此处仅列出常用类别，避免文档与实现偏差。

## 使用示例（UTF-8）

```pascal
{$CODEPAGE UTF8}
program arr_quickstart;
uses
  fafafa.core.collections.arr, fafafa.core.collections.base;

type
  TIntArr = specialize TArray<Integer>;
var
  A: TIntArr;
begin
  // 创建固定元素数量的数组（Count = 16，使用默认分配器）
  A := TIntArr.Create(16, GetRtlAllocator);
  try
    A.Put(0, 42);
    if A.Get(0) = 42 then ; // OK

    // 批量写入（从静态数组）
    A.OverWrite(1, [1,2,3,4]);

    // 区间反转（有边界检查）
    A.Reverse(1, 4);
  finally
    A.Free;
  end;
end.

## 语义说明：Ensure 与指针重载
- Ensure(aCount): 确保数组的元素数量（Count）至少为 aCount。注意：这是改变 Count 的操作，并非“确保容量”。
- 指针重载注意事项：
  - OverWrite/Read 的指针版本要求指针对齐到元素大小；当源/目的与自身内存重叠时，内部会自动选择安全路径。
  - 传入的外部内存区域必须已分配且足够大；调用方负责其生命周期。
- UnChecked 统一约定（简版）：不做边界/空指针/重叠等检查，仅用于性能敏感且已验证参数合法的路径。详见 docs/UnChecked_Methods_Summary.md。


## 与 Vec/VecDeque 的关系
- Arr 不承诺摊销 O(1) 的 push/pop 语义，偏向“定长/显式 Resize”的简单存储
- Vec 使用可增长策略管理容量；VecDeque 使用环形缓冲与 2 的幂对齐
- 作为内部实现，Arr 注重原地块操作与最少依赖

## 测试建议
- 侧重块语义与边界：OverWrite/Read/Swap/Reverse/Zero 的区间正确性
- UnChecked 契约独立覆盖：构造最小可再现用例，验证性能路径
- 所有测试需：{$CODEPAGE UTF8}，Debug+heaptrc 开启；二进制输出在 tests/<module>/bin

## 性能与最佳实践
- 大块拷贝优先使用 OverWrite/Read（指针或 array of T）
- 如果元素为管理类型（字符串/动态数组/接口），注意初始化与 Finalize 成本
- 与自定义 TAllocator 配合以获得更佳内存局部性与对齐

## 注意事项
- UnChecked 方法仅用于已验证边界的热路径
- 统一从 src/fafafa.core.settings.inc 注入编译宏；禁止内联变量写法

## 参考
- 源码：src/fafafa.core.collections.arr.pas
- UnChecked 契约：docs/UnChecked_Methods_Summary.md
- 增长策略（供 Vec 参考）：src/fafafa.core.collections.base.pas
- Best Practices（策略组合与对齐建议）：docs/partials/collections.best_practices.md

