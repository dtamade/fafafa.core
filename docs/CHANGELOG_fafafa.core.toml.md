# fafafa.core.toml Changelog

## [Unreleased]
- Reader: Unify Unicode escape handling for quoted keys and strings
  - Both now use TryReadUnicodeEscape4/8
  - Strictly require \uXXXX, \UXXXXXXXX; forbid surrogate range D800–DFFF; max code point ≤ 0x10FFFF
  - Unknown escapes are treated as errors (parse fails and bubbles up)
- Reader: Quoted key must be closed; unclosed quoted keys now fail with a proper error
- Reader: Remove divergent implementations; quoted-key parsing delegates to ReadString for full consistency
- Tests: Add regression tests for Unicode in keys (positives and negatives); all tests pass
- Housekeeping: Removed temporary debug prints

## [0.6.x]
- Various improvements to arrays, writer flags, and dotted key handling.

