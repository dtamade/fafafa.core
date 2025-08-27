# todos — fafafa.core.xml

更新时间：2025-08-18

## 本轮目标（最小闭环）
- 修复编译错误（接口实现顺序/Stub 缺口）— 完成
- 跑通 XML 测试工程构建与运行（fpcunit runner）— 完成（构建成功，runner 无详细输出待格式调整）
- 输出模块文档初稿 — 完成

## 待办（高优先级）
1) 文档巩固（本轮 P1）
   - 更新 docs/fafafa.core.xml.md：支持矩阵、Bench 使用、限制与兼容性（已执行）
   - 结合 tests/fafafa.core.xml 结果，补充行为边界说明（零拷贝有效期、Coalesce 不跨 Comment/PI）
2) Reader（编码增强，下一轮 P2）
   - xrfAutoDecodeEncoding：支持 UTF-16/32 LE/BE（BOM 优先）自动转 UTF-8；声明 encoding 冲突检测
   - 小缓冲/跨块/声明边界的转码用例与回归测试
3) Reader/Writer 稳定性
   - 环形缓冲与跨块定位；实体/非法码点边界（延续现有测试扩展）
   - Writer 属性排序/去重组合边界与 Pretty 定位（延续现有测试扩展）
4) DOM Freeze 与遍历
   - 父/子/兄弟链接稳定性，跨多次 Freeze 的树构建；Arena 分配器对接（fafafa.core.mem）
5) 示例与基准
   - examples/fafafa.core.xml：bench 文档化使用；缓冲大小调优示例；reader 过滤/计数示例完善

## 验收标准
- tests/fafafa.core.xml 全部通过；新增边界用例覆盖命名空间/跨块/错误路径
- docs/fafafa.core.xml.md 完成 API/行为/示例；report 更新

## 风险与缓解
- 跨块处理复杂：以最小窗口 + 逐步扩展测试来缓解
- Writer NS 自动推断：先提供显式 DeclareNamespace，逐步演进

