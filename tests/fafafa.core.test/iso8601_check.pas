unit iso8601_check;

{$mode objfpc}{$H+}

interface

uses SysUtils, RegExpr;

function IsRFC3339Timestamp(const S: string): boolean;

implementation

function IsRFC3339Timestamp(const S: string): boolean;
var
  R: TRegExpr;
begin
  // 允许两种形式：
  // 1) UTC: yyyy-mm-ddThh:mm:ss(.sss)?Z
  // 2) 本地偏移: yyyy-mm-ddThh:mm:ss(.sss)?(+|-)HH:MM
  R := TRegExpr.Create('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{3})?(Z|[+-][0-9]{2}:[0-9]{2})$');
  try
    Result := R.Exec(S);
  finally
    R.Free;
  end;
end;

end.

