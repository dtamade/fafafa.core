# fafafa.core.simd 开发计划日志（本轮）

## 今日（T0）
- 建立最小测试工程（FPCUnit + lazbuild 脚本），跑通门面全部公开 API 的冒烟用例（9/9 通过）
- 为确保正确性，暂时将 BytesIndexOf 的 AVX2/SSE2 绑定回退为标量实现

## 待办（T1）
1) 搜索原语 BytesIndexOf 的边界用例矩阵
   - nlen ∈ {1,2,3,4,7,8,15,16,17,31,32,33}
   - 命中位置 ∈ {开头, 中间, 末尾, 不命中}
   - haystack 尺寸 ∈ {64B, 1KB, 64KB}
   - 目标：覆盖所有分支（预检/尾部/中段检查/CompareByte）并形成稳定绑定
2) 修复 SIMD 实现
   - SSE2 路径：补充中段验证策略，确保在 nlen>32 时不误判
   - AVX2 路径：根据 SSE2 策略扩展到 32/64 字节快检，确保 CompareByte 前后的索引一致
3) Text 原语
   - AsciiEqualIgnoreCase_{SSE2,AVX2} 的完备用例（非 ASCII 提前拒绝）
   - Utf8Validate_FastPath 的 NEC（非 ASCII）分支回退验证
4) Bitset
   - POPCNT 绑定路径：在 HasPopcnt=True 时绑定 BitsetPopCount_Popcnt，并补充针对非 8 对齐尾部的测试
5) AArch64/NEON
   - 在 arm64 环境验证 mem/text/search 三类原语的 NEON 绑定

## 🎉 今日重大进展（T0 完成）
### ✅ 访问违例修复（9个→0个）
- 修复 `BitsetPopCount_Popcnt` - 添加边界检查，防止8字节对齐访问越界
- 修复 `BitsetPopCount_Scalar` - 修正 `byteLen = 1` 时的循环边界问题
- 修复 `ToLowerAscii_Scalar` - 添加 `len = 0` 检查
- 修复 `AsciiEqualIgnoreCase_Scalar` - 添加 `len = 0` 检查
- 修复 `ToUpperAscii_Scalar` - 添加 `len = 0` 检查
- 修复 `MemEqual_SSE2` - 修正寄存器冲突问题

### ✅ 新增6个高性能SIMD接口
- `MemCopy` - 高性能内存复制（标量+SSE2+AVX2）
- `MemSet` - 高性能内存填充（标量+SSE2+AVX2）
- `MemReverse` - 内存反转（标量+SSE2）
- `SumBytes` - 字节数组求和（标量+SSE2+AVX2）
- `MinMaxBytes` - 查找最小/最大值（标量+SSE2）
- `CountByte` - 统计特定字节出现次数（标量+SSE2）

### ✅ 测试结果改善
- 总测试数：41（新增6个）
- 通过数：35（85%通过率）
- 错误数：0（所有访问违例已修复）
- 所有新增接口测试全部通过

## 说明
- 按项目规范：先实现+测试，最后统一补文档和基准
- 禁止在库代码输出中文；测试/示例已包含 {$CODEPAGE UTF8}

