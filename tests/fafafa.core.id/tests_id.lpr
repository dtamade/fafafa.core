{$CODEPAGE UTF8}
program tests_id;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  Test_fafafa_core_id_global,
  Test_fafafa_core_id_ulid_monotonic,
  Test_fafafa_core_id_snowflake,
  Test_fafafa_core_id_uuid_v7_monotonic,
  Test_fafafa_core_id_uuid_record,
  Test_fafafa_core_id_uuid_v7_monotonic_batch,
  Test_fafafa_core_id_uuid_negative,
  Test_fafafa_core_id_p0_features,
  Test_fafafa_core_id_p1_features,
  Test_fafafa_core_id_p2_features,
  Test_fafafa_core_id_p3_features;

type
  TIdTestApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TIdTestApplication.DoRun;
var
  LRunner: TTestRunner;
begin
  LRunner := TTestRunner.Create(nil);
  try
    LRunner.Initialize;
    LRunner.Run;
  finally
    LRunner.Free;
  end;
  Terminate;
end;

var
  App: TIdTestApplication;
begin
  App := TIdTestApplication.Create(nil);
  try
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.

