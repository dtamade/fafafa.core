program example_result_filters_and_try;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ../../src/fafafa.core.settings.inc}
uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.result,
  fafafa.core.option.base;

var
  LResult: specialize TResult<Integer, String>;
  LFiltered: specialize TResult<Integer, String>;
  LResultOption: specialize TResult<specialize TOption<Integer>, String>;
  LOptionResult: specialize TOption<specialize TResult<Integer, String>>;
  LValue: Integer;
begin
  // FilterOrElse: Ok(3) 且谓词不满足 -> Err('odd')
  LResult := specialize TResult<Integer, String>.Ok(3);
  LFiltered := specialize ResultFilterOrElse<Integer, String>(LResult,
    function (const X: Integer): Boolean begin Result := (X mod 2)=0; end,
    function (const X: Integer): String begin Result := 'odd'; end);
  if LFiltered.IsErr then
    WriteLn('FilterOrElse -> Err(', LFiltered.UnwrapErr, ')')
  else
    WriteLn('FilterOrElse -> Ok(', LFiltered.Unwrap, ')');

  // ResultToTry: Err -> raise 映射异常
  LResult := specialize TResult<Integer, String>.Err('bad');
  try
    LValue := specialize ResultToTry<Integer, String>(LResult,
      function (const E: String): Exception begin Result := Exception.Create('mapped:'+E); end);
    WriteLn('ToTry(Err) -> ', LValue);
  except
    on Ex: Exception do
      WriteLn('ToTry(Err) raised: ', Ex.Message);
  end;

  // ResultToTry: Ok -> 返回值
  LResult := specialize TResult<Integer, String>.Ok(9);
  LValue := specialize ResultToTry<Integer, String>(LResult,
    function (const E: String): Exception begin Result := Exception.Create(E); end);
  WriteLn('ToTry(Ok) -> ', LValue);

  // Transpose: Result<Option<T>,E> -> Option<Result<T,E>>
  LResultOption := specialize TResult<specialize TOption<Integer>, String>.Ok(
    specialize TOption<Integer>.Some(5));
  LOptionResult := specialize ResultTranspose<Integer, String>(LResultOption);
  if LOptionResult.IsSome then
  begin
    if LOptionResult.Unwrap.IsOk then
      WriteLn('Transpose -> Some(Ok(', LOptionResult.Unwrap.Unwrap, '))')
    else
      WriteLn('Transpose -> Some(Err(', LOptionResult.Unwrap.UnwrapErr, '))');
  end
  else
    WriteLn('Transpose -> None');
end.

