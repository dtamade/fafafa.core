# Upgrade & Adoption Guide — fafafa.core.args

## Positioning
- Lightweight kernel + opt-in extensions
- No implicit printing; caller renders help/errors

## Who should adopt Extensions?
- If you need a quick Usage rendering with flags/args, use Schema + RenderUsage
- If you want parent flags to appear in child commands, use Persistent flags (registration-time propagation)
- If you want ENV-based defaults, use ArgsArgvFromEnv and merge with argv (prefer CLI > ENV)

## Recommended migration steps (Core → Extensions)
1. Keep your existing Core-only integration unchanged (parsing + routing)
2. Incrementally attach specs to the commands you want to render help for
   - Create a minimal IArgsCommandSpec
   - Add flags/positionals you want documented
   - Call RenderUsage(Node) to get text; print at your discretion
3. For inherited defaults/flags across subcommands
   - Mark parent flags with SetPersistent(True) to propagate down when registering
   - Use First-Wins semantics to avoid overriding child’s own flags
4. For ENV defaults
   - Map env vars with ArgsArgvFromEnv('APP_')
   - Merge: merged := env ++ cli (or cli ++ env). Recommended precedence: CLI > ENV
   - Note: legacy aliases were removed; use ArgsArgvFrom* APIs.

## Non-goals (to avoid surprises)
- No automatic printing or process exit (you control it)
- No heavy DSL/annotations for schema
- No complex validation/diagnostics in core (mutex/depends/choices/range etc.)

## Examples to follow
- examples/fafafa.core.args.command/example_usage_default
- examples/fafafa.core.args.command/example_help_schema
- examples/fafafa.core.args.command/example_env_merge

