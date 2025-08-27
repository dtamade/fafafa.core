program example_json_read_traverse;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

function StrOfJsonString(AVal: PJsonValue): String;
begin
  if Assigned(AVal) and JsonIsStr(AVal) then
    Result := String(JsonGetStrUtf8(AVal))
  else
    Result := '';
end;

procedure Demo_ReadAndTraverse;
var
  JsonText: String;
  Doc: TJsonDocument;
  Root, Key, Val, Item: PJsonValue;
  ObjIter: TJsonObjectIterator;
  ArrIter: TJsonArrayIterator;
  S: String;
begin
  Writeln('== Demo: Read + Traverse ==');
  // JSON 示例：包含对象、数组和多种类型
  JsonText := '{' +
              '  "name": "Alice",' +
              '  "age": 30,' +
              '  "admin": true,' +
              '  "tags": ["dev", "json"],' +
              '  "profile": {"city": "Shenzhen", "score": 99.5}' +
              '}';

  Doc := JsonRead(PChar(JsonText), Length(JsonText), [jrfAllowComments, jrfAllowTrailingCommas]);
  try
    Root := JsonDocGetRoot(Doc);
    if Root = nil then
    begin
      Writeln('Parse failed: root is nil');
      Exit;
    end;

    Writeln('BytesRead=', JsonDocGetReadSize(Doc), ', ValuesRead=', JsonDocGetValCount(Doc));

    // 根对象遍历
    if JsonIsObj(Root) then
    begin
      if JsonObjIterInit(Root, @ObjIter) then
      begin
        while JsonObjIterHasNext(@ObjIter) do
        begin
          Key := JsonObjIterNext(@ObjIter);
          Val := JsonObjIterGetVal(Key);
          S := StrOfJsonString(Key);
          Writeln('Key: ', S, ' => Type: ', JsonGetTypeDesc(Val));
        end;
      end;

      // 访问嵌套字段
      Val := JsonObjGet(Root, 'tags');
      if Assigned(Val) and JsonIsArr(Val) then
      begin
        Writeln('tags: array size = ', JsonArrSize(Val));
        if JsonArrIterInit(Val, @ArrIter) then
        begin
          while JsonArrIterHasNext(@ArrIter) do
          begin
            Item := JsonArrIterNext(@ArrIter);
            if JsonIsStr(Item) then
            begin
              S := StrOfJsonString(Item);
              Writeln('  - ', S);
            end;
          end;
        end;
      end;
    end
    else
      Writeln('Root is not an object');
  finally
    JsonDocFree(Doc);
  end;
end;

procedure Demo_ErrorHandling;
var
  BadJson: String;
  Err: TJsonError;
  Doc: TJsonDocument;
begin
  Writeln('');
  Writeln('== Demo: Error Handling ==');
  // 缺少逗号，制造语法错误
  BadJson := '{"a": 1  "b": 2}';
  FillChar(Err, SizeOf(Err), 0);
  Doc := JsonReadOpts(PChar(BadJson), Length(BadJson), [jrfDefault], GetRtlAllocator, Err);
  if JsonDocGetRoot(Doc) = nil then
  begin
    Writeln('Error Code   : ', Ord(Err.Code));
    Writeln('Error Pos    : ', Err.Position);
    Writeln('Error Message: ', Err.Message);
  end
  else
  begin
    Writeln('Unexpected: should fail but succeeded');
    JsonDocFree(Doc);
  end;
end;

begin
  Demo_ReadAndTraverse;
  Demo_ErrorHandling;
end.

