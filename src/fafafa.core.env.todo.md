# fafafa.core.env 模块 TODO（规划与进度）

最后更新：2025-08-24

---

## 现状评估
- 新增门面单元：src/fafafa.core.env.pas
- 能力：
  - env_get/env_set/env_unset/env_vars
  - env_override（测试/工具临时覆写并回滚，RAII）
  - env_expand（$VAR/${VAR} + Windows %VAR%）
  - PATH：env_split_paths/env_join_paths + 分隔符查询
  - 目录：current/home/temp/exe + user_config/user_cache
- 依赖：复用 src/fafafa.core.os.pas 提供的跨平台实现

## 竞品模型对照（Rust/Go/Java）
- Rust std::env：var/vars/split_paths/join_paths/current_dir/set_current_dir/temp_dir/home_dir
- Go os：Getenv/Setenv/Environ/Getwd/Chdir/UserHomeDir/UserConfigDir/UserCacheDir/ExpandEnv
- Java nio：System.getenv()/Properties，Paths 与 Files 组合使用

## 下一步
- [x] 单元测试：tests/fafafa.core.env/（已补齐并通过 Windows 本地构建）
  - env_expand：空值、未定义、混合文本、Windows 分支（已覆盖）
  - PATH：split/join roundtrip（已覆盖）
  - set/get/unset：保存并回滚原值（已覆盖）
  - env_override/env_overrides/env_override_unset：回滚与 unset 语义（已覆盖）
  - user dirs：仅断言“非空或合理回退”（已覆盖）
- [x] 示例：examples/fafafa.core.env/example_quickstart（已补齐并通过 BuildOrRun.bat 验证）
- [ ] 文档：平台差异表与最佳实践（不要在库中修改全局 env；测试推荐 env_override；补充批量覆写与显式 unset 守卫）

## 里程碑
- M1：API 门面落地（已完成）
- M2：测试与示例补齐（已完成 2025-08-25）
- M3：文档完善与收尾

