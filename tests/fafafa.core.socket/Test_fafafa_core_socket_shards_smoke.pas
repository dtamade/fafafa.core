unit Test_fafafa_core_socket_shards_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.socket, fafafa.core.socket.shards;

Type
  TTestCase_Socket_Shards_Smoke = class(TTestCase)
  published
    procedure Smoke_Init_Start_Stop;
  end;

implementation

procedure TTestCase_Socket_Shards_Smoke.Smoke_Init_Start_Stop;
var S: IShardSystem;
begin
  S := TShardSystem.Create;
  S.Init(2);
  S.Start;
  Sleep(50);
  S.Stop;
  AssertTrue('metrics json non-empty', Length(S.MetricsJson) > 0);
end;

initialization
  RegisterTest(TTestCase_Socket_Shards_Smoke);

end.

