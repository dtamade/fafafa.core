# fafafa.core.color – Usage and Notes

This document summarizes the key APIs, JSON-like serialization format, palette strategy semantics, and terminal mappings for the color module. It focuses on practical usage and best practices.

## Core suggestions / contrast
- color_pick_bw_for_bg(bg): pick black or white foreground for given bg by simple luminance heuristic (fast, 2-choice only)
- color_suggest_fg_for_bg_default(bg): recommends a foreground that meets WCAG AA contrast threshold 4.5 by default (uses enforced search over OKLCH L)
- color_suggest_fg_for_bg_enforced(bg, minContrast): same as above with explicit minimum contrast

Best practice: use color_suggest_fg_for_bg_default for UI text and icons; fallback to color_pick_bw_for_bg for extremely performance-sensitive or binary choice scenarios.

## Strict HEX parsing
- color_parse_hex(s): parses #RRGGBB or extended notations; throws on invalid input
- color_parse_hex_rgba(s): parses #RRGGBBAA or extended notations; throws on invalid input
- color_from_hex / color_try_from_hex / color_try_from_hex_rgba remain available as lenient variants

Best practice: prefer the strict variants at boundaries (input validation) and the lenient variants internally when you already trust inputs.

## JSON-like serialization for palette strategy
- IPaletteStrategy.Serialize outputs a compact JSON-like string:
  - mode: "SRGB" | "LINEAR" | "OKLAB" | "OKLCH" (string)
  - shortest, usePos, norm: true/false (lower-case booleans)
  - colors: ["#RRGGBB", ...] (extended hex supported on deserialize)
  - positions: numbers separated by semicolons ‘;’. Each number allows both '.' or ',' as decimal separator.

Example (JSON-like; not guaranteed to be strict JSON):
{
  "mode":"OKLCH",
  "shortest":true,
  "usePos":true,
  "norm":false,
  "colors":["#FF0000","#00FF00","#0000FF"],
  "positions":[0.1; 0.2; 0.7]
}

Notes
- positions are separated by ';' to avoid locale replacing '.' with ',' from breaking array structure.
- The lightweight deserializer accepts ';' or ',' as item separators and '.' or ',' as decimal points.
- For integration with standard JSON tooling, use the jsonadapter unit which produces/consumes proper JSON.

## Palette strategy API and best practices
- Constructors
  - TPaletteStrategy.CreateEven(mode, colors, shortestPath)
  - TPaletteStrategy.CreateWithPositions(mode, colors, positions, shortestPath, normalize)
  - TPaletteStrategy.CreateWithPositionsFixed(mode, colors, positions, shortestPath, makeNonDecreasing=true, normalizeTo01=false)
- Runtime mutators
  - SetMode(...), SetShortestHuePath(...), SetNormalizePositions(...), SetColors(...), SetPositions(...)
- Validation and fix-up
  - Validate(out msg): checks length matches and positions are non-decreasing
  - FixupPositions(makeNonDecreasing, normalizeTo01): explicit fix-up helper; returns whether changes were made

Best practice
- Avoid implicit mutation during serialize/deserialize. After constructing or deserializing, call Validate to check correctness; if needed, explicitly call FixupPositions(true, ...) or use CreateWithPositionsFixed(...).
- Prefer normalizePositions=True when positions represent arbitrary scales but must be interpreted on [0,1].

## OKLCH gamut strategy (parameterized)
- color_from_oklch_gamut(lch, strategy, maxBisectionIters=24, epsilon=1e-6)
  - GMT_Clip: identical to color_from_oklch
  - GMT_PreserveHueDesaturate: keeps L/h, reduces C via bisection until sRGB in-gamut
  - maxBisectionIters and epsilon control convergence; defaults match previous behavior

Best practice: use defaults unless you have hard constraints on precision/speed; increase iters only when you observe edge cases near gamut boundaries.

## Terminal palette mapping
- color_xterm256_to_rgb(index)
  - For index < 16, uses ANSI16 mapping
  - For 16..255, uses 6x6x6 cube + gray band decoding
- color_rgb_to_xterm256(r,g,b) and color_rgb_to_ansi16(r,g,b)

Note: accuracy is limited by the terminal’s fixed palette; for UI usage prefer real sRGB colors instead of terminal indices.

## Interpolation modes
- palette_sample / palette_sample_multi / palette_sample_multi_with_positions support modes:
  - PIM_SRGB: channel-wise sRGB
  - PIM_LINEAR: convert sRGB->linear, interpolate, then linear->sRGB
  - PIM_OKLAB: OKLab space
  - PIM_OKLCH: OKLCH space; hue wraps; shortestPath controls wrap direction

Best practice: 
- For perceptual smoothness, use OKLab/OKLCH. 
- For physically-inspired compositing, use Linear (e.g. color_blend_over_linear).

## Locale and decimal points
- Serialize prints numbers using '.'
- The deserializer accepts '.' or ',' as decimal points and supports ';' or ',' as separators

## Performance notes
- Fast paths and micro-optimizations:
  - sRGB<->Linear uses precomputed LUT and constant-coefficient fast paths.
  - OKLab cube roots use a fast cbrt approximation on x86_64 (with one Newton step); otherwise fallback to Power(x,1/3).
  - Palette sampling with positions avoids copies when possible and uses binary search for segments.

All changes are covered by the color test suite (79 tests) which must remain green (0 failures).

