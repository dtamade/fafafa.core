# report — fafafa.core.crypto.xxhash（本轮）

日期：2025-08-18

## 进度与已完成项
- 新增 XXH32 实现（IHashAlgorithm 兼容，流式 + seed）：src/fafafa.core.crypto.hash.xxhash32.pas
- 门面集成工厂/便利函数：CreateXXH32 / XXH32Hash
- 最小测试工程：tests/fafafa.core.crypto.xxhash/（一键脚本、LPI/LPR、用例）
- 文档初稿：docs/fafafa.core.crypto.xxhash.md

## 遇到的问题与解决方案
- 在线检索中断：采用已知稳定常量与算法流程，先保证正确性与跨平台；待网络恢复后补充官方向量一致性测试
- 测试工具函数统一：复用门面导出的 TBytes 与 BytesToHex；字符串→字节采用 Move，保持与库一致

## 后续计划
- Phase 2：实现 XXH64 + 引入官方已知向量测试（兼容大小端与非对齐路径）
- Phase 3：实现 XXH3-64/128 + 性能优化（指针 & 非对齐读；可选 SIMD）
- examples：补一个简单对比 SHA-256 的吞吐演示与用途说明（非安全 vs 安全）

