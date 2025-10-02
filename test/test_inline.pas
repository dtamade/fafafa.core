program test_inline;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

// Test inline function
function TestInline1: Boolean; inline;
begin
  Result := True;
end;

// Test normal function
function TestNormal: Boolean;
begin
  Result := True;
end;

begin
  WriteLn('Testing inline functions...');
  WriteLn('TestInline1: ', TestInline1);
  WriteLn('TestNormal: ', TestNormal);
end.
