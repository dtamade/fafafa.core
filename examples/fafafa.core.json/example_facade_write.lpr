program example_facade_write;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json;

procedure Run;
var
  Doc: TJsonDocument;
  InJson: String;
  FacadeDoc: IJsonDocument;
  W: IJsonWriter;
  S: String;
begin
  InJson := '{"a":1,"b":[1,2,3]}';
  Doc := JsonRead(PChar(InJson), Length(InJson), []);
  FacadeDoc := JsonWrapDocument(Doc);
  W := NewJsonWriter;
  S := W.WriteToString(FacadeDoc, [jwfPretty]);
  Writeln(S);
end;

begin
  Run;
end.

