# fafafa.core.xml tests

本目录包含 XML Reader/Writer 的 FPCUnit 测试与本地运行脚本。

## 常用命令（在仓库根目录执行）

- 构建 + 全量（plain）：
  - `tests\fafafa.core.xml\BuildOrTest.bat test`
- 构建 + 产出 JUnit：
  - `tests\fafafa.core.xml\BuildOrTest.bat test-junit`
- 仅运行可执行（手动方式）：
  - 先建目录：`mkdir tests\fafafa.core.xml\bin\junit`
  - JUnit 到 stdout 并重定向：
    - `tests\fafafa.core.xml\bin\tests_xml.exe --all --format=junit > tests\fafafa.core.xml\bin\junit\tests_xml.junit.xml 2> tests\fafafa.core.xml\bin\heaptrc.txt`

说明：脚本已内置
- 预创建 `bin` 与 `bin\junit` 目录
- 设置 `FAFAFA_TEST_SILENT_REG=1` 静默初始化输出
- 将 heaptrc（-gh）输出重定向至 `bin\heaptrc.txt`，避免“卡住”的错觉

## 排障速查

1) 列出用例（仅枚举）：
   - `tests_xml.exe --list 2>nul`
2) 全量（plain，不写文件）：
   - `tests_xml.exe --all -p --format=plain 2>nul`
3) 全量 JUnit（走 stdout）：
   - `tests_xml.exe --all --format=junit > bin\junit\tests_xml.junit.xml 2> bin\heaptrc.txt`

若 1、2 正常而 3 异常，通常是输出路径问题。

## 测试约定与最佳实践

- 任何扫描循环必须“每轮前进或抛错”，避免死循环
- 流式路径返回给上层的文本/名称/属性值一律持久化（Owned）
- 字符引用解码（DecodeEntities）
  - 命名实体逐字匹配；数字实体严格边界与分号检查
  - 超范围码点与畸形实体安全退化（不崩溃、不死循环）
  - 标准 UTF-8 输出（1~4 字节）

