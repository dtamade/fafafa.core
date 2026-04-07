# fafafa.core.contracts Examples

这个目录放 `fafafa.core.contracts` 的最小示例。目标是固定 strict L0 前置条件 helper 的 today contract，而不是替代 tests 里的双模式验证。

## 当前推荐入口

Linux/macOS：

```bash
cd examples/fafafa.core.contracts
bash BuildOrRun.sh
```

只构建：

```bash
cd examples/fafafa.core.contracts
bash BuildOrRun.sh build
```

Windows：

```cmd
cd examples\fafafa.core.contracts
BuildOrRun.bat
```

## 当前脚本行为

- `BuildOrRun.sh` / `BuildOrRun.bat` 当前都只构建并运行 `example_contracts_basics.lpi`
- 当前示例覆盖 `ContractsRequire`、`ContractsRequireAssigned` 的正常路径与异常捕获路径
- `NoContracts` build 模式下的 no-op 语义仍以 `tests/fafafa.core.contracts/BuildOrTest.*` 为准
