# 开发计划与待办 - fafafa.core.archiver（本轮更新）

## 即刻（Next 1-2 rounds）
- [ ] 截断负例用例：断言消息、确保 Windows/Unix 下一致稳定
- [ ] Tar Reader：
  - [ ] 0 字节文件读写
  - [ ] 空归档（双零块 vs 异常）
  - [ ] 边界：超长 pax path、多段 pax 记录解析
- [ ] GZip Provider：
  - [ ] 增加 trailer 校验错误路径覆盖（CRC/ISIZE mismatch）
  - [ ] 基准：MemoryStream 100KB/10MB（压缩比与耗时）
- [ ] 文档：在 docs/fafafa.core.archiver.md 增补“Seek 策略、Finish 释放策略、非可寻址流容错”章节

## 中期（M2-M3）
- [ ] Zip 容器最小实现（Store/Deflate）
- [ ] Provider 注册优先级与默认策略（SetDefault/Resolve 优先）
- [ ] 与 fs 集成：FsWalk + Writer.AddFile，高级选项（FollowSymlinks/时间戳/权限）

## 长期
- [ ] Zstd Provider（可选：外部库/纯 Pascal）
- [ ] Zip64、UTF-8 Extra、CentralDirectory 优化
- [ ] 更细化的错误分类与错误码（保留 EArchiverError 作为总类）

# fafafa.core.archiver 模块 TODO（规划与进度）

最后更新：2025-08-20
负责人：Augment Agent

---

## 现状
- 新增接口与门面：src/fafafa.core.archiver.interfaces.pas、src/fafafa.core.archiver.pas
- 引入 CompressionAlgorithm + Provider/Registry 架构；移除硬编码后端枚举
- 文档初稿已同步更新：docs/fafafa.core.archiver.md（分层组合、Provider 列表）
- 尚未实现容器与压缩后端（tar/zip；gzip/deflate/zstd），CreateArchiveReader/Writer 暂抛 EArchiverError

## 近期计划（M1）
1) 选择首个后端：Tar(+GZip)
   - 读：解析 ustar 头；支持长文件名（pax 记录最小集）；按 size 流式跳过与读出
   - 写：生成 ustar 头；对齐到 512 block；目录条目与普通文件
   - gzip 包装：TStream 适配器（复用 zlib）
2) 单元测试骨架：tests/fafafa.core.archiver/
   - TTestCase_Global：测试工厂函数与错误路径
   - TTestCase_TarReader/TarWriter：覆盖所有公开接口
3) 示例：examples/fafafa.core.archiver/example_minimal_tar
4) 文档更新：完成 Tar 行为矩阵与限制说明

## 对标与可行性
- Go archive/tar + compress/gzip：API 与行为对齐
- Rust tar crate：流式读取、pax 扩展字段
- Java java.util.zip.GZIPInputStream/Tar 未内置（Apache Commons Compress 可参考）

## 里程碑（更新：基准暂缓）
- M1（Tar/GZip 可用 + 测试最小集）
- M2（Zip 可用：Store/Deflate）
- M3（增强：权限/时间戳/符号链接 & PAX 扩展）
- 基准测试：暂缓，等三路后端齐备后再立项

## 风险与缓解
- 压缩库依赖：优先复用 RTL zlib；避免第三方依赖
- 路径与编码：统一 UTF-8；与 Windows ANSI 的互转在上层处理
- 大文件支持：流式读写，避免一次性缓存

## 待维护者批示
- 允许创建 tests/examples 目录与 LPI/LPR 工程
- 允许基于现有工具脚本添加 BuildOrTest.bat（不涉及 CI）

