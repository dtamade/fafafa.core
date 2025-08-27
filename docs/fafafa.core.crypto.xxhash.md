# fafafa.core.xxhash

- 模块：src/fafafa.core.crypto.hash.xxhash32.pas
- 门面：src/fafafa.core.crypto.pas（CreateXXH32 / XXH32Hash）
- 状态：Phase 1 — 实现 XXH32（流式+seed），非加密哈希

## 使用

- 一次性：
```
var d: TBytes;
d := XXH32Hash(TEncoding.UTF8.GetBytes('hello'));
```
- 流式：
```
var h: IHashAlgorithm; r: TBytes; b: TBytes;
h := CreateXXH32(0);
b := TEncoding.UTF8.GetBytes('hello');
if Length(b)>0 then h.Update(b[0], Length(b));
r := h.Finalize;
```

## 注意
- xxhash 为非加密哈希，不适合安全场景（认证/签名/密码学用途）。
- 输出为 4 字节（小端序），返回的 TBytes 长度为 4。

## 计划
- Phase 2：XXH64 + 向量一致性测试
- Phase 3：XXH3-64/128，性能优化（非对齐读、SIMD 可选）

