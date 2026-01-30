Debugging color and scrolling on Windows 10/11 terminals

- Use Windows Terminal or VSCode integrated terminal (Legacy cmd may block VT)
- Alternate screen should be enabled automatically by ui_app; backend declares tc_alternate_screen and emits CSI ? 1049 h/l
- Output mode disables WRAP_AT_EOL_OUTPUT to avoid implicit line wrap that grows scrollback
- 24bit colors are emitted as SGR: ESC [ 38;2;R;G;B m and ESC [ 48;2;R;G;B m
- If colors still don't show, verify supports_vt=true and that the terminal is not in Legacy Console mode

