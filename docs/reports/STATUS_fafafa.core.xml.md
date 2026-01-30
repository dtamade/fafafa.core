# Checkpoint: fafafa.core.xml (Reader/Writer + Tests)

更新时间: 2025-08-18

## 已完成

- 测试脚本与输出稳定性
  - tests/fafafa.core.xml/BuildOrTest.bat
    - 启用延迟展开、括号转义
    - 明确记录退出码；产物存在性检查 [OK]/[FAIL]
    - heaptrc(-gh) 一律重定向到 tests/fafafa.core.xml/bin/heaptrc.txt
    - 通过 PowerShell 包装脚本实现硬性超时，避免无限阻塞
      - tests/fafafa.core.xml/support/run_with_timeout.ps1（参数 -ArgString）
    - 一键统计 JUnit 摘要
      - tests/fafafa.core.xml/support/junit_summary.ps1（输出 suites/tests/failures/errors/skipped）

- Reader 稳健性修复（src/fafafa.core.xml.pas）
  - AppendUtf8 实现标准 UTF-8 编码（1~4 字节）
  - DecodeEntities：对畸形/非法数字实体退化输出并 i+=1（保证“每轮必前进”）
  - StartTag 闭合等待循环：无法判定 '/>' 或 '>' 时 Step 强制前进（并修正 begin/end 结构）
  - 文本跨块路径：持久化返回值到 Owned 缓冲，避免窗口压实后悬挂

- 测试覆盖增强（小缓冲 + 跨块）
  - Reader：
    - Test_fafafa_core_xml_reader_charrefs_smallbuf.pas（既有）
    - Test_fafafa_core_xml_reader_attr_crosschunk_smallbuf[_linc].pas（既有）
    - 新增：
      - Test_fafafa_core_xml_reader_charrefs_nonascii_smallbuf.pas（UTF-8 三字节 '你'）
      - Test_fafafa_core_xml_reader_charrefs_unicode4_smallbuf.pas（UTF-8 四字节 🙂）
      - Test_fafafa_core_xml_reader_charrefs_malformed_smallbuf.pas（无分号/超范围）
      - Test_fafafa_core_xml_reader_charrefs_hex_illegal_smallbuf.pas（非法十六进制）
      - Test_fafafa_core_xml_reader_charrefs_named_mix_smallbuf.pas（& 与 < 的命名/数字混合，严格断言）
  - Writer：
    - Test_fafafa_core_xml_writer_entities_roundtrip.pas（含 &, <, >, 引号，及 UTF-8 非 ASCII/Emoji 的回环）
  - tests_xml.lpr 已接入上述测试单元；初始化期设置环境变量 FAFAFA_TEST_SILENT_REG=1
  - tests/fafafa.core.xml/README.md：本地运行/排障/最佳实践

## 当前状态

- 编译已通过（之前的 begin/end 结构问题已修复）
- 执行 test-junit 时：控制台输出 [Run] 行，完成后脚本会输出 [OK]/[FAIL] 与统计摘要
- 若遇慢用例/异常：超时脚本会强杀并返回 [TIMEOUT]，避免挂住

## 如何继续（新会话快速上手）

- 生成 JUnit 报告并打印摘要
  - tests\fafafa.core.xml\BuildOrTest.bat test-junit
  - 或（手动）
    - tests\fafafa.core.xml\bin\tests_xml.exe --all --format=junit > tests\fafafa.core.xml\bin\junit\tests_xml.junit.xml 2> tests\fafafa.core.xml\bin\heaptrc.txt
    - powershell -NoProfile -ExecutionPolicy Bypass -File tests\fafafa.core.xml\support\junit_summary.ps1 -Path tests\fafafa.core.xml\bin\junit\tests_xml.junit.xml

- 仅观察进度（不写 JUnit）：
  - tests\fafafa.core.xml\BuildOrTest.bat test

- 如需调整超时：
  - 编辑 BuildOrTest.bat 内 -TimeoutSec（默认 junit 分支 180s）

## 待办（Next）

- 收集并粘贴 JUnit 摘要：suites/tests/failures/errors/skipped
- 若出现 [TIMEOUT] 或 [FAIL]：
  - 用 --suite 二分定位具体卡用例；根据“每轮必前进或抛错”原则做最小修复
- Writer 侧再补：命名/数字实体混合更全面用例（>、'、" 已覆盖一部分），并与 Reader 结果逐字符对比
- 文档：在主文档中链接 tests/fafafa.core.xml/README.md 的运行与排障章节

## 约定与偏好

- 不做 CI（仅本地脚本与测试）
- 解析器原则：任何循环必须“推进或抛错”，绝不原地空转
- 优先完善底层与单测，随后推进 UI 层（term 模块）

