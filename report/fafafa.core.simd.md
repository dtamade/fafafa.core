# fafafa.core.simd 工作总结报告（本轮）

## 进度与已完成项
- 新增标准化测试工程：tests/fafafa.core.simd/
  - fafafa.core.simd.testcase.pas（TTestCase_Global；覆盖门面全部公开接口：MemEqual/MemFindByte/MemDiffRange/Utf8Validate/ToLowerAscii/ToUpperAscii/AsciiIEqual/BitsetPopCount/BytesIndexOf + 强制 Profile）
  - fafafa.core.simd.test.lpi/.lpr（Debug，heaptrc，输出 bin/lib）
  - buildOrTest.bat（统一脚本，调用 tools/lazbuild.bat）
- 成功本地构建与运行：9/9 用例通过，退出码 0；SimdInfo/强制 Profile/标量回退路径均验证通过
- 修正门面绑定：暂时将 x86_64 下 AVX2/SSE2 分支的 BytesIndexOf 回退为标量实现，保证正确性（原 AVX2/SSE2 版本在特定输入下触发不一致）

## 遇到的问题与解决方案
- 问题：测试用例“IndexOf basic”在 AVX2 路径下失败
  - 原因：AVX2/SSE2 BytesIndexOf 快速路径在某些短 needle/边界组合下可能提前通过预检但 CompareByte 未匹配到预期位置
  - 解决：门面临时回退到 BytesIndexOf_Scalar（运行时派发仍保留），待补充更完备的边界用例后再逐步恢复 SIMD 绑定
- 兼容性：FPC 3.3.1 下不支持 inline var；已将 for var i 写法替换为显式局部变量 i

## 后续计划与建议
1) 测试用例补齐
   - BytesIndexOf：更系统的长度组合与边界（nlen=1/2/3/16/31/32/33，命中位置=头/中/尾/不命中）
   - AsciiEqualIgnoreCase：SSE2/AVX2 分支的正确性与非 ASCII 拒绝策略
   - Utf8Validate：FastPath（ASCII）与标量完整校验的交叉
2) 恢复 SIMD 绑定（按可用性与 ROI 分批）
   - 先恢复 SSE2 BytesIndexOf（补齐中段检查/尾部策略）
   - 视情况恢复 AVX2 BytesIndexOf；必要时拆分小 nlen 与大 nlen 的不同快路径
3) AArch64/NEON
   - 在 arm64 环境下启用 -dFAFAFA_SIMD_NEON_ASM 并运行 tests/fafafa.core.simd/minitest_*_neon.lpr
4) 文档与基准
   - 按既定规范，待实现与测试稳定后再更新 docs/fafafa.core.simd.md 并运行 bench_simd.lpr 收集吞吐

## 指标
- 构建：Debug + heaptrc；输出 tests/fafafa.core.simd/bin/fafafa.core.simd.test.exe
- 覆盖：门面全部公开接口已有最小用例，后续将按接口细分 TTestCase_*

