# fafafa.core.collections 覆盖清单（2025-08-18）

目标：梳理 arr/vec/vecDeque 三者公开接口的测试覆盖，标出缺口并制定最小补测集。

## 范畴
- Arr（IArray<T> 基础顺序存储）
- Vec（IVec<T> 动态向量，容量管理）
- VecDeque（IVec<T> + IDeque<T> + IQueue<T>，环形缓冲）

## 现有测试样本（按文件名）
- VecDeque（tests/fafafa.core.collections.vecdeque/）
  - test_countof_simple.pas（CountOf 基础）
  - test_slices_simple.pas（切片基础）
  - test_reverse_simple.pas（Reverse 基础）
  - test_capacity_pushfront_simple.pas（容量+PushFront 基础）
  - test_wrap_batch_simple.pas（环绕+批量）
  - test_findlastif_wraparound_simple.pas（FindLastIF 环绕）
  - test_filter_simple.pas / test_filter_comprehensive.pas（Filter）
  - test_min_max_filter.pas（Min/Max + Filter 组合）
  - test_exception_methods.pas / test_simple_exceptions.pas（异常路径）
  - 以及工程级 Test_vecdeque.pas / Test_vecdeque_span.pas / Test_fafafa_core_collections_vecdeque_clean.pas
- Vec（tests/fafafa.core.collections.vec/）：Test_vec.pas、Test_vec_span.pas（工程级）
- Arr（tests/fafafa.core.collections.arr/）：Test_arr.pas（工程级）

## 按功能域覆盖矩阵（摘要）

- 通用 IArray<T>（三者共享，VecDeque 通过内部数组实现）
  - 读写：Get/Put/OverWrite/Read（基础/区间/UnChecked）
    - 已覆盖：部分（VecDeque 基础用例）
    - 缺口：Write/WriteExact、OverWriteExact、Read 到 Collection/Array 的所有重载组合、UnChecked 契约系统化用例
  - 结构：Resize/Ensure/Swap/Copy/Fill/Zero/Reverse（区间/UnChecked）
    - 已覆盖：Reverse（基础）
    - 缺口：Swap/Copy/Fill/Zero 系列，区间 + UnChecked 组合
  - 遍历/查询：ForEach/Contains/Find/FindIF/FindIFNot/FindLast/CountOf/CountIF
    - 已覆盖：CountOf（VecDeque）、FindLastIF（环绕）
    - 缺口：Contains/Find 系列与 Method/RefFunc 重载、FindIFNot、FindLast/FindLastIFNot 的完整组合
  - 排序/二分/洗牌：IsSorted/BinarySearch/BinarySearchInsert/Sort/SortUnChecked/Shuffle
    - 已覆盖：无（或仅工程级）
    - 缺口：上述全部方法及其比较器（Func/Method/RefFunc）重载

- IVec<T>（Vec、VecDeque）容量管理
  - Get/SetCapacity/GrowStrategy/TryReserve/Reserve/ReserveExact/ShrinkToFit/ShrinkToFitExact/Shrink/Truncate/ResizeExact
    - 已覆盖：部分容量+PushFront 的侧观
    - 缺口：TryReserve/ReserveExact/ShrinkToFitExact/Shrink/Truncate/ResizeExact 的行为与边界测试

- IQueue<T>/IDeque<T>（VecDeque）
  - Push/Enqueue/PushFront/PushBack（多重重载）
  - Pop/Dequeue/Peek/Front/Back/TryGet/TryRemove/SplitOff/Append/Resize(with value)
    - 已覆盖：PushFront/Pop/Peek（基础不系统）；SplitOff/Append/Try* 系列缺失

- VecDeque 专属
  - GetTwoSlices（当前/区间）/PeekRange
    - 已覆盖：基础 GetTwoSlices（需补区间版本、空集、单元素、环绕两段边界）
  - Delete/DeleteSwap、RemoveCopy/Array/Swap 等批量删除与复制系列
    - 缺口：基本缺失
  - MinElement/MaxElement（返回值与索引版本，含比较器重载）
    - 已覆盖：值版部分（min/max）
    - 缺口：索引版 + 比较器重载

## 最小补测建议（优先级从高到低）
1) 容量与增长语义（Vec / VecDeque）
   - TryReserve/ReserveExact/ShrinkToFitExact/Shrink 的边界：小→中→大数据规模；增长策略切换（默认/PowerOfTwo/AlignedWrapper）
2) 零拷贝切片（VecDeque）
   - GetTwoSlices：连续/跨环两段/空/单元素/区间版本
3) UnChecked 契约热路径
   - OverWriteUnChecked/ReadUnChecked/SwapUnChecked/ReverseUnChecked：以 3~5 种典型边界组合验证
4) 排序/二分/有序性
   - IsSorted/Sort（含比较器）/BinarySearch/BinarySearchInsert（区间+UnChecked）
5) Deque/Queue 语义
   - SplitOff/Append/TryGet/TryRemove/Resize(with value) 的功能与边界

## 产出形式与约束
- 每个方法族至少 1~2 条代表性用例（避免测试过度膨胀）
- 测试命名遵循规范：Test_函数名 或 Test_函数名_参数1_参数2
- UTF-8、Debug、heaptrc 开启；输出到 tests/<module>/bin

## 备注
- UnChecked 系列严格遵循 docs/UnChecked_Methods_Summary.md 合同：不做边界检查，调用方保证安全
- 尽量使用小数据规模构造可读、可复现的边界用例；性能基准另行处理

