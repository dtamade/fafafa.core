# 贡献指南（fafafa.core.color 专项）

本文件为 fafafa.core.color 模块的专项贡献规范，覆盖模块边界、代码风格、构建/运行、测试与文档更新等最佳实践。除非明确同意，请避免对 fafafa.core.term 做侵入式改动。

## 模块边界
- 颜色类型与转换：RGBA/HSV/HSL、sRGB↔Linear、OKLab/OKLCH
- 插值：sRGB、Linear、OKLab、OKLCH（支持 Hue 最短路径）
- Palette：单点/多点（等分/非均匀 positions；可选 normalizePositions）统一采样
- 终端降级映射（xterm256/ANSI16）与前景色建议（WCAG 对比度）

## 代码风格
- Pascal：`{$mode objfpc}{$H+}` + `{$CODEPAGE UTF8}`，与现有单元一致
- API：facade + 纯函数；类型/枚举建模清晰（如 palette_interp_mode_t）
- 命名：`color_*`、`palette_*`、`TTestCase_*`
- 性能：必要时使用 `{$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}`
- 依赖：不新增外部依赖

## 构建与运行
- 构建测试：
  - `tools\lazbuild.bat --build-mode=Debug tests\fafafa.core.color\tests_color.lpi`
- 运行测试：
  - `bin\tests_color.exe --all --format=plain --progress`
  - 通过标准：退出码 0，日志无错误/失败；heaptrc 0 未释放
- 构建示例：
  - `tools\lazbuild.bat --build-mode=Debug examples\fafafa.core.color\palette_demo.lpi`
- 一键脚本：
  - Windows：`examples\fafafa.core.color\RunDemo.bat`
  - PowerShell：`./examples/fafafa.core.color/RunDemo.ps1`
  - Unix/macOS：`bash examples/fafafa.core.color/run_demo.sh`

## 测试规范
- fpcunit；按主题建 `*.testcase.pas`
- 重点覆盖：
  - 转换可逆性/容差（sRGB↔Linear、OKLab/OKLCH）
  - 插值端点幂等、分段中点/单调性、Hue 最短路径一致性（跨 0°/180°）
  - Palette 多点与非均匀 positions（边界裁剪、零段退化、归一化）
  - 终端降级映射边界
- 性能目标：单套件 < 2s（Debug）；重性质测试用固定种子与有限规模

## 文档更新
- API 变更同步至 `docs/fafafa.core.color.md`（签名、参数默认值、示例）
- 示例与脚本：`examples/fafafa.core.color/`（lpi/lpr，RunDemo 脚本），README 描述构建与输出

## 提交与评审
- 小步提交；配套测试与文档
- Conventional Commits：
  - `feat(color): add palette_sample_multi_with_positions + tests + docs`
  - `fix(color): correct OKLCH shortest-hue wrap at boundary`
  - `docs(color): update examples and README`
  - `test(color): extend multi-point monotonicity props`
- 自检：API 命名一致、数学正确与稳定、Hue 路径正确、Palette 边界清晰、测试覆盖充分、文档已更新、未影响 term

## 安全与限制
- 不进行发布/部署；不改动 CI（除非明确要求）
- 不引入额外依赖或全局环境修改


