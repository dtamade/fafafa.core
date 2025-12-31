# CHANGELOG — fafafa.core.args

## Core v1.0.0 (proposed)

## Extensions v1.2.0 (proposed, opt-in)
- Usage rendering improvements (backward compatible):
  - New TRenderUsageOptions: width (0=auto from COLUMNS or fallback 80), wrap, sortSubcommands, markDefaultInChildren
  - RenderUsage(Node) retains default behavior; new overload accepts options
  - Output now includes a Commands section (optional sorting) with [default] marking
  - Aliases are shown for commands and flags
  - Flags/Args columns are aligned; descriptions soft-wrapped to width
- Tests:
  - Relax spacing-sensitive assertions in usage tests
  - Add default-child routing when next token is an option
  - Ensure JUnit testsuite header includes timestamp and hostname

- Parsing core (stable):
  - GNU/Windows styles, double-dash sentinel, case-insensitive keys (opt)
  - Short-flags combo (opt), negative-number ambiguity control, no-prefix negation
- Subcommand routing (stable):
  - Arbitrary depth, aliases, default subcommand, Run/RunPath
- Behavior:
  - No implicit printing; return integer codes only. Help/errors are caller-owned
- Quality:
  - Unit tests all green. API considered frozen for Core

## Extensions v1.1.0 (proposed, opt-in)
- Light schema (for rendering/metadata, not a heavy DSL)
- Usage rendering: RenderUsage(Node)
  - Prints child list as "name: desc"; if schema attached, appends Flags/Args sections
- ENV → argv: ArgsArgvFromEnv('APP_')
- Persistent flags (registration-time propagation):
  - Parent → child, first-wins (child keeps same-name flag). Visible in Usage

### Reserved / not implemented yet
- CONFIG → argv (opt-in): ArgsArgvFromToml / ArgsArgvFromJson (enable via {$DEFINE FAFAFA_ARGS_CONFIG_TOML} / {$DEFINE FAFAFA_ARGS_CONFIG_JSON}); returns empty array when disabled
- ArgsArgvFromYaml stub (reserved)
- Completion generators (bash/zsh/fish/pwsh) under consideration
- Advanced validation/diagnostics (mutex/depends/choices/range, did-you-mean), heavy styling/i18n — deferred

### Notes
- All extensions are optional and do not change core behavior
- Callers decide when/how to render or print help text

