Title: Windows Global\ Named Objects and Privileges

Overview
- Windows distinguishes named kernel objects in per-session (Local\) and global (Global\) namespaces.
- Creating or opening Global\ named objects requires the SeCreateGlobalPrivilege privilege. Typical desktop processes do not have this privilege by default.

Implications
- Tests or examples that create Global\-prefixed objects (e.g., Global\my_mutex) may fail with "Access is denied" when run in a normal user session.
- Services or processes running with appropriate privileges can create Global\ objects successfully.

Recommendations
- Prefer non-prefixed names when cross-session visibility is not required; the implementation will use per-session (Local) semantics.
- If Global\ is required:
  - Run as a service or under an account granted SeCreateGlobalPrivilege.
  - Or adjust Local Security Policy: Local Policies → User Rights Assignment → "Create global objects".
  - For automated tests, consider skipping Global\-specific cases when privilege is missing.

Library Behavior
- Some named sync primitives may attempt a Local\ fallback if Global\ creation fails with Access Denied. This preserves functionality in unprivileged environments while keeping external names unchanged.

