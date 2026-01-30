# fafafa.core.aliases — 常用别名与辅助

目标
- 提供常用的类型别名与轻量泛型辅助，提升易用性与可读性

内容
- 别名
  - TOptionStr = TOption<string>
  - TOptionInt = TOption<Integer>
  - TResultIntStr = TResult<Integer,string>
- 泛型辅助
  - Some<T>(V): TOption<T>
  - None<T>: TOption<T>
  - Ok<T,E>(V): TResult<T,E>
  - Err<T,E>(EVal): TResult<T,E>

示例
```pascal
uses fafafa.core.aliases;
var O: TOptionInt := specialize Some<Integer>(7);
var R: TResultIntStr := specialize Ok<Integer,string>(1);
```

关联
- Option：docs/fafafa.core.option.md（FromNullable、组合子、互转）
- Result：docs/fafafa.core.result.md（组合子、调试输出）

