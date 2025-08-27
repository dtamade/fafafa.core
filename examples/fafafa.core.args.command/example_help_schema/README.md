# Example: Help Rendering with Options

This example prints usage for a command with schema.

You can customize rendering via TRenderUsageOptions:

- Fixed width: set environment variable `COLUMNS=100` or pass Options.width
- Disable wrapping: Options.wrap := False
- Keep registration order: Options.sortSubcommands := False
- Hide default marking: Options.markDefaultInChildren := False

Build & run (Windows):

```
examples\fafafa.core.args.command\example_help_schema\build.bat
examples\fafafa.core.args.command\example_help_schema\bin\example_help_schema.exe
```

Build & run (Linux/macOS):

```
cd examples/fafafa.core.args.command/example_help_schema
lazbuild example_help_schema.lpi
./bin/example_help_schema
```

