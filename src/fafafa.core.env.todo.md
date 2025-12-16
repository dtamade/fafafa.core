# fafafa.core.env 模块 TODO（规划与进度）

最后更新：2025-12-16

---

## 现状评估
- 模块版本：v1.2（企业级就绪，对标 Rust std::env）
- 源文件：src/fafafa.core.env.pas
- 能力：
  - 基础 API：env_get/env_set/env_unset/env_vars/env_lookup/env_has
  - 便捷 API：env_required/env_keys/env_count/env_get_or + nonempty helpers
  - RAII 覆写：env_override/env_overrides/env_override_unset
  - 字符串展开：env_expand（$VAR/${VAR} + Windows %VAR%）
  - PATH 处理：env_split_paths/env_join_paths/env_join_paths_checked + env_get_paths
  - 目录查询：current/home/temp/exe/user_config/user_cache
  - 平台常量：env_os/env_arch/env_family/env_is_*
  - 迭代器：env_iter（支持 for-in；Windows/Unix 直接遍历环境块/ environ）
  - 命令行参数：env_args/args_count/arg
  - 安全辅助：env_is_sensitive_name/env_mask_value/env_validate_name/env_vars_masked
  - 类型化 Getters：
    - env_get_bool/env_get_int/env_get_int64/env_get_uint/env_get_uint64
    - env_get_duration_ms/env_get_size_bytes/env_get_float/env_get_list/env_get_paths
  - 沙盒操作：env_clear_all
  - Result API：可选启用（FAFAFA_ENV_ENABLE_RESULT）
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
- [x] M6：v1.2 强化（已完成 2025-12-16）
  - 类型化 Getters 扩充（UInt/UInt64/Duration/Size/Paths 等）
  - 安全增强（敏感名 token 识别、mask 策略、env_vars_masked）
  - Result Err.Msg 可读性增强（包含 index/segment/separator/op/code 等）

## 测试覆盖
- 94 个测试用例，全部通过
- 覆盖：基础操作、RAII 守卫、字符串展开、PATH、目录查询、安全、便捷 API、平台常量、迭代器、命令行参数、沙盒、Result API、typed getters

## 待补充（低优先级）
- 文档明确：`env_iter` 在非 for-in 使用时需手动调用 enumerator.Free
- 备注：非 UNIX/WINDOWS 平台 `env_count` 走 os_environ snapshot（会分配 TStringList）

## 后续规划
参见 docs/fafafa.core.env.roadmap.md

