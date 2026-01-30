unit Test_fafafa_core_socket_stats_json_ext;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.socket;

Type
  TTestCase_Socket_StatsJson_Ext = class(TTestCase)
  published
    procedure Test_GetExtendedStatisticsJson_Basics;
  end;

implementation

procedure TTestCase_Socket_StatsJson_Ext.Test_GetExtendedStatisticsJson_Basics;
var S: ISocket; J: String;
begin
  S := TSocket.TCP; // IPv4 TCP
  J := (S as TSocket).GetExtendedStatisticsJson; // 实现类提供扩展JSON
  AssertTrue('json should contain options', Pos('"options":{', J) > 0);
  AssertTrue('json should contain keepAlive', Pos('"keepAlive":', J) > 0);
  AssertTrue('json should contain tcpNoDelay', Pos('"tcpNoDelay":', J) > 0);
  AssertTrue('json should contain sendBufferSize', Pos('"sendBufferSize":', J) > 0);
  AssertTrue('json should contain receiveBufferSize', Pos('"receiveBufferSize":', J) > 0);
end;

initialization
  RegisterTest(TTestCase_Socket_StatsJson_Ext);

end.

