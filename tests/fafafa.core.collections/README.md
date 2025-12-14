# fafafa.core.collections 测试

## 目录结构

```
tests/fafafa.core.collections/
├── *.pas              # 40 个测试单元 (648 测试用例)
├── tests_collections.lpr   # 主测试项目
├── bin/               # 编译输出
├── lib/               # 编译产物
├── vec/               # Vec 专门回归测试
│   ├── Test_vec_growstrategy_interface_regression.pas
│   ├── Test_vec_hysteresis.pas
│   ├── Test_vec_reserve_overflow_freebuffer.pas
│   └── Test_vec_span.pas
└── vecdeque/          # VecDeque 专门回归测试
    ├── test_strategy_pow2_rounding.pas
    ├── Test_vecdeque_clean.pas
    └── Test_vecdeque_span.pas
```

## 运行测试

```bash
# 构建并运行所有测试
bash BuildOrTest.sh test

# 直接运行已编译的测试
./bin/tests_collections --all --format=plain

# 运行特定测试套件
./bin/tests_collections -s TTestCase_Vec
```

## 测试覆盖

| 测试文件 | 覆盖内容 |
|---------|---------|
| Test_Vec_Full.pas | TVec 完整功能测试 |
| Test_HashMap_Full.pas | THashMap 完整功能测试 |
| Test_TreeMap_Full.pas | TTreeMap 完整功能测试 |
| Test_VecDeque_Full.pas | TVecDeque 完整功能测试 |
| Test_Collections_Boundary.pas | 边界条件测试 |
| Test_Algorithms*.pas | 算法测试 |
| Test_Iterators_Adapters.pas | 迭代器适配器测试 |
| Benchmark_Collections.pas | 性能基准测试 |

## 子目录说明

### vec/
专门的 Vec 回归测试，覆盖：
- 增长策略接口回归
- 滞后行为
- 溢出和内存释放
- Span 操作

### vecdeque/
专门的 VecDeque 回归测试，覆盖：
- Power-of-2 容量策略
- 清理行为
- Span 操作

## 历史遗留测试

旧的独立测试项目已归档到：
`archive/2025-12-collections-tests-legacy/`

---

**最后整理**: 2025-12-13
**测试数量**: 648
**通过率**: 100%
**内存安全**: 0 泄漏
