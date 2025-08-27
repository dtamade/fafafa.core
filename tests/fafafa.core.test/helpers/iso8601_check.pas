unit helpers.iso8601_check;

{$mode objfpc}{$H+}

interface

uses SysUtils, RegExpr;

function IsISO8601Z(const S: string): boolean;

implementation

function IsISO8601Z(const S: string): boolean;
var
  R: TRegExpr;
begin
  R := TRegExpr.Create('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z$');
  try
    Result := R.Exec(S);
  finally
    R.Free;
  end;
end;

end.

