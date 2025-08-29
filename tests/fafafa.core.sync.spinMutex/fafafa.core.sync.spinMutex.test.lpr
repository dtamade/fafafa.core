program fafafa.core.sync.spinMutex.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.spinMutex.testcase;

type
  TSpinMutexTestApplication = class(TTestRunner)
  protected
    procedure DoRun; override;
  end;

procedure TSpinMutexTestApplication.DoRun;
begin
  WriteLn('========================================');
  WriteLn('fafafa.core.sync.spinMutex 单元测试');
  WriteLn('========================================');
  WriteLn;
  
  inherited DoRun;
end;

var
  Application: TSpinMutexTestApplication;

begin
  Application := TSpinMutexTestApplication.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'SpinMutex Unit Tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
