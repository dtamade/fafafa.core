{$CODEPAGE UTF8}
program test_guard;

{$mode objfpc}{$H+}

uses
  simple_guard_test;

begin
  try
    TestGuardMechanism;
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
end.
