unit Test_fafafa_core_socket_stats_json;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.socket;

Type
  TTestCase_Socket_StatsJson = class(TTestCase)
  published
    procedure Test_GetStatisticsJson_Basics;
  end;

implementation

procedure TTestCase_Socket_StatsJson.Test_GetStatisticsJson_Basics;
var S: ISocket; J: String;
begin
  S := TSocket.TCP; // IPv4 TCP
  // 接口已暴露 JSON 方法
  J := S.GetStatisticsJson;
  AssertTrue('json should contain handle', Pos('"handle":', J) > 0);
  AssertTrue('json should contain state', Pos('"state":"', J) > 0);
  AssertTrue('json should contain stats', Pos('"stats":{', J) > 0);
  AssertTrue('json should contain bytesSent', Pos('"bytesSent":', J) > 0);
  AssertTrue('json should contain bytesReceived', Pos('"bytesReceived":', J) > 0);
end;

initialization
  RegisterTest(TTestCase_Socket_StatsJson);

end.

