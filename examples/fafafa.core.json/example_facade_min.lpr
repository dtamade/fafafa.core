program example_facade_min;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  // 使用门面单元（统一为 fafafa.core.json）
  fafafa.core.json;

procedure Run;
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  Root, Item: IJsonValue;
  S: String;
begin
  Reader := NewJsonReader(GetRtlAllocator);
  Doc := Reader.ReadFromString('{"name":"Alice","age":30,"tags":["dev","json"]}', []);
  Root := Doc.Root;
  if (Root <> nil) and Root.IsObject then
  begin
    S := '';
    Item := Root.GetObjectValue('name');
    if (Item <> nil) and Item.IsString then
      S := Item.GetString;
    Writeln('name=', S);

    Item := Root.GetObjectValue('tags');
    if (Item <> nil) and Item.IsArray then
      Writeln('tags.size=', Item.GetArraySize);
  end;
end;

begin
  Run;
end.

