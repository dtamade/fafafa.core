# Args Config JSON flattening rules

This document specifies how JSON config files are converted into argv-like tokens by ArgsArgvFromJson.

Principles
- Keys are flattened using dot-separated paths; names are normalized to lower-case and underscores become dashes
- Only scalar JSON values become tokens
- Arrays produce repeated tokens when elements are scalars
- Objects inside arrays are ignored (no tokens)
- Nulls are ignored

Details
- Object
  - For each key k: recurse with prefix `${prefix}.${lower-dash(k)}` (trim the leading dot when empty)
- Array
  - For each item i:
    - If item is a scalar (string/number/boolean): append `--${prefix}=${scalar-string}`
    - Else (object/array/null): ignore item
- Scalar
  - Emit `--${prefix}=${value}`
  - String: as-is
  - Number: textual representation (decimal separator '.')
  - Boolean: true/false
  - Null: ignored

Examples
- {"count":1,"debug":true} -> ["--count=1","--debug=true"]
- {"tags":["a","b"]} -> ["--tags=a","--tags=b"]
- {"items":[{"a":1},{"a":2}]} -> []
- {"app":{"db":{"host":"h"}}} -> ["--app.db.host=h"]
- {} -> []

Tests
- The suite tests/fafafa.core.test includes cases:
  - Scalars to argv
  - Arrays to repeated argv
  - Precedence merging (config < env < cli)
  - Array of objects ignored
  - Null ignored
  - Empty object/array -> empty argv
  - Deep object flattening

Implementation note
- See src/fafafa.core.args.config.pas: WalkJson/JSONScalarToString/AppendToken

