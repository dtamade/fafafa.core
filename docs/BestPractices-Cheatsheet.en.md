# fafafa.core.fs Best Practices (Cheatsheet)

Compact, copy-paste friendly guidance for WalkDir, IFsFile, sharing, errors, path safety, perf, and tests.

## WalkDir
- Memory-friendly on large trees: `UseStreaming=True`, `Sort=False` (non-stable order)
- Need stable order: `Sort=True` (buffer + stable sort)
- Prune early: `PreFilter` (skip .git, node_modules, hidden trees)
- Select results: `PostFilter` (does not affect recursion)
- Scope control: set `MaxDepth`
- Observe: pass `Stats` to collect Dirs/Files/Errors

Streaming template
```pascal
function OnVisit(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // TODO: process entry; return False to stop early
  Result := True;
end;

function PreSkipHidden(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
var name: string;
begin
  name := ExtractFileName(APath);
  Result := (name = '') or (name[1] <> '.');
end;

var opts: TFsWalkOptions; rc: Integer;
begin
  opts := FsDefaultWalkOptions;
  opts.UseStreaming := True;
  opts.Sort := False;
  opts.PreFilter := @PreSkipHidden;
  rc := WalkDir('root', opts, @OnVisit);
end;
```

Buffer + stable sort
```pascal
var opts: TFsWalkOptions; rc: Integer;
begin
  opts := FsDefaultWalkOptions;
  opts.Sort := True;
  rc := WalkDir('root', opts, @OnVisit);
end;
```

## IFsFile
- Modes: `fomRead`, `fomWrite`(truncate), `fomReadWrite`, `fomAppend`
- Strings/encoding: specify `TEncoding`; avoid implicit conversions
- Random I/O: prefer `PRead/PWrite` (falls back to Seek+Read/Write if not optimized)

Basic R/W
```pascal
var F: IFsFile; buf: array[0..4095] of Byte; n: Integer;
begin
  F := NewFsFile;
  F.Open('data.bin', fomReadWrite);
  try
    n := F.Read(buf, SizeOf(buf));
    // ...
    F.Write(buf, n);
    F.Flush;
  finally
    F.Close;
  end;
end;
```

## Sharing (Windows)
- `TFsShareMode = set of (fsmRead, fsmWrite, fsmDelete)`
- Windows: maps to CreateFileW FILE_SHARE_READ/WRITE/DELETE
- Unix: currently ignored (no CreateFile-like share flags). If needed, use advisory locks (fcntl) at a higher layer
- Compatibility: empty set `[]` defaults to "full-share" for backward compatibility (READ|WRITE|DELETE)

Common combos
```pascal
// read-only, share-read only (blocks writers)
F.Open('x.bin', fomRead, [fsmRead]);

// read-write, share read+write (allows another reader)
F.Open('x.bin', fomReadWrite, [fsmRead, fsmWrite]);

// prevent being deleted: do not include fsmDelete
F.Open('x.bin', fomReadWrite, [fsmRead, fsmWrite]);
```

## Errors
- Exception semantics (recommended): catch `EFsError` and branch on `ErrorCode`
```pascal
try
  F.Open('maybe.bin', fomRead);
except
  on E: EFsError do
  begin
    // case E.ErrorCode of ...
  end;
end;
```
- No-exception semantics: `TFsFileNoExcept` returns unified negative codes; use helpers like `IsNotFound`, `IsPermission`

## Path safety
- Always `ValidatePath`; sanitize with `SanitizePath`/`SanitizeFileName`
- Compose with `Join/Normalize/ToNativePath`; avoid manual separators
- Compare with `PathsEqual` (Windows case-insensitive)

## Symlink & depth
- Default: do not follow symlinks; enable only when needed
- Combine with `MaxDepth` to avoid deep chains/loops

## Performance
- WalkDir: UseStreaming + PreFilter pruning; toggle IncludeFiles/IncludeDirs
- I/O: batch small writes; use buffered implementations when needed; avoid hot-path allocations
- Strings: reuse buffers; avoid frequent encoding conversions

## Testing (fpcunit)
- Temp dirs: random name + try-finally cleanup
- Conditional asserts per platform (symlink, sharing)
- Set comparison: sort before compare to avoid order sensitivity
- Enable `heaptrc` to catch leaks

- Test registration: prefer closures (reference to procedure), avoid "is nested" to prevent static-link issues after RegisterTests → see docs/partials/testing.best_practices.md

## Terminal testing (fafafa.core.term)
- Environment: `TestEnv_AssumeInteractive(Self)`; if not, `TestSkip` and `Exit`
- Scope: `term_init; try ... finally term_done; end;`
- Checks: IsATTY → term_size>0 → term_name not empty/unknown
- Feature gates: `term_support_*` before calling; restore in `finally`
- Skip compatibility: raises `ESkipTest` if available, else soft "SKIP: ..."

Template: minimal interactive test
```pascal
if not TestEnv_AssumeInteractive(Self) then Exit;
term_init; try
  CheckTrue(term_clear);
finally
  term_done;
end;
```

See also: docs/API.md, docs/fafafa.core.fs.ifile.md, docs/BestPractices-Cheatsheet.md, docs/partials/term.testing.en.md
