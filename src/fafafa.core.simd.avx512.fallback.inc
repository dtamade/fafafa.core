// Intentional empty include:
// MemDiffRange/BytesIndexOf now reuse the cloned AVX2 slots from
// RegisterAVX512Backend directly.
// Keep this file as an audited include boundary so docs/tests can point at the
// retired AVX512 fallback layer without reintroducing pass-through wrappers.
