{$CODEPAGE UTF8}
program example_chain;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.result;

function ParseInt(const S: string): specialize TResult<Integer,String>;
begin
  try
    Result := specialize TResult<Integer,String>.Ok(StrToInt(S));
  except
    on E: Exception do Result := specialize TResult<Integer,String>.Err(E.Message);
  end;
end;

function NonZero(const X: Integer): specialize TResult<Integer,String>;
begin
  if X<>0 then Result := specialize TResult<Integer,String>.Ok(X)
  else Result := specialize TResult<Integer,String>.Err('zero');
end;

var
  R: specialize TResult<Integer,String>;
  OutS: string;
begin
  R := ParseInt('10');
  // AndThen 链式
  R := specialize ResultAndThen<Integer,String,Integer>(R, @NonZero);

  // Match 输出
  OutS := specialize ResultMatch<Integer,String,string>(R,
    function (const X: Integer): string begin Result := 'Ok(' + IntToStr(X) + ')'; end,
    function (const E: String): string begin Result := 'Err(' + E + ')'; end);
  WriteLn(OutS);
end.

