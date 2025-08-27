# todos — fafafa.core.crypto.xxhash

- [ ] Phase 2：实现 XXH64；补充官方向量一致性测试（包括空串、'a', 'abc', 长数据）
- [ ] Phase 3：实现 XXH3（64/128）与 streaming；添加 128-bit 输出 API 设计
- [ ] 性能：在 x86/x64 上添加非对齐读优化路径；必要时提供 -dFAFAFA_CRYPTO_XXHASH_UNALIGNED 开关
- [ ] 示例：examples/fafafa.core.crypto.xxhash/example_xxhash32_min.lpr
- [ ] 文档：补充与 CRC32/Adler32/SipHash 的对比与选型建议

