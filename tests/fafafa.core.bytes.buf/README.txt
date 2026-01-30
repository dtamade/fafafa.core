Notes:
- Compact and EnsureWritable are root-only operations. Views (Slice/Duplicate) will raise EOutOfRange.
- FromBuilder copies the builder bytes to a new independent buffer to avoid aliasing.

