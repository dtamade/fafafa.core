{$CODEPAGE UTF8}
program example_result_basics;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.result;

var
  R: specialize TResult<Integer,String>;
  U: Integer;
begin
  R := specialize TResult<Integer,String>.Ok(5);
  if R.IsOk then
    WriteLn('Ok: ', R.Unwrap)
  else
    WriteLn('Err: ', R.UnwrapErr);

  U := specialize ResultMapOr<Integer,String,Integer>(R, -1,
    function (const X: Integer): Integer begin Result := X * 2; end);
  WriteLn('MapOr -> ', U);

  R := specialize TResult<Integer,String>.Err('boom');
  U := specialize ResultMapOrElse<Integer,String,Integer>(R,
    function (const E: String): Integer begin Result := -2; end,
    function (const X: Integer): Integer begin Result := X + 3; end);
  WriteLn('MapOrElse(Err) -> ', U);
end.

