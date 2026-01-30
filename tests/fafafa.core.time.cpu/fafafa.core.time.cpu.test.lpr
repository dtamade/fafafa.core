program fafafa.core.time.cpu.test;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  Test_fafafa_core_time_cpu_basic;

var
  Application: TTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.time.cpu Test Suite';
    Application.Run;
  finally
    Application.Free;
  end;
end.


