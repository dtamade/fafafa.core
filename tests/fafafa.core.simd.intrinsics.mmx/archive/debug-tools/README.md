# MMX 调试资产归档说明

更新时间：2026-02-08

## 背景
- 本目录存放历史调试/定位脚本，不参与正式构建链与门禁。
- 正式入口仅保留：
  - `fafafa.core.simd.intrinsics.mmx.test.lpi`
  - `fafafa.core.simd.intrinsics.mmx.test.lpr`
  - `fafafa.core.simd.intrinsics.mmx.testcase.pas`
  - `BuildOrTest.sh` / `buildOrTest.bat`

## 归档原则
- 仅迁移未被 `lpi`、`BuildOrTest`、测试 `lpr` 引用的文件。
- 归档后不影响 `BuildOrTest.sh test`、SIMD 总门禁、coverage 严格模式。

## 如需临时调试
- 可在本目录单独编译运行对应脚本（不纳入 CI/gate）。
- 如确认某脚本需恢复为正式资产，请在 PR 中说明用途与接入点。

## 已归档文件
- `debug_byte_cast.pas`
- `debug_packsswb.pas`
- `debug_packuswb.pas`
- `debug_por.pas`
- `debug_psub.pas`
- `debug_psubusb.pas`
- `debug_psubusb_real.pas`
- `debug_pxor.pas`
- `debug_shift.pas`
- `debug_test.pas`
- `detailed_test_runner.lpr`
- `emms_test.pas`
- `final_debug.pas`
- `find_exact_failure.pas`
- `find_failures.lpr`
- `find_last_failure.pas`
- `individual_test.pas`
- `manual_test_runner.pas`
- `minimal_test.pas`
- `quick_test.pas`
- `simple_mmx_test.pas`
- `simple_test.pas`
- `simple_test_runner.lpr`
- `test_individual.pas`
- `verbose_test.lpr`
