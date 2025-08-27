# TOML -> argv Flattening Spec (Draft)

Status: Draft for review
Scope: Minimal viable mapping consistent with current JSON behavior; easy to implement and reason about.

## Goals
- Deterministic, stable mapping from TOML to argv tokens for args.config
- Keep behavior aligned with JSON minimal rules to ease mental model
- Avoid ambiguous encodings; prefer skipping when unclear

## Key normalization
- Case-insensitive keys at lookup time; however we emit canonical form in tokens
- Normalize each segment when flattening:
  - Lowercase ASCII letters
  - Replace '_' with '-'
- Join path segments with '.'

Example
[server]
  Access_Key = "abc"
=> --server.access-key=abc

## Scalars
- Booleans → "true"/"false"
- Numbers → textual string as-is
- Strings → as-is (no additional quoting)
- Datetime → use the original textual representation when available; else ISO-8601

Token form: --<path>=<value>

## Arrays
- Scalar arrays → repeated tokens in encounter order
  - [1,2,3] under key k → --k=1 --k=2 --k=3
- Arrays of arrays → skipped (ambiguous)
- Arrays of tables/objects → skipped (minimal rules)

Rationale: Keep parity with JSON current behavior, which emits only scalars and scalar arrays.

## Tables / nesting
- Descend recursively through tables; join keys with '.' as the path separator
- For inline tables: treat as normal tables

Example
[build]
  [build.env]
    node_env = "production"
=> --build.env.node-env=production

## Null / missing
- TOML does not have null; if a value is absent, it doesn't produce any token

## Precedence (outside of this mapping step)
- Merge order for args: CONFIG ++ ENV ++ CLI (last wins)
- This spec only covers how CONFIG becomes argv

## Examples

1) Scalars
[app]
  name = "core"
  count = 3
  debug = true
=> --app.name=core --app.count=3 --app.debug=true

2) Scalar array
files = ["a.txt", "b.txt"]
=> --files=a.txt --files=b.txt

3) Nested
[remote]
  [remote.origin]
    url = "https://example"
=> --remote.origin.url=https://example

4) Arrays of tables (skipped)
[[items]]
  name = "a"
[[items]]
  name = "b"
=> (no tokens)

5) Mixed case and underscores
[API]
  ACCESS_KEY_ID = "x"
=> --api.access-key-id=x

## Non-goals (defer)
- Encoding positions (items.0.name) or object-array elements
- Custom separators, quoting, or escape policies beyond what args parser handles
- Complex merging inside CONFIG step

## Implementation notes
- Reuse JSON scalar emitters (to-string functions) where possible
- TOML reader must provide visitors or typed access; if an object/array node is not a scalar nor scalar-array, skip
- Keep traversal iterative where feasible to avoid deep recursion

