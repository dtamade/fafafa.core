unit __tmp_fmt_helper;

{$mode ObjFPC}{$H+}

interface

function FmtFixed(aValue: Double; aDigits: Integer): string;

implementation

uses SysUtils;

function FmtFixed(aValue: Double; aDigits: Integer): string;
var
  LFmt: string;
begin
  if aDigits <= 0 then Exit(FormatFloat('0', aValue));
  LFmt := '0.' + StringOfChar('0', aDigits);
  Result := FormatFloat(LFmt, aValue);
end;

end.

