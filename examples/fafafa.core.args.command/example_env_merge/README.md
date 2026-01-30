# Example: ENV/CONFIG → argv Merge

This example shows how to convert environment variables (and optionally a CONFIG file) to CLI tokens and merge them with process argv.

- Recommended precedence: CONFIG → ENV → CLI (later overrides earlier)
- Example mapping: APP_COUNT=3, APP_DEBUG= → ["--count=3", "--debug"]
- CONFIG flattening:
  - TOML tables flatten to dot-keys (lower-cased; '_' → '-')
  - Scalars → `--key=value`; arrays of scalars → repeated `--key=value`

Optional features (compile-time flags):
- `{$DEFINE FAFAFA_ARGS_CONFIG_TOML}` enables ArgsArgvFromToml
- `{$DEFINE FAFAFA_ARGS_CONFIG_JSON}` enables ArgsArgvFromJson

Build & run (Windows):

```
examples\fafafa.core.args.command\example_env_merge\build.bat
set APP_COUNT=3 & set APP_DEBUG= & examples\fafafa.core.args.command\example_env_merge\bin\example_env_merge.exe run --dry-run
```

Build & run (Linux/macOS):

```
cd examples/fafafa.core.args.command/example_env_merge
lazbuild example_env_merge.lpi
APP_COUNT=3 APP_DEBUG= ./bin/example_env_merge run --dry-run
```

Notes:
- Windows and Unix CLI styles are both supported; tokens starting with '/' are treated as options and are never considered values.
- With StopAtDoubleDash=False, the sentinel `--` is kept as a positional and the rest are also positionals.

- When EnableNoPrefixNegation=True, Windows forms '/no-xxx=value' and '/no-xxx:value' also map the base key 'xxx' to 'value' (and keep the literal no- key), preserving last-write-wins across long ('--') and Windows ('/') styles.
