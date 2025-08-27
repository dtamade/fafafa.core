# report — fafafa.core.xml（本轮）

日期：2025-08-22

## 进度与已完成项
- 修复编译错误（ReadAllToAnsiString 提前 Exit 漏 end），最小改动保证可编译
- 本地构建与测试：tests/fafafa.core.xml 全量 66/66 通过（E:0 F:0），包含跨块/小缓冲/实体/字符引用/命名空间/Freeze/Writer Pretty/属性排序去重 等
- 更新文档 docs/fafafa.core.xml.md：
  - 新增“支持矩阵（与当前实现对齐）”：Reader/Writer/Freeze/Flags/行列定位/命名空间
  - 新增“Bench 使用与调优”：XML_BUF_SIZE、缓冲大小建议、合并文本开关建议
  - 新增“限制与兼容性”：编码策略、DTD/外部实体、零拷贝有效期、命名空间规则、FPC/Lazarus 版本
- 同步更新 todos/fafafa.core.xml.md：明确 P1 文档巩固已完成与 P2 编码增强计划

## 遇到的问题与解决方案
- 问题：tests 构建阶段报 src/fafafa.core.xml.pas(401) Illegal expression（提前 Exit 后缺失 end）
  - 方案：补全 end；不改变逻辑，构建恢复

## 后续计划（下一轮）
1) 编码自动检测与转码（P2）：实现/完善 xrfAutoDecodeEncoding
   - BOM 优先策略；支持 UTF-16/32 LE/BE；与 XML 声明冲突时报错
   - 覆盖小缓冲、跨块、声明边界等测试
2) 性能与稳定性微调：EnsureLookahead 策略、流式 Coalesce 相邻合并边界
3) 文档跟进：编码增强完成后补充“编码支持矩阵与示例”

## 备注
- 遵循仅使用 lazbuild 的构建规范；不涉及 CI
- 输出目录规范：bin/ 与 lib/ 均已按约定生成
