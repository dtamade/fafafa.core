# fafafa.core.term Testing Best Practices (includeable partial)

> Goal: Make tests that depend on real terminal capabilities runnable and reliable across environments (interactive/non‑interactive, Windows/TTY emulators).

## 1) Unified skip and environment assumption

- Use TestSkip(TestCase, Reason) for explicit skip
  - Newer FPCUnit: raises ESkipTest → recorded as Skipped
  - Older FPCUnit: falls back to a soft skip message "SKIP: …"
- Use TestEnv_AssumeInteractive(Self): Boolean to decide if an interactive TTY is present
  - Checks (any failure → skip):
    1) IsATTY is true (if available)
    2) term_init succeeds
    3) term_size(w,h) returns positive size
    4) term_name is non‑empty and not "unknown"

Recommended pattern
- At test start:
  if not TestEnv_AssumeInteractive(Self) then Exit;
- For call chains that require a live term_current (e.g., GetCapabilities), always scope term_init/term_done:
  term_init; try … finally term_done; end;

## 2) Common templates

- Minimal interactive path:
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init; try
    CheckTrue(term_clear);
  finally term_done; end;

- Feature toggles with detection:
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init; try
    if term_support_alternate_screen then begin
      CheckTrue(term_alternate_screen_enable(True));
      CheckTrue(term_alternate_screen_disable);
    end else
      CheckTrue(True, 'alt screen not supported: skipped');
  finally
    if term_support_alternate_screen then term_alternate_screen_disable;
    term_done;
  end;

## 3) Windows specifics

- Quick Edit guard: temporarily disable Quick Edit while mouse is enabled; restore on exit
- Unicode input: exercise ReadConsoleInputW path; synthesize Emoji/SMP chars; ensure parsing does not crash
- ConsoleMode toggles: restored by internal guards; avoid asserting raw bitfields here (cover in dedicated tests)

## 4) Expectations in non‑interactive environments

- Tests requiring a real terminal: should be Skipped (or soft‑skipped), not Failed
- Algorithmic/structural tests: should pass everywhere

## 5) Run and rebuild

- One‑shot rebuild and test (Windows):
  tests\\fafafa.core.term\\BuildOrTest.bat rebuild
  tests\\fafafa.core.term\\BuildOrTest.bat test

- PowerShell helper:
  cd tests\\fafafa.core.term
  powershell -ExecutionPolicy Bypass -File .\\run-tests.ps1 -Rebuild

## 6) Troubleshooting

- aTerm is nil: missing term_init/term_done scope; or non‑interactive environment
- term_size=0 or term_name='unknown': pseudo‑TTY/non‑interactive; should skip
- Missed precheck: add if not TestEnv_AssumeInteractive(Self) then Exit; at test start

## 7) Next steps

- Gradually convert soft skips to real Skipped where supported
- Summarize Skipped count in runner output
- Add layered labels (fast/slow/interactive) for UI frame loop + double‑buffer diff tests
