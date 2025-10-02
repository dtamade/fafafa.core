program test_tryadd;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

type
  TInt64Helper = record
  public
    class function TryAdd(a, b: Int64; out r: Int64): Boolean; static;
  end;

class function TInt64Helper.TryAdd(a, b: Int64; out r: Int64): Boolean;
var tmp: Int64;
begin
  tmp := a + b;
  WriteLn('a = ', a);
  WriteLn('b = ', b);
  WriteLn('tmp = ', tmp);
  WriteLn('(a xor b) and High(Int64) = ', (a xor b) and High(Int64));
  WriteLn('(a xor tmp) and High(Int64) = ', (a xor tmp) and High(Int64));
  
  if (((a xor b) and High(Int64)) = 0) and (((a xor tmp) and High(Int64)) <> 0) then 
  begin
    WriteLn('Overflow detected!');
    Exit(False);
  end;
  r := tmp; 
  Result := True;
end;

var
  a, b, r: Int64;
  ok: Boolean;
begin
  WriteLn('=== Test 1: Should overflow ===');
  a := High(Int64) - 5;
  b := 10;
  ok := TInt64Helper.TryAdd(a, b, r);
  WriteLn('Result: ', ok, ', r = ', r);
  WriteLn;
  
  WriteLn('=== Test 2: Should not overflow ===');
  a := 100;
  b := 200;
  ok := TInt64Helper.TryAdd(a, b, r);
  WriteLn('Result: ', ok, ', r = ', r);
end.
