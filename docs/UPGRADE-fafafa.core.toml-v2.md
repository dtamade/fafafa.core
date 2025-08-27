# UPGRADE to fafafa.core.toml parser v2

目标
- 指导用户从 v1 解析器平滑迁移到 v2
- 解释行为差异、开启方式、回退策略与最佳实践

## 如何开启 v2
- Parse 的 AFlags 增加 `trfUseV2`
  - 示例：
    ```pascal
    var Doc: ITomlDocument; Err: TTomlError;
    if Parse(RawByteString('a = [{x=1}, {x=2}]'), Doc, Err, [trfUseV2]) then ...
    ```
- 默认仍使用 v1；逐步迁移时建议按模块/配置文件分批启用

## 行为差异（v1 vs v2）
- 数值
  - NaN/Inf：两者均禁止（与 TOML 1.0 一致）。v2 遇到相关标识更严格报错，错误信息更一致
- 数组/内联表
  - v2 对内联表、嵌套数组、数组内表（AoT）覆盖更完备，容错与报错前缀更统一
  - v1 的一些边界（内联表值类型）支持不完整；迁移时建议优先开启 v2
- 键/路径
  - 两者均支持 dotted keys、quoted/bare 键，重复/冲突严格校验
- 错误消息
  - v2 的 LastErrorMessage 前缀与定位更一致；便于在日志中聚合

## 迁移步骤建议
1) 标识样本
   - 收集现网 TOML 配置样本（含大文件、边界用例、历史遗留写法）
2) 双跑比对
   - 单元测试层：为关键用例增加在 `[trfUseV2]` 与 `[]` 下分别解析与断言
   - 工具层：可临时添加一个 CLI/工具脚本，对比 v1/v2 的 parse 成功率与错误消息
3) 分批启用
   - 按服务、按配置目录、按文件名分批启用 `trfUseV2`
   - 对于报错差异，先修正配置或在解析前做预清洗
4) 回退策略
   - 保留开关；若遇到无法立即修复的配置，可暂时回到 v1，继续排查

## 最佳实践
- 配置规范
  - 避免重复键、避免数组类型混合（本库 Builder 已强制同构）
  - 字符串尽量使用基本字符串（"...")，必要时加引号；键名包含空格/点/非 bare 字符需加引号
  - 禁用 NaN/Inf/-Inf；用显式可解析文本替代
- API 使用
  - 首选 TryGet*（返回 Boolean）与新 API：Has / TryGetValue；显式判断存在性与类型
  - 需要默认值时使用 Get*，但避免用默认值判断存在性
- Writer 风格
  - 推荐默认风格：`key = value`（twfTightEquals 关闭）。若需紧凑，可显式加 `twfTightEquals`
  - 复杂层级建议开启 twfSortKeys 与 twfPretty 提升可读性
- 性能
  - 大文件解析建议逐步迁移至 v2，并在未来考虑流式读取（Roadmap）
  - Writer 已优化拼接；避免在外部再对 ToToml 结果做大量字符串拼接，尽量一次性输出

## 兼容性注意
- TryGet* 语义已修正（仅存在且类型匹配才 True）。历史调用若依赖旧行为，请调整逻辑
- Builder 的 AddPair 改为同键覆盖，不再追加重复键；数组强制同构类型
- 文档同步说明：默认空格等号；twfSpacesAroundEquals 已废弃，改用 `twfTightEquals`

## 附录：问题排查
- 常见错误与建议：
  - invalid identifier value / NaN/Inf not allowed in TOML：检查数值字段，替换为合法字面量
  - invalid inline table value / mixed array types：检查数组元素是否同构，内联表值是否是允许的类型
  - duplicate key / type mismatch in path：检查同一表重复赋值或同一路径不同类型赋值


