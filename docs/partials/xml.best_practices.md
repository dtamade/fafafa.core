# XML Best Practices (fafafa.core)

- Use `XmlEscape` for simple, internal logs where input is known to be "clean": it replaces only `& < > " '`, preserving all other bytes as-is.
- Use `XmlEscapeXML10Strict` for any XML that will be parsed by external tools (JUnit, CI dashboards, etc.). It strips XML 1.0 illegal code points (keeps TAB/LF/CR) and then escapes entities.

Examples

- Internal console/log:
  - `XmlEscape('hello <world> & "quote"')` → `hello &lt;world&gt; &amp; &quot;quote&quot;`
- External artifacts (XML 1.0 compliant):
  - `XmlEscapeXML10Strict('A'+#9+'B'+#10+'C'+#13+'D &<>')` → `A\tB\nC\rD &amp;&lt;&gt;`
  - Invalid control characters (e.g., #0..#8, #11, #12, #14..#31) are removed before escaping

Guidelines

- Prefer strict mode when serializing user/content strings to XML
- Document clearly which escape helper is used in each reporter and why
- Keep escaping at the last step of serialization to avoid double-escaping

See also
- `docs/README_fafafa_core_xml.md`
- `docs/fafafa.core.xml.md`

