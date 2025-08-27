# fafafa.core.toml Testing Guidelines (断言规范)

目标：使 TOML 测试稳定、可维护、平台无关。

## 1. 错误断言（必须）
- 先断言 HasError，再断言错误码：
  - `AssertTrue(Err.HasError);`
  - `AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));` 或更具体的 `tecDuplicateKey`/`tecTypeMismatch`。
- 禁止依赖 Err.Message 文本断言（不同平台/实现可能轻微差异）。
- 如需补充信息，可仅将 Message 打印到调试输出，但不参与断言。

## 2. Writer/Reader 用例风格
- 优先使用 Builder 构建数据（避免原始文本解析差异引入不稳定）：
  - `LDoc := NewDoc....Build;`
- Writer 快照类测试：尽量断言关键片段存在、顺序关系、空行存在性，而非完整字符串对比。
- Reader 负例：给出最小复现的非法文本，断言错误码，不断言完整消息。

## 3. 命名与结构
- 变量命名：`Doc`、`Err`、`Ok`、`S` 等简洁一致。
- 解析入口统一：`Parse(RawByteString('...'), Doc, Err)`。
- 路径与键名：必要时用 quoted 键，保持与实现一致的转义。

## 4. 典型示例
```pascal
Err.Clear;
AssertFalse(Parse(RawByteString('key  value'), Doc, Err));
AssertTrue(Err.HasError);
AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
```

```pascal
B := NewDoc;
LDoc := B
  .PutStr('app_version','1.2.3')
  .PutStr('msg','hello' + LineEnding + 'world "quote" \\ ' + #9)
  .Build;
S := String(ToToml(LDoc, [twfTightEquals, twfPretty]));
AssertTrue(Pos('app_version="1.2.3"', S) > 0);
AssertTrue(Pos('msg="hello', S) > 0);
```

## 5. 负例清单参考
- 无等号、非法转义、非法/越界 unicode、非法下划线（整数/浮点/指数）、重复键、路径冲突、NaN/Inf。

## 6. 运行命令
- `tests/fafafa.core.toml/BuildOrTest.bat test`

## 7. 变更约束
- 新增或修改测试时，若需断言错误，必须基于 Err.Code；出现 Err.Message 断言将被驳回（见 pre-commit 检查）。

