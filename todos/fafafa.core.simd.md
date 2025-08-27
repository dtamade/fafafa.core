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

## 说明
- 按项目规范：先实现+测试，最后统一补文档和基准
- 禁止在库代码输出中文；测试/示例已包含 {$CODEPAGE UTF8}

