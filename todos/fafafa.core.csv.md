# 开发计划日志：fafafa.core.csv

日期：2025-08-16

## 近期目标
- 通过 tests/fafafa.core.csv 全量用例（当前剩余少量 Reader 细节）
- 保持接口外观与方言配置不变，最小改动完成修复

## 进行中
- 逐套件验证，低噪声运行：
  - Reader_Escape_BOM / Reader_Multiline_NoEscape / Reader_Edge_More / Writer_Extremes
  - 最后攻关：Reader_Quoted 中“引号内换行”断言

## 待办
1. 若“引号内换行”仍不等：
   - 将 LF 归一化移动到更早的解码点；必要时对读取缓冲中的 CRLF/CR 做一次性归一
2. Writer: QuoteAndEscapeBytes 优化为预分配缓冲，避免大量 `Tmp := Tmp + ...`
3. 对关键变更追加注释与单元测试文档摘要

## 验证命令（Windows）
- 构建：tests/fafafa.core.csv/BuildOrTest.bat test
- 单套件运行示例：
  - tests\fafafa.core.csv\bin\tests.exe --suite=TTestCase_Reader_Escape_BOM --format=plainnotiming -r
  - tests\fafafa.core.csv\bin\tests.exe --suite=TTestCase_Reader_Multiline_NoEscape --format=plainnotiming -r
  - tests\fafafa.core.csv\bin\tests.exe --suite=TTestCase_Reader_Edge_More --format=plainnotiming -r
  - tests\fafafa.core.csv\bin\tests.exe --suite=TTestCase_Writer_Extremes --format=plainnotiming -r
  - tests\fafafa.core.csv\bin\tests.exe --suite=TTestCase_Reader_Quoted --format=plainnotiming -r

