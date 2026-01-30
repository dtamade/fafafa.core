{$CODEPAGE UTF8}
program example_result_filters_and_try;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.result,
  fafafa.core.option;

var
  R, R2: specialize TResult<Integer,String>;
  RO: specialize TResult< specialize TOption<Integer>, String>;
  ORs: specialize TOption< specialize TResult<Integer,String> >;
  V: Integer;
begin
  // FilterOrElse: Ok(3) 且谓词不满足 -> Err('odd')
  R := specialize TResult<Integer,String>.Ok(3);
  R2 := specialize ResultFilterOrElse<Integer,String>(R,
    function (const X: Integer): Boolean begin Result := (X mod 2)=0; end,
    function (const X: Integer): String begin Result := 'odd'; end);
  if R2.IsErr then WriteLn('FilterOrElse -> Err(', R2.UnwrapErr, ')') else WriteLn('FilterOrElse -> Ok(', R2.Unwrap, ')');

  // ResultToTry: Err -> raise 映射异常
  R := specialize TResult<Integer,String>.Err('bad');
  try
    V := specialize ResultToTry<Integer,String>(R,
      function (const E: String): Exception begin Result := Exception.Create('mapped:'+E); end);
    WriteLn('ToTry(Err) -> ', V);
  except on Ex: Exception do WriteLn('ToTry(Err) raised: ', Ex.Message); end;

  // ResultToTry: Ok -> 返回值
  R := specialize TResult<Integer,String>.Ok(9);
  V := specialize ResultToTry<Integer,String>(R,
    function (const E: String): Exception begin Result := Exception.Create(E); end);
  WriteLn('ToTry(Ok) -> ', V);

  // Transpose: Result<Option<T>,E> -> Option<Result<T,E>>
  RO := specialize TResult< specialize TOption<Integer>, String>.Ok(specialize TOption<Integer>.Some(5));
  ORs := specialize ResultTransposeOption<Integer,String>(RO);
  if ORs.IsSome then
  begin
    if ORs.Unwrap.IsOk then WriteLn('Transpose -> Some(Ok(', ORs.Unwrap.Unwrap, '))')
    else WriteLn('Transpose -> Some(Err(', ORs.Unwrap.UnwrapErr, '))');
  end
  else
    WriteLn('Transpose -> None');
end.

