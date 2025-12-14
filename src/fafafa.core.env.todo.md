# fafafa.core.env 模块 TODO（规划与进度）

最后更新：2025-12-08

---

## 现状评估
- 模块版本：v1.1（企业级就绪，对标 Rust std::env）
- 源文件：src/fafafa.core.env.pas
- 能力：
  - 基础 API：env_get/env_set/env_unset/env_vars/env_lookup/env_has
  - 便捷 API：env_required/env_keys/env_count/env_get_or
  - RAII 覆写：env_override/env_overrides/env_override_unset
  - 字符串展开：env_expand（$VAR/${VAR} + Windows %VAR%）
  - PATH 处理：env_split_paths/env_join_paths/env_join_paths_checked
  - 目录查询：current/home/temp/exe/user_config/user_cache
  - 平台常量：env_os/env_arch/env_family/env_is_*
  - 迭代器：env_iter（支持 for-in）
  - 命令行参数：env_args/args_count/arg
  - 安全辅助：env_is_sensitive_name/env_mask_value/env_validate_name
  - 沙盒操作：env_clear_all
- 依赖：复用 src/fafafa.core.os.pas 提供的跨平台实现

## 里程碑
- [x] M1：API 门面落地（已完成）
- [x] M2：测试与示例补齐（已完成 2025-08-25）
- [x] M3：v1.1 升级 - 对标 Rust std::env（已完成 2025-12-06）
- [x] M4：代码审查与清理（已完成 2025-12-08）
  - 删除死代码（参考实现）
  - 提取共享逻辑（ParseEnvLine）
  - 文档整合
- [x] M5：命令行参数 API（已完成 2025-12-08）
  - env_args/args_count/arg

## 测试覆盖
- 59 个测试用例，全部通过
- 覆盖：基础操作、RAII 守卫、字符串展开、PATH 处理、目录查询、安全辅助、便捷 API、平台常量、迭代器、命令行参数、沙盒操作、Result API

## 后续规划
参见 docs/fafafa.core.env.roadmap.md

