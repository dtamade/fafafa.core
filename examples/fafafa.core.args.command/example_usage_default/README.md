# Example: Default Subcommand and Caller-Owned Help

This example shows how a default subcommand is invoked when:
- No more non-option tokens are provided
- The next token is an option (e.g., --json)

It also demonstrates that help/output is owned by the caller (no implicit printing from the library).

Expected output snippets:
- --help shows a list of subcommands (e.g., "remote: List remotes")
- When running `remote --json`, the default subcommand runs and you should see a line indicating the handler was executed (the exact text comes from the example code)

Build & run (Windows):

```
examples\fafafa.core.args.command\example_usage_default\build.bat
examples\fafafa.core.args.command\example_usage_default\bin\example_usage_default.exe --help
examples\fafafa.core.args.command\example_usage_default\bin\example_usage_default.exe remote --json
```

Build & run (Linux/macOS):

```
cd examples/fafafa.core.args.command/example_usage_default
lazbuild example_usage_default.lpi
./bin/example_usage_default --help
./bin/example_usage_default remote --json
```

