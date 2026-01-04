# Args Config JSON flattening rules

This document specifies how JSON config files are converted into argv-like tokens by ArgsArgvFromJson.

Principles
- Error handling: ArgsArgvFromJson never raises; it returns an empty argv on IO errors or JSON parse errors
- Root requirement: only a JSON object root is processed; array/scalar roots return an empty argv
- Keys are flattened using dot-separated paths; names are normalized to lower-case and underscores become dashes
- Only scalar JSON values become tokens
- Arrays produce repeated tokens when elements are scalars
- Objects inside arrays are ignored (no tokens)
- Nulls are ignored

Details
- Non-object root
  - If the JSON root is not an object (array/scalar/null): return []
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
- [1,2,3] -> []
- {"a":,} -> []
- {} -> []

Tests
- The suite tests/fafafa.core.test includes cases:
  - Scalars to argv
  - Arrays to repeated argv
  - Precedence merging (config < env < cli)
  - Array of objects ignored
  - Null ignored
  - Empty object/array -> empty argv
  - Invalid JSON -> empty argv (no raise)
  - Root array -> empty argv
  - Deep object flattening

Implementation note
- See src/fafafa.core.args.config.pas: WalkJson/JSONScalarToString/AppendToken

