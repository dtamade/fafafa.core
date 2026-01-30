# fafafa.core.ini

Current version: v0.9.0

A lightweight INI parser/writer with order and comments preservation for Free Pascal/Lazarus.

## Highlights
- Preserves section order and keys order
- Round-trip friendly: comments and blank lines are preserved (both section header pad and section body lines)
- File-level Entries captured (Prelude/SectionHeader/Key/Comment/Blank); when not dirty, `ToIni` replays the original text
- Locale-invariant float parsing/formatting (decimal separator is '.')
- Read/Write flags for common behaviors

## Default behavior
Unless specified otherwise via flags:
- Section/key names are case-insensitive
- Duplicate key overwrites previous (no error)
- Write path uses '=' as separator (no spaces around), and boolean values are lower-case `true/false`
- Line endings follow the platform (Windows CRLF, Unix LF). Use `iwfForceLF` to force LF on write; use `iwfTrailingNewline` to ensure a final newline only when output is non-empty
- Inline comments are NOT stripped by default when parsing. Enable `irfInlineComment` to strip content after ';' or '#'
- Output encoding is UTF-8 without BOM by default; use `iwfWriteBOM` to emit UTF-8 BOM when writing to file

## inifmt (CLI)
Quick examples:
- Verify round-trip: `inifmt verify samples/ini/basic.ini`
- Format with flags to stdout: `inifmt format samples/ini/with_comments.ini --spaces --colon --bool-upper --lf --stable-order --trailing-newline`
- In-place format with inline-comment read: `inifmt format samples/ini/default_only.ini --inline-comment --allow-quoted-value --spaces --lf --in-place`

Options:
- Read flags:
  - `--inline-comment` → irfInlineComment
  - `--allow-quoted-value` → irfAllowQuotedValue
  - `--strict-key-chars` → irfStrictKeyChars
  - `--case-sensitive-keys` → irfCaseSensitiveKeys
  - `--case-sensitive-sections` → irfCaseSensitiveSections
  - `--duplicate-key-error` → irfDuplicateKeyError
- Write flags:
  - `--spaces` → iwfSpacesAroundEquals
  - `--colon` → iwfPreferColon
  - `--bool-upper` → iwfBoolUpperCase
  - `--lf` → iwfForceLF
  - `--stable-order` → iwfStableKeyOrder
  - `--trailing-newline` → iwfTrailingNewline (only when output non-empty)
  - `--write-bom` → iwfWriteBOM (only via file output path)
- Output control:
  - `--in-place` overwrite input file
  - `--output <file>` write to specific file (mutually exclusive with `--in-place`)

## Basic usage

```pascal
uses fafafa.core.ini;

var Doc: IIniDocument; Err: TIniError;
if Parse(RawByteString('[core]'+LineEnding+'name = x'+LineEnding), Doc, Err) then
begin
  // read
  var S: String;
  if Doc.TryGetString('core','name', S) then ;
  // write via facade helpers
  SetBool(Doc, 'core', 'enabled', True);
  // emit
  var OutText := ToIni(Doc, [iwfSpacesAroundEquals]);
end;
```

## Read flags (TIniReadFlag)
- `irfCaseSensitiveKeys`: key names are case-sensitive
- `irfCaseSensitiveSections`: section names are case-sensitive
- `irfDuplicateKeyError`: duplicate key triggers error (default is overwrite)

Pass flags to any `Parse/ParseFile/ParseStream` overload:

```pascal
Parse(Text, Doc, Err, [irfCaseSensitiveKeys, irfDuplicateKeyError]);
```

## Write flags (TIniWriteFlag)
- `iwfSpacesAroundEquals`: add spaces around the separator when reassembling
- `iwfPreferColon`: prefer ':' instead of '=' as the separator when reassembling
- `iwfBoolUpperCase`: output booleans as `TRUE/FALSE` when reassembling

Note: When the document is not dirty and there are captured Entries, `ToIni` replays original raw lines and write flags do not apply. Write flags only affect the reassembled path (no body lines or document marked dirty).

## Dirty/Entries semantics
- The parser captures file-level Entries (with Raw text) and each section's HeaderPad and BodyLines
- The document is marked dirty when any SetString/SetInt/SetBool/SetFloat is called
- `ToIni` behavior:
  1) If NOT dirty and Entries exist: replay Entries (full-file faithful round-trip)
  2) Else if a section has BodyLines and NOT dirty: replay BodyLines for that section
  3) Else: reassemble keys (applying write flags)


## Samples quick demo
- basic.ini
  - Verify: `inifmt verify samples/ini/basic.ini`
- with_comments.ini
  - Format to stdout: `inifmt format samples/ini/with_comments.ini --spaces --colon --bool-upper --lf --stable-order --trailing-newline`
- default_only.ini
  - Format with inline-comment read: `inifmt format samples/ini/default_only.ini --inline-comment --spaces --lf --in-place`
- duplicate_sections.ini
  - Replay (not dirty): `inifmt verify samples/ini/duplicate_sections.ini`  // preserves two [s] headers and comments
  - Note: merging duplicate sections into a single header happens on reassembly only when the document is dirty (i.e., after modifications via API), which CLI does not perform by design
- inline_comment_quotes.ini
  - Strip inline comment (keep quotes removed): `inifmt format samples/ini/inline_comment_quotes.ini --inline-comment`
  - Preserve outer quotes under inline-comment: `inifmt format samples/ini/inline_comment_quotes.ini --inline-comment --allow-quoted-value`
- BOM example
  - Write with BOM to file: `inifmt format samples/ini/basic.ini --spaces --lf --write-bom --output out_with_bom.ini`

This design ensures faithful round-trip by default, and correctness after modifications.

## Floats
- `TryGetFloat` uses `DecimalSeparator='.'`
- `PutFloat` writes with `.` regardless of locale

## Tips
- Default section is the empty section name `''` (keys before the first section header)
- You can mix `=` and `:` in the source; on reassembly the chosen separator depends on write flags

## Duplicate sections (same-named [section])
- Allowed by default. The parser aggregates keys of the same-named sections into one logical section (view)
- Not dirty (no modifications) and Entries captured: `ToIni` replays original raw text, preserving multiple identical headers and comments/blank lines between them
- Dirty (after Set*/Remove*): `ToIni` reassembles and emits a single header per section name; keys are merged
- Ordering: with `iwfStableKeyOrder`, keys are sorted; otherwise internal order is used


## Testing
- See tests under `tests/fafafa.core.ini/` for usage samples, round-trip cases, and behavior when dirty.



## Troubleshooting
- Duplicate key error: If you see an error like `Duplicate key`, you likely enabled `irfDuplicateKeyError`. Either deduplicate the file or remove this flag to allow last-write-wins.
- Case sensitivity: If `TryGet*` fails after you enabled `irfCaseSensitiveKeys` or `irfCaseSensitiveSections`, double-check the exact casing of keys/section names.
- Entries vs. flags: When a document is not dirty and Entries exist, `ToIni` replays original raw lines. Write flags apply only to the reassembly path.
- Mixed separators: Source may contain both `=` and `:`. Reassembly uses `iwfPreferColon` or `=` by default; original raw lines are preserved when replayed.
