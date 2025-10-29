program tests_bitset;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, consoletestrunner,
  test_bitset;

type
  TMyTestRunner = class(TTestRunner)
  protected
    // override for specific setup
  end;

var
  LApp: TMyTestRunner;
begin
  LApp := TMyTestRunner.Create(nil);
  try
    LApp.Initialize;
    LApp.Title := 'FPCUnit tests for BitSet';
    LApp.Run;
  finally
    LApp.Free;
  end;
end.

