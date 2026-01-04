# Release Notes — fafafa.core.args

## Positioning
- Lightweight kernel + opt-in extensions
- Caller controls all output; library returns integer codes only

## Core v1.0.0
- Parsing core (stable)
  - GNU/Windows styles, double-dash sentinel
  - Case-insensitive keys (opt), short-flags combo (opt)
  - Negative-number ambiguity control, no-prefix negation
- Subcommand routing (stable)
  - Arbitrary depth, aliases, default subcommand, Run/RunPath
- Behavior
  - No implicit printing
  - API frozen for Core; unit tests all green

## Extensions v1.1.0 (opt-in)
- Light schema for rendering/metadata
- Usage rendering: RenderUsage(Node)
  - Child list "name: desc"; if spec attached, appends Flags/Args
- ENV → argv: ArgsArgvFromEnv('APP_') (maps APP_FOO=1 → --foo=1)
- Persistent flags
  - Registration-time propagation (parent → child)
  - First-wins (child keeps same-name flag)

## Reserved / Deferred
- CONFIG → argv (opt-in): ArgsArgvFromToml / ArgsArgvFromJson (enable via {$DEFINE FAFAFA_ARGS_CONFIG_TOML} / {$DEFINE FAFAFA_ARGS_CONFIG_JSON}); returns empty array when disabled or on read/parse errors (no raise). JSON requires object root
- YAML → argv: ArgsArgvFromYaml (stub)
- Completion generators (bash/zsh/fish/pwsh): under consideration
- Advanced validation/diagnostics (mutex/depends/choices/range, did-you-mean): deferred

## Examples
- examples/fafafa.core.args.command/example_usage_default
- examples/fafafa.core.args.command/example_help_schema
- examples/fafafa.core.args.command/example_env_merge

## Tagging Strategy (recommendation)
- Use a single repository tag per release (e.g., v1.0.0)
  - Include module-specific sections in Release Notes
  - Simpler process and consistent repo-wide snapshot
- If component tags are required by tooling, mirror the top-level tag naming with suffixes

## Quality & Contracts Checklist
- No implicit printing (caller renders help/errors)
- Register is First-Wins; no Execute(nil) probes
- Default subcommand fallback when no more non-options or next token is an option
- Persistent flags propagate at registration-time; same-name flags not overridden
- Enhancements are optional and non-breaking

