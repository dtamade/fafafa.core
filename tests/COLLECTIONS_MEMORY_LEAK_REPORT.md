# Collections 内存泄漏验证报告

**生成时间**: 2025年 12月 01日 星期一 10:58:14 CST
**测试工具**: Free Pascal HeapTrc
**编译选项**: `-gh -gl` (启用堆追踪和行号信息)

---

## 📊 执行摘要

| 指标 | 值 |
|------|----|
| 总测试数 | 10 |
| ✅ 通过 | 10 |
| ❌ 失败 | 0 |
| 通过率 | 100% |

**结论**: ✅ 所有测试通过，无内存泄漏

---

## 📋 测试结果详情

### test_vec_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_vec_leak"
72 memory blocks allocated : 21537
72 memory blocks freed     : 21537
0 unfreed memory blocks : 0
True heap size : 65536
True free heap : 65536
```

---

### test_vecdeque_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_vecdeque_leak"
196 memory blocks allocated : 21651
196 memory blocks freed     : 21651
0 unfreed memory blocks : 0
True heap size : 131072
True free heap : 131072
```

---

### test_list_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_list_leak"
1081 memory blocks allocated : 26198
1081 memory blocks freed     : 26198
0 unfreed memory blocks : 0
True heap size : 196608
True free heap : 196608
```

---

### test_hashmap_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_hashmap_leak"
3570 memory blocks allocated : 180612
3570 memory blocks freed     : 180612
0 unfreed memory blocks : 0
True heap size : 262144
True free heap : 262144
```

---

### test_hashset_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_hashset_leak"
77 memory blocks allocated : 74409
77 memory blocks freed     : 74409
0 unfreed memory blocks : 0
True heap size : 131072
True free heap : 131072
```

---

### test_linkedhashmap_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_linkedhashmap_leak"
1110 memory blocks allocated : 197199
1110 memory blocks freed     : 197199
0 unfreed memory blocks : 0
True heap size : 196608
True free heap : 196608
```

---

### test_bitset_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_bitset_leak"
62 memory blocks allocated : 108212
62 memory blocks freed     : 108212
0 unfreed memory blocks : 0
True heap size : 65536
True free heap : 65536
```

---

### test_treeset_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_treeset_leak"
1091 memory blocks allocated : 39849
1091 memory blocks freed     : 39849
0 unfreed memory blocks : 0
True heap size : 196608
True free heap : 196608
```

---

### test_treemap_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_treemap_leak"
1076 memory blocks allocated : 46929
1076 memory blocks freed     : 46929
0 unfreed memory blocks : 0
True heap size : 196608
True free heap : 196608
```

---

### test_priorityqueue_leak

✅ **状态**: PASSED (无内存泄漏)

**HeapTrc 输出**:
```
Heap dump by heaptrc unit of "/home/dtamade/projects/fafafa.core/tests/leak_test_bin/test_priorityqueue_leak"
24 memory blocks allocated : 9703
24 memory blocks freed     : 9703
0 unfreed memory blocks : 0
True heap size : 65536
True free heap : 65536
```

---

## 📁 日志文件

所有详细日志保存在: `/home/dtamade/projects/fafafa.core/tests/leak_test_logs/`

- 编译日志和运行输出在各自的 `.log` 文件中
- HeapTrc 内存泄漏报告包含在运行输出中

---

## 🔍 如何手动运行单个测试

```bash
# 编译
fpc -gh -gl -B -Fu./src -Fi./src -otest_name tests/test_name.pas

# 运行
./test_name

# 检查输出中是否包含:
# "0 unfreed memory blocks : 0"
```

---

**报告结束**
