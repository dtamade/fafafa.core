# fafafa.core.json module guide (English)

High‑performance JSON with zero‑copy access, immutable/mutable models, iterators, JSON Pointer (RFC 6901), and JSON Patch (RFC 6902). Provides a small, modern facade with convenient helpers for common tasks.

> Recommended: see docs/json-utf8.md for UTF‑8 best practices on reading/comparing strings to avoid system codepage issues.


- Parse/Serialize: immutable document + mutable document
- Iterate: array/object zero‑allocation iteration
- Pointer/Patch: RFC‑compliant Pointer and Patch helpers
- Facade helpers: TryGet / ForEach / Typed TryGet / OrDefault

## Quick Start (Facade)

```pascal
uses fafafa.core.json, fafafa.core.json.core;

var R: IJsonReader; W: IJsonWriter; Doc: IJsonDocument; V: IJsonValue; S: String;
begin
  R := CreateJsonReader(nil);
  Doc := R.ReadFromString('{"a":1,"b":[true,null],"c":"hi"}', []);

  // Pointer
  V := JsonPointerGet(Doc, '/b/0'); // => true

  // TryGet object key / array item
  if JsonTryGetObjectValue(Doc.Root, 'a', V) then Writeln(V.GetInteger);
  if JsonTryGetArrayItem(Doc.Root, 0, V) then Writeln(V.GetType);

  // ForEach (can early-stop by returning False)
  JsonArrayForEach(Doc.Root, function(I: SizeUInt; Item: IJsonValue): Boolean
  begin
    if Item.IsBoolean then Writeln('bool');
    Result := True;
  end);

  JsonObjectForEach(Doc.Root, function(const Key: String; Val: IJsonValue): Boolean
  begin
    Writeln(Key);
    Result := True;
  end);

  // Raw-key object ForEach (avoid String allocation for keys)
  JsonObjectForEachRaw(Doc.Root, function(KeyPtr: PChar; KeyLen: SizeUInt; Val: IJsonValue): Boolean
  begin
    // Convert to String only if needed:
    var Key: String; SetString(Key, KeyPtr, KeyLen);
    Result := True;
  end);


  // Typed TryGet / OrDefault (never throws)
  var b: Boolean; i: Int64; u: UInt64; f: Double; str: String;
  if JsonTryGetBool(V, b) then Writeln(b);
  i := JsonGetIntOrDefault(V, -1);
  u := JsonGetUIntOrDefault(V, 0);
  f := JsonGetFloatOrDefault(V, 0.0);
  str := JsonGetStrOrDefault(V, '');

  // Write back
  W := CreateJsonWriter;
  S := W.WriteToString(Doc, [jwfPretty]);
  Writeln(S);
end;
```

## Reader / Writer Flags (common)
- Reader (TJsonReadFlags)
  - jrfAllowComments
  - jrfAllowTrailingCommas
  - jrfStopWhenDone
  - jrfAllowInfNan
  - jrfAllowInvalidUnicode
  - JsonObjectForEachRaw(Obj, (keyPtr, keyLen, v) => bool) // avoid key String allocation in hot paths

- Writer (TJsonWriteFlags)
  - jwfPretty
  - jwfEscapeSlashes
  - jwfAllowInfNanAsNull (otherwise NaN/Inf cause error)

## Facade helpers overview
- JsonPointerGet(ARoot|ADoc, '/path')
- JsonTryGetObjectValue(Obj, 'key', out V) / JsonTryGetArrayItem(Arr, idx, out V)
- JsonArrayForEach(Arr, (i, v) => bool) / JsonObjectForEach(Obj, (key, v) => bool)
- Typed TryGet: JsonTryGetInt/UInt/Bool/Float/Str
- OrDefault: JsonGetIntOrDefault/UInt/Bool/Float/Str

## JSON Pointer / JSON Patch
- Pointer (RFC 6901): `JsonPointerGet(ADoc|ARoot, '/path/to/value')`
  - Empty pointer returns root
  - Handles `~1` (/) and `~0` (~) unescaping
- Merge Patch (RFC 7386) and JsonPatch (RFC 6902)
  - See src/fafafa.core.json.patch*.pas and tests for examples

## Fluent API (overview)
- Convenient building and access (see src/fafafa.core.json.fluent.pas)
- Works well with Pointer and facade helpers

## Performance and memory
- Parsing: single document buffer, zero‑copy for strings/numbers, compact array/object layout
- Iteration: iterators traverse the in‑place buffer; no temporary collections
- Object keys: object ForEach converts the key to a transient String; values are wrapped zero‑copy
- Writer: escaping controlled by flags; NaN/Inf behavior controlled by flags
- Reader default allocator: when IJsonReader is created without an explicit allocator (Allocator=nil), ReadFromString/ReadFromStringN fall back to GetRtlAllocator to avoid “Invalid allocator”.
- Raw-key object iteration: use JsonObjectForEachRaw to avoid transient key String allocation in hot paths.


Tips:
- Prefer ForEach over manual indexing when iterating large containers
- Combine ForEach + Typed TryGet to minimize string comparisons in hot paths

## Compatibility and exceptions
- IJsonValue.Get* throws EJsonValueError when the type mismatches (explicit semantics)
- All TryGet/OrDefault never throw:
  - TryGet: returns False and sets out param to default
  - OrDefault: returns the provided default
- EJsonParseError exposes Code/Position/Line/Column

## Example: combine ForEach + TryGet
```pascal
var R: IJsonReader; Doc: IJsonDocument; V: IJsonValue; sum: Int64 = 0;
R := CreateJsonReader(nil);
Doc := R.ReadFromString('{"nums":[1,2,3],"ok":true}', [jrfAllowComments]);
if JsonTryGetObjectValue(Doc.Root, 'nums', V) then
  JsonArrayForEach(V, function(I: SizeUInt; Item: IJsonValue): Boolean
  var n: Int64; ok: Boolean;
  begin
    ok := JsonTryGetInt(Item, n); if ok then Inc(sum, n);
    Result := True;
  end);
Writeln('sum=', sum);
```

## Testing
- Run tests/fafafa.core.json/BuildOrTest.bat test
- Suite covers: Reader/Writer, Pointer, Patch, Mutable, Fluent, Facade (TryGet/ForEach/Typed/OrDefault)

