# 贡献指南（fafafa.core.xml 专项）

> 开发约定：全部功能/优化落地之后，再统一编写文档与基准测试；在此之前不写文档或基准。

## 模块边界
- 解析器：流式/字符串两种路径，命名空间绑定与校验，Freeze 构建最小 DOM
- Writer：占位符/属性分组→排序/去重→展开；Pretty（缩进/换行占位）
- I/O：Reader 支持文件/流/字符串；Writer 支持字符串/流/文件

## 代码风格
- Pascal：`{$mode objfpc}{$H+}` + `{$CODEPAGE UTF8}`，与现有单元一致
- 禁止：方法内联变量、内嵌过程/嵌套函数（使用独立小函数/过程）
- 内部字符串优化：
  - Reader：跨块拼接使用 ScratchClear/ScratchAppend（避免 `S1 + S2`）
  - Writer：TStringBuilder.EnsureCapacity 预估容量后 Append

## 构建与运行
- 测试套件：`tests\fafafa.core.xml\tests_xml.lpi`
- 一键脚本：`tests\fafafa.core.xml\BuildOrTest.bat`
  - 常用参数：`test-notiming`、`test-plainlog`
- 不做 CI 改动（除非明确要求）

## 测试规范
- fpcunit；按主题分类：Reader、NS、Errors、Traversal、Writer、Perf
- 覆盖重点：
  - Reader：跨块文本/CDATA/PI、实体/字符引用、BOM/AutoDecode、行列定位
  - NS：默认/前缀绑定、非法绑定/URI、属性 NS 行为（默认 NS 不作用于属性）
  - Freeze：树结构、兄弟/父子链接、属性数量与名称一致
  - Writer：属性排序/去重、Pretty 占位换行/缩进、NS 声明与约束
- 运行期应保持：heaptrc 0 未释放；退出码 0；错误/失败为 0

## 文档与基准（延后原则）
- 文档与基准均在“全部功能/优化落地”之后再统一补齐：
  - API 文档：`docs/fafafa.core.xml.md`
  - 性能基准：`docs/benchmarks/` 与 `docs/PERF*.md`

## 提交与评审
- 小步提交；优先保证测试通过与性能目标
- Conventional Commits 示例：
  - `feat(xml): ring buffer streaming + coalesced scratch builder`
  - `perf(xml): writer stream output with on-the-fly placeholders`
  - `fix(xml): unbound prefix detection and line/col snapshots`
  - `test(xml): add cross-chunk CDATA & PI cases`

## 安全与限制
- 不进行发布/部署；不改动 CI（除非明确要求）
- 不引入额外依赖或全局环境修改

