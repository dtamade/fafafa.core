# Changelog

## Unreleased

### Added – Environment Module v1.1 (fafafa.core.env)
Modern, cross-platform environment variable and user directory helpers.
Inspired by Rust std::env and Go os.

**Core Features:**
- Basic operations: `env_get`, `env_set`, `env_unset`, `env_lookup`, `env_has`, `env_vars`
- Convenience API: `env_required` (throws EEnvVarNotFound), `env_keys`, `env_count`, `env_get_or`
- RAII override guards: `env_override`, `env_override_unset`, `env_overrides` (manual Done cleanup)
- String expansion: `env_expand` ($VAR, ${VAR}, Windows %VAR%), `env_expand_with` (custom resolver)
- PATH handling: `env_split_paths`, `env_join_paths`, `env_join_paths_checked`
- Directories: `env_current_dir`, `env_home_dir`, `env_temp_dir`, `env_executable_path`, `env_user_config_dir`, `env_user_cache_dir`

**v1.1 Additions (2025-12-06):**
- Platform constants: `env_os`, `env_arch`, `env_family`, `env_is_windows`, `env_is_unix`, `env_is_darwin`
- Iterator API: `TEnvKVPair`, `TEnvVarsEnumerator`, `env_iter` (supports for-in)
- Command-line args: `env_args`, `env_args_count`, `env_arg`
- Security helpers: `env_is_sensitive_name`, `env_mask_value`, `env_validate_name`
- Sandbox: `env_clear_all` (dangerous, for test isolation)
- Exception: `EEnvVarNotFound`
- Result API (conditional, macro-gated): `env_get_result`, `env_join_paths_result`, `env_current_dir_result`, etc.

**v1.2 Additions (2025-12-16):**
- Typed Getters: `env_get_bool`, `env_get_int`, `env_get_int64`, `env_get_uint`, `env_get_uint64`, `env_get_duration_ms`, `env_get_size_bytes`, `env_get_float`, `env_get_list`, `env_get_paths`
  - `env_get_bool`: Parse true/false/1/0/yes/no/on/off (case-insensitive), returns default for unrecognized/undefined
  - `env_get_int`: Parse integer (Int32), returns default for invalid/undefined
  - `env_get_int64`: Parse integer (Int64), returns default for invalid/undefined
  - `env_get_uint`: Parse unsigned integer (UInt32/Cardinal), returns default for invalid/undefined/negative/overflow
  - `env_get_uint64`: Parse unsigned integer (UInt64/QWord), returns default for invalid/undefined/negative/overflow
  - `env_get_duration_ms`: Parse duration to milliseconds; supports suffix ms/s/m/h/d (case-insensitive); no suffix = ms; returns default for invalid/overflow
  - `env_get_size_bytes`: Parse size to bytes; supports B/KB/MB/GB and KiB/MiB/GiB (case-insensitive; optional spaces); no suffix = bytes; returns default for invalid/overflow
  - `env_get_float`: Parse float (Double) with '.' decimal separator (locale-invariant), returns default for invalid/undefined
  - `env_get_list`: Split by separator (default comma), returns empty array for undefined
  - `env_get_paths`: Split by platform PATH separator (like `env_split_paths`), returns empty array for undefined/empty
- Convenience & Security:
  - `env_vars_masked`: export masked NAME=VALUE snapshot for logging/diagnostics
  - `env_is_sensitive_name`: token-based detection to reduce false positives (e.g. avoids MONKEY/AUTHOR)
  - `env_mask_value`: updated policy to keep only a short tail (avoid leaking prefixes)
- Result API:
  - Improved Err Msg fields for readability (include var name / separator / OS error code where available)
  - EIOError now includes Kind, Code (OS error code; 0 if unavailable) and SysMsg (SysErrorMessage(Code) when available)
  - EPathJoinError now includes Kind (currently pjekContainsSeparator) and Separator (the path list separator that caused the join failure)
  - EVarError now includes Kind (currently vekNotDefined)
- Performance optimization: `env_expand` fast path (16.9x speedup for passthrough)
- Performance optimization: `env_iter` iterates environ directly (Unix) / GetEnvironmentStringsW block (Windows), avoids TStringList snapshot allocation

**Tests:**
- 94 test cases, 100% pass rate
- Documentation examples validated (25/25 tests pass)

**Performance Baseline (2025-12-13):**
- env_get: 16M ops/sec
- env_expand (simple): 824K ops/sec
- env_split_paths: 1.4M ops/sec
- See benchmarks/fafafa.core.env/BASELINE.md

**Docs:**
- docs/fafafa.core.env.md (API reference, examples, platform differences)
- docs/fafafa.core.env.roadmap.md (development roadmap)

### Added – Result method-style API (macro-gated)
- TResult<T,E>: add Rust-style method wrappers guarded by FAFAFA_CORE_RESULT_METHODS (default OFF)
  - Map/MapErr/AndThen/OrElse/MapOr/MapOrElse/Inspect/InspectErr/OkOpt/ErrOpt
  - All wrappers delegate to existing top-level combinators; no semantic change by default
- Tests: method-style minimal cases added under the same macro
- Docs: docs/README.result.methods.md with usage and examples; README.md links to it



- 终端模块（fafafa.core.term）：粘贴存储后端 ring（behind-a-flag）与相关语义更新，详见 docs/CHANGELOG_fafafa.core.term.md 与 docs/fafafa.core.term.md#paste-后端选择与推荐配置

### Added – Collections OrderedMap (TRBTreeMap)
- APIs: TryAdd, TryUpdate, Extract, LowerBoundKey, UpperBoundKey
- Docs: docs/partials/collections.orderedmap.apis.md（常用 API、示例、策略建议）；更新 docs/API_collections.md、docs/fafafa.core.collections.md 入口
- Samples: orderedmap_range_pagination.pas + Build_range_pagination.bat；orderedmap_range_pagination_int.lpr + Build_range_pagination_int.bat（整数键 UpperBound 续页）
- Tests: 新增
  - Test_TryUpdate_Extract_NegativePaths
  - Test_Extract_ManagedValue_Semantics
  - Test_Randomized_Small_Stability
  - 分页/边界：Strategies_Equivalence、Boundary_Cases、InclusiveRight_Alignment、VarPageSizes、Bidirectional_FromMiddle、SparseKeys、CaseInsensitive_Boundary_Consistency
- Notes: 修复/清理若干局部 var 位置与重复片段引发的编译问题

### Added – OS module (fafafa.core.os)
- Environment: os_getenv, os_setenv, os_unsetenv, os_environ
- Platform info: os_hostname, os_username, os_home_dir, os_temp_dir, os_exe_path, os_cpu_count, os_page_size, os_platform_info
- Kernel/Uptime: os_kernel_version, os_uptime
- Memory/Boot/Timezone: os_memory_info, os_boot_time, os_timezone
- Capabilities: os_is_admin, os_is_wsl, os_is_container, os_is_ci
- Second batch: TOSVersionDetailed (Name, VersionString, Build, Codename, PrettyName, ID, IDLike), os_os_version_detailed, os_cpu_model, os_locale_current
- Platform impl: Windows (WinAPI, registry, SID), Unix (/proc, /etc/os-release, uname, TZ detection), macOS Darwin→macOS mapping (13/14/15)
- Examples: example_basic (text/JSON, --fields), example_capabilities (JSON, --fields, --output), one-click scripts, .lpi
- Docs: quickstart outputs (Windows/Linux/macOS), CLI overview, JSON field dictionary, platform differences, Windows build mapping, macOS mapping, FAQ, consumption examples

### Changed – OS module hardening
- Windows: admin detection via Administrators SID; CPU model via registry + env fallback; Windows 10/11 build mapping refined (incl. 21H1..24H2)
- Unix: locale normalization (LANG/LC_* → language-REGION, strip encoding/modifier); timezone detection priority (TZ→/etc/timezone→/etc/localtime)

### Tests – OS module
- Soft-assert suites for version detail fields, CPU model, locale; capabilities no-throw

### Fixed
- Vec: IGrowthStrategy 生命周期与下界行为
  - 修复 TVec.GetGrowStrategyI 直接 `as IGrowthStrategy` 导致的生命周期/引用计数耦合风险，改为返回弱包装视图，避免悬垂/双重释放/AV。
  - 调整 TGrowthStrategy.GetGrowSize：取消 aCurrentSize=0 的特判，统一委派到具体策略（DoGetGrowSize），并在基类做 Result>=aRequiredSize 的下界收敛，确保自定义策略“首轮扩张”即可生效。
  - 测试：TTestCase_Vec 全量通过；此前失败用例 Test_GrowStrategy_Interface_CustomBehavior 恢复通过。

## 0.9.0 - 2025-08-19

### fafafa.core.ini
- Features
  - File-level Entries capture and exact replay when document is not dirty
  - Dirty semantics: any Set* marks document dirty; reassembly applies write flags
  - Read flags: irfCaseSensitiveKeys, irfCaseSensitiveSections, irfDuplicateKeyError, irfInlineComment
  - Write flags: iwfSpacesAroundEquals, iwfPreferColon, iwfBoolUpperCase, iwfForceLF
  - Locale-invariant float parsing/formatting
- Stability
  - Strict round-trip tests: comments/blank lines, inter-section comments, empty sections, consecutive blanks
  - Edge cases: empty file, comments-only file, long line smoke test (~64KB)
  - Docs: README with default behavior and Dirty/Entries semantics
- Notes
  - Write flags affect only the reassembly path; when replaying Entries/BodyLines (and not dirty), raw text is preferred
  - Inline comments affect parsing of values; comments are preserved via Entries/BodyLines

### inifmt CLI
- New CLI tool at tools/inifmt
- Modes: verify (round-trip), format (apply write flags)
- Options: --in-place, --output, --inline-comment, --case-sensitive-keys, --case-sensitive-sections, --duplicate-key-error, --spaces, --colon, --bool-upper, --lf


## 0.6.0 - 2025-08-18

### fafafa.core.json (2025-08-18)
- Facade: centralized type-assertion error messages (use constants from `src/fafafa.core.json.errors.pas`) to stabilize assertions.
- Tests: full suite green (92/92) via `tests/fafafa.core.json/BuildOrTest.bat test`.
- Next: draft facade minimization plan; unify examples build scripts to lazbuild.


### Added
- Facade: JsonArrayForEach / JsonObjectForEach (callback can early-stop)
- Facade: Typed TryGet — JsonTryGetInt/UInt/Bool/Float/Str
- Facade: OrDefault — JsonGetIntOrDefault/UInt/Bool/Float/Str
- Plays: perf_json_read_write.lpr adds ForEach vs Pointer+TryGet micro-benchmark
- Docs: English guide (docs/fafafa.core.json.en.md)
- Docs: Chinese quick start + migration guide + expanded yyjson mapping
- Facade: JsonObjectForEachRaw — raw key pointer+length callback to avoid key String allocation in hot paths



### Perf
- Plays: perf_json_read_write.lpr adds object ForEach Raw-key vs String-key micro-benchmark; script supports arguments --arr/--nums/--objKeys


### Tests
- Added tests covering array/object ForEach early stop, typed TryGet success/fail, and OrDefault defaults
- All json tests passing (92/92)

### Compatibility
- Facade is a thin layer; underlying fixed behavior unchanged
- Object ForEach allocates a transient key string; values are zero‑copy wrappers
- Recommend migrating exception‑throwing Get* to TryGet/OrDefault and manual loops to ForEach


### Fixed
- Reader: default allocator fallback — when no allocator is provided, IJsonReader falls back to GetRtlAllocator in ReadFromString/ReadFromStringN to avoid “Invalid allocator”

- VecDeque: Prevent memory leak from TPtrIter when loops exit early
  - Insert(aCollection, aStartIndex): free `LIter.Data` after the copy loop
  - Write(aCollection, aStartIndex): free `LIter.Data` after the copy loop
  - OverWriteUnChecked(aIndex; const aSrc: TCollection; aCount): free `LIterator.Data` after the copy loop

### Added
- Tests: Implement 8 Remove* test cases in `tests/fafafa.core.collections.vecdeque/Test_fafafa_core_collections_vecdeque_clean.pas`
  - Test_RemoveCopy_Index_Pointer_Count
  - Test_RemoveCopy_Index_Pointer
  - Test_RemoveArray_Index_Array_Count
  - Test_Remove_Index_Element
  - Test_RemoveCopySwap_Index_Pointer_Count
  - Test_RemoveCopySwap_Index_Pointer
  - Test_RemoveArraySwap_Index_Array_Count
  - Test_RemoveSwap_Index_Element

### Infra
- Play project under `plays/fafafa.core.collections.vecdeque` for fast iteration
  - Console test runner with logs: `play_build.log`, `play_run.log`
- Enhanced `tests/fafafa.core.collections.vecdeque/BuildOrTest.bat` to capture full-suite plain output to `bin/results_plain.txt` and print it

### Changed
- VecDeque: Switch iterator to zero-allocation design (aIter.Data stores logical index)
  - Removed heap allocation/free for iterator state in PtrIter/DoIterMoveNext
  - Eliminated manual loop-tail frees in Insert/Write/OverWrite*

### Changed

### Changed
- json facade merged into json unit. The old `fafafa.core.json.facade` unit was removed; use `fafafa.core.json`.
- Writer: now throws `EJsonParseError('Document has no root value')` when document root is nil (was previously returning empty string or failing later).
- IJsonDocument: added properties `Root`, `Allocator`, `BytesRead`, `ValuesRead`.

### Fixed
- Implemented missing getters in facade by delegating to fixed: `GetArrayItem` via `JsonArrGet`, `GetObjectValueN`/`HasObjectKeyN` via `JsonObjGetN`.
- JsonPointerGet uses internal bridge interfaces to safely access raw pointers and document, avoiding access violations.

### Tests
- All 92 json tests passing.
- Added `json-facade` edge tests for writer no root and pointer slash-only.

### Migration Guide
- Replace `uses fafafa.core.json.facade` with `uses fafafa.core.json`.
- If you relied on writer returning empty string for nil root, catch `EJsonParseError` instead or ensure root is set.


