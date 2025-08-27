# 核心算法库设计规划

本文档旨在规划 fafafa.collections 框架需要实现的通用算法库, 作为后续开发工作的路线图和设计依据.

---

## 核心算法清单 (按功能与迭代器要求分类)

### 1. 非修改序列操作 (Non-modifying sequence operations)

*这些算法只读取序列, 不修改元素.*

| 算法名称 | 功能描述 | 最低迭代器要求 |
| :--- | :--- | :--- |
| `ForEach` | 对序列中的每个元素执行一个函数。 | **输入 (Input)** |
| `Count` | 计算序列中等于特定值的元素数量。 | **输入 (Input)** |
| `CountIf` | 计算序列中满足特定条件的元素数量。 | **输入 (Input)** |
| `Find` | 查找第一个等于特定值的元素。 | **输入 (Input)** |
| `FindIf` | 查找第一个满足特定条件的元素。 | **输入 (Input)** |
| `FindIfnot` | 查找第一个不满足特定条件的元素。 | **输入 (Input)** |
| `Search` | 在一个序列中查找另一个子序列的第一次出现。 | **向前 (Forward)** |
| `FindEnd` | 在一个序列中查找另一个子序列的最后一次出现。 | **向前 (Forward)** |
| `FindFirstOf` | 在一个序列中查找第一个出现在另一组值中的元素。 | **输入 (Input)** |
| `AdjacentFind` | 查找第一对相等的相邻元素。 | **向前 (Forward)** |
| `Equal` | 判断两个序列是否按元素相等。 | **输入 (Input)** |
| `Mismatch` | 查找两个序列中第一个不匹配的元素对。 | **输入 (Input)** |

### 2. 修改序列操作 (Modifying sequence operations)

*这些算法会修改序列中的元素值或顺序.*

| 算法名称 | 功能描述 | 最低迭代器要求 |
| :--- | :--- | :--- |
| `Copy` | 将一个序列的元素复制到另一个序列。 | **输入 (Input)** -> **输出 (Output)** |
| `CopyIf` | 将一个序列中满足条件的元素复制到另一个序列。 | **输入 (Input)** -> **输出 (Output)** |
| `CopyN` | 复制指定数量的元素。 | **输入 (Input)** -> **输出 (Output)** |
| `CopyBackward` | 反向复制序列（从后往前）。 | **双向 (Bidirectional)** -> **双向 (Bidirectional)** |
| `Move` | 将一个序列的元素“移动”到另一个序列（原序列可能失效）。 | **输入 (Input)** -> **输出 (Output)** |
| `Fill` | 用一个给定的值填充序列。 | **向前 (Forward)** |
| `FillN` | 用一个给定的值填充指定数量的元素。 | **输出 (Output)** |
| `Transform` | 对一个或两个序列的元素应用一个函数，结果存入目标序列。 | **输入 (Input)** -> **输出 (Output)** |
| `Generate` | 用一个生成器函数的结果填充序列。 | **向前 (Forward)** |
| `Remove` | “移除”序列中所有等于特定值的元素（返回新的逻辑末尾）。 | **向前 (Forward)** |
| `RemoveIf` | “移除”序列中所有满足特定条件的元素。 | **向前 (Forward)** |
| `RemoveCopy` | 将一个序列的元素（不含特定值）复制到另一个序列。 | **输入 (Input)** -> **输出 (Output)** |
| `Replace` | 将序列中所有等于某旧值的元素替换为新值。 | **向前 (Forward)** |
| `ReplaceIf` | 将序列中所有满足条件的元素替换为新值。 | **向前 (Forward)** |

### 3. 排序与分区操作 (Sorting and partitioning operations)

*这些算法对序列进行排序或重新组织.*

| 算法名称 | 功能描述 | 最低迭代器要求 |
| :--- | :--- | :--- |
| `Sort` | 对序列进行不稳定排序。 | **随机访问 (Random Access)** |
| `StableSort` | 对序列进行稳定排序。 | **随机访问 (Random Access)** |
| `PartialSort` | 将序列的前 N 个元素排序。 | **随机访问 (Random Access)** |
| `IsSorted` | 检查序列是否有序。 | **向前 (Forward)** |
| `Partition` | 将满足条件的元素移动到序列前半部分。 | **向前 (Forward)** |
| `StablePartition` | 稳定的分区操作。 | **双向 (Bidirectional)** |
| `Reverse` | 反转序列中元素的顺序。 | **双向 (Bidirectional)** |
| `Rotate` | 将序列中的元素向左旋转。 | **向前 (Forward)** |
| `Shuffle` | 随机打乱序列中的元素。 | **随机访问 (Random Access)** |

### 4. 二分查找操作 (Binary search operations)

*这些算法要求序列必须是**已排序**的.*

| 算法名称 | 功能描述 | 最低迭代器要求 |
| :--- | :--- | :--- |
| `BinarySearch` | 检查已排序序列中是否存在某个值。 | **向前 (Forward)** |
| `LowerBound` | 查找第一个不小于给定值的元素。 | **向前 (Forward)** |
| `UpperBound` | 查找第一个大于给定值的元素。 | **向前 (Forward)** |
| `EqualRange` | 同时查找 `LowerBound` 和 `UpperBound`。 | **向前 (Forward)** |

---

## 运筹建议

1.  **迭代器设计**: 从这个清单可以看出, 我们的迭代器设计**必须**能够清晰地区分**向前 (Forward)**、**双向 (Bidirectional)** 和 **随机访问 (Random Access)** 这三个核心等级。这是让算法发挥最大效能的关键。
2.  **MVP (最小可行产品)**: 我们可以先从实现**非修改序列操作**和一部分核心的**修改序列操作**（如 `Copy`, `Fill`, `Transform`）开始。
3.  **性能核心**: `Sort` 算法是重中之重, 它直接决定了我们框架的性能上限, 并且它强制要求我们必须拥有一个高效的**随机访问迭代器**。
