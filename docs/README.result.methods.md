# TResult<T,E> method-style API (macro-gated)

This module provides a Rust-style, method-oriented API on top of the existing top-level combinators for TResult<T,E>. It is macro-gated and OFF by default to keep the mainline stable.

Macro flag
- Macro name: FAFAFA_CORE_RESULT_METHODS
- Default: OFF
- Enable temporarily in either way:
  - Edit src/fafafa.core.settings.inc: change `{.$DEFINE FAFAFA_CORE_RESULT_METHODS}` to `{$DEFINE FAFAFA_CORE_RESULT_METHODS}`
  - Or pass `-dFAFAFA_CORE_RESULT_METHODS` as a compiler flag during build

Surface (all thin wrappers delegating to top-level combinators)
- Map / MapErr
- AndThen / OrElse
- MapOr / MapOrElse
- Inspect / InspectErr
- OkOpt / ErrOpt (Option adapters)

Usage examples (Integer,String)

- Map + MapErr
  R := specialize TResult<Integer,String>.Ok(7)
    .Map(function (const X: Integer): Integer begin Result := X+1; end)
    .MapErr(function (const E: String): String begin Result := E + '!'; end);
  // R.IsOk = True; R.Unwrap = 8

- AndThen + OrElse
  R := specialize TResult<Integer,String>.Err('e')
    .OrElse(function (const E: String): specialize TResult<Integer,String>
            begin Result := specialize TResult<Integer,String>.Ok(Length(E)); end)
    .AndThen(function (const X: Integer): specialize TResult<Integer,String>
             begin if X>0 then Result := specialize TResult<Integer,String>.Ok(X) else Result := specialize TResult<Integer,String>.Err('neg'); end);
  // R.IsOk = True; R.Unwrap = 1

- MapOr / MapOrElse
  U := specialize TResult<Integer,String>.Ok(7).MapOr(-1, function (const X: Integer): Integer begin Result := X+1; end);
  // U = 8
  U := specialize TResult<Integer,String>.Err('xx').MapOr(99, function (const X: Integer): Integer begin Result := X+1; end);
  // U = 99

- Inspect / InspectErr (side effects)
  GTapCount := 0;
  specialize TResult<Integer,String>.Ok(3).Inspect(@TapInt);     // adds 3
  specialize TResult<Integer,String>.Err('a').InspectErr(@TapStr); // adds Length('a')

- OkOpt / ErrOpt
  OI := specialize TResult<Integer,String>.Ok(5).OkOpt;  // Some(5)
  OS := specialize TResult<Integer,String>.Err('e').ErrOpt; // Some('e')

Tests
- Method-style tests are included but guarded by the same macro
- To run them: enable the macro and run the standard Result test project

Notes
- All method-style wrappers are implemented in implementation section and delegate to the existing, battle-tested top-level functions to minimize risk.
- Keep the macro OFF in mainline unless you specifically need to validate the method surface.

