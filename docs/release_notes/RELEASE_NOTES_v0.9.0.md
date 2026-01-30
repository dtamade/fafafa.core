# Release Notes — fafafa.core.ini v0.9.0

Date: 2025-08-19

## Highlights
- Full round-trip with comments/blank lines preserved (Entries + BodyLines)
- Dirty-aware write: modifications reassemble keys and apply write flags
- Read/Write flags:
  - Read: irfCaseSensitiveKeys, irfCaseSensitiveSections, irfDuplicateKeyError, irfInlineComment
  - Write: iwfSpacesAroundEquals, iwfPreferColon, iwfBoolUpperCase, iwfForceLF
- Locale-invariant floats
- CLI: tools/inifmt (verify + format)

## What’s new since previous pre-release
- Added file-level Entries capture and replay when not dirty
- Added Dirty semantics to prefer latest values over raw replay
- Added inline comment stripping (optional) and force-LF write option
- Expanded tests to 18+ covering round-trip/flags/edges; all green
- Added CLI and samples for quick checks

## Upgrade & Compatibility
- Public API remains stable; new flags are opt-in
- Default behavior:
  - Case-insensitive names; duplicate key overwrites previous
  - Write uses '=' without spaces; booleans as lower-case
  - Line endings follow platform unless iwfForceLF set
  - Inline comments NOT stripped unless irfInlineComment set

## Quick start
- Parse & write in code:

```
uses fafafa.core.ini;
var Doc: IIniDocument; Err: TIniError;
ParseFile('config.ini', Doc, Err, [irfInlineComment]);
SetBool(Doc, 'core', 'enabled', True);
var OutText := ToIni(Doc, [iwfSpacesAroundEquals, iwfBoolUpperCase]);
```

- CLI verify/format:
```
# verify round-trip
inifmt verify samples/ini/basic.ini

# format with flags (stdout)
inifmt format samples/ini/with_comments.ini --spaces --colon --bool-upper --lf

# in-place with inline-comment parsing
i nifmt format samples/ini/default_only.ini --inline-comment --spaces --lf --in-place
```

## Known limitations
- Inline comment stripping does not support escape sequences in quotes; comment chars inside quotes are preserved literally
- When replaying Entries (not dirty), write flags do not apply

## Next (post v0.9.0)
- Optional: escape-aware parser extensions
- Optional: additional dialect switches
- Performance smoke scripts (see tools/perf_ini)

