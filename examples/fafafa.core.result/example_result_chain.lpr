{$CODEPAGE UTF8}
program example_result_chain;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.result
  {$IFDEF FAFAFA_CORE_RESULT_METHODS}
  , fafafa.core.option
  {$ENDIF}
  ;

var
  R: specialize TResult<Integer,String>;
  U: Integer;
begin
  // Start from Ok(2)
  R := specialize TResult<Integer,String>.Ok(2);

  // AndThen chaining to do (+3) then (*2) using combinators
  R := specialize ResultAndThen<Integer,String,Integer>(R,
    function (const X: Integer): specialize TResult<Integer,String>
    begin
      if X >= 0 then Result := specialize TResult<Integer,String>.Ok(X + 3)
      else Result := specialize TResult<Integer,String>.Err('neg');
    end);
  R := specialize ResultAndThen<Integer,String,Integer>(R,
    function (const X: Integer): specialize TResult<Integer,String>
    begin
      Result := specialize TResult<Integer,String>.Ok(X * 2);
    end);

  // Fold / Match to project into an integer
  U := specialize ResultFold<Integer,String,Integer>(R,
    function (const X: Integer): Integer begin Result := X; end,
    function (const E: String): Integer begin Result := -1; end);
  WriteLn('Fold = ', U); // Expect 10

  // Err path with OrElse -> map error to Ok(5)
  R := specialize TResult<Integer,String>.Err('bad');
  R := specialize ResultOrElse<Integer,String,String>(R,
    function (const E: String): specialize TResult<Integer,String>
    begin
      Result := specialize TResult<Integer,String>.Ok(5);
    end);

  // MapOrElse to lengths
  U := specialize ResultMapOrElse<Integer,String,Integer>(R,
    function (const E: String): Integer begin Result := Length(E); end,
    function (const X: Integer): Integer begin Result := X; end);
  WriteLn('MapOrElse = ', U); // Expect 5

  // Optional: method-style API preview (only when FAFAFA_CORE_RESULT_METHODS enabled)
  {$IFDEF FAFAFA_CORE_RESULT_METHODS}
  var OI: specialize TOption<Integer>;
  OI := specialize TResult<Integer,String>.Ok(7)
        .Inspect(function (const X: Integer) begin WriteLn('Inspect Ok = ', X); end)
        .OkOpt;
  if OI.IsSome then WriteLn('OkOpt = ', OI.Unwrap);

  {$IFDEF FAFAFA_CORE_RESULT_METHODS}
  // Method-style And/Or/FilterOrElse/ToTry demo
  var Rb: specialize TResult<Integer,String>;
  Rb := specialize TResult<Integer,String>.Ok(1)
          .And(specialize TResult<Integer,String>.Err('x'))  // -> Err('x')
          .Or(specialize TResult<Integer,String>.Ok(9))      // -> Err stays; Or not applied
          .Or(specialize TResult<Integer,String>.Ok(9));     // if previous was Err -> Ok(9)
  WriteLn('Method Or -> ', Rb.UnwrapOr(-1));

  try
    V := specialize TResult<Integer,String>.Err('bad').ToTry(
      function (const E: String): Exception begin Result := Exception.Create('mapped:'+E); end);
  except on Ex: Exception do WriteLn('ToTry raised: ', Ex.Message); end;
  {$ENDIF}

  {$ENDIF}
end.

