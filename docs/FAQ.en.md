# Frequently Asked Questions (FAQ)

This FAQ collects common questions across subsystems. First batch covers fafafa.core.fs.

## fafafa.core.fs

### 1) Why does `WalkDir('invalid_root', ...)` return 0 after setting `OnError = weaContinue`?
- Semantics: `weaContinue` means “ignore this error and continue”. When the root path itself is invalid, the entire traversal is equivalent to an empty traversal, hence returns 0.
- Default (OnError=nil): Preserve legacy behavior; an invalid root path immediately returns a negative unified error code.
- Tip: If you need to record the error but not abort, log it inside `OnError` and return `weaContinue`. Use `weaSkipSubtree` to skip the current subtree selectively.

Minimal snippet:

```pascal
function TWalker.OnErrContinue(const Path: string; Error, Depth: Integer): TFsWalkErrorAction;
begin
  Result := weaContinue;
end;

procedure TWalker.Run;
var Opts: TFsWalkOptions; Rc: Integer;
begin
  Opts := FsDefaultWalkOptions; Opts.OnError := @OnErrContinue;
  Rc := WalkDir('Z:\not_exists', Opts, @OnVisit);
  // Rc = 0 (root invalid but ignored by continue policy)
end;
```

### 2) What is the exception-safety semantics of OpenFileEx?
- `OpenFileEx(Path, Opts): IFsFile` returns an IFsFile opened with given options.
- On failure it raises `EFsError` and guarantees the internal instance is freed on the exceptional path (factory uses try..except).
- Shorthands: `FsOptsReadOnly / FsOptsWriteTruncate / FsOptsReadWrite` are aliases for `FsOpenOptions_*`.

### 3) How is TFsShareMode mapped on Windows/Unix?
- Windows: mapped to CreateFileW share flags (FILE_SHARE_READ/WRITE/DELETE).
- Unix: no CreateFile-like sharing flags; TFsShareMode is currently ignored. If you need sharing semantics, consider advisory locking (fcntl) at a higher layer.

More:
- README_fafafa_core_fs.md (module overview, examples, stats & error model)
- docs/API.md (API reference with OnError and OpenFileEx/FsOpts* notes)
- docs/EXAMPLES.md (complete examples and a small troubleshooting section)

