# Archiver gzip/tar fixes (2025-08)

- gzip now uses raw deflate body (zlib deflateInit2/inflateInit2 with windowBits = -15).
  - Reason: gzip body must be raw deflate, not zlib stream. Using raw mode removes data error and trailer confusion.
  - Added TRawDeflateStream/TRawInflateStream in `src/fafafa.core.archiver.codec.deflate.raw.paszlib.pas`.
- CRC32 handling aligned with gzip spec:
  - Seed = 0xFFFFFFFF; write trailer with bitwise NOT; read trailer compare with NOT(FCRC).
- Decode side trailer handling:
  - For seekable sources, a bounded stream is passed to inflate so trailer is never consumed; trailer (8 bytes) is read afterwards.
  - For non-seekable sources, raw inflate wraps source directly; VerifyTrailer is performed only when truly at EOF.
- Tar reader path-safety:
  - Perform zero-allocation checks against header name before creating entry object.
  - After applying PAX path override, also run a string-level safety check.
- Test runner script
  - `tests/fafafa.core.archiver/buildOrTest.bat` now syncs latest exe from `lib/x86_64-win64` to `bin/tests_archiver.exe` to avoid stale binary.

All test suites pass (11/11) with heaptrc reporting 0 unfreed blocks.

