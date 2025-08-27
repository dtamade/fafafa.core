{$CODEPAGE UTF8}
program example_json;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.json.core;

procedure PrintValue(V: PJsonValue; Indent: Integer);
var
  I: SizeUInt;
  ArrIt: TJsonArrayIterator;
  ObjIt: TJsonObjectIterator;
  K, Val: PJsonValue;
begin
  if not Assigned(V) then Exit;
  for I := 1 to Indent do Write(' ');
  case UnsafeGetType(V) of
    YYJSON_TYPE_NULL: Writeln('null');
    YYJSON_TYPE_BOOL: if UnsafeIsTrue(V) then Writeln('true') else Writeln('false');
    YYJSON_TYPE_NUM: Writeln(WriteJsonNumber(V, []));
    YYJSON_TYPE_STR: Writeln('"', StrPas(JsonGetStr(V)), '"');
    YYJSON_TYPE_ARR:
      begin
        Writeln('[');
        ArrIt := JsonArrIterInit(V);
        while True do
        begin
          Val := JsonArrIterNext(ArrIt);
          if Val = nil then Break;
          PrintValue(Val, Indent + 2);
        end;
        for I := 1 to Indent do Write(' ');
        Writeln(']');
      end;
    YYJSON_TYPE_OBJ:
      begin
        Writeln('{');
        ObjIt := JsonObjIterInit(V);
        while JsonObjIterNext(ObjIt, K, Val) do
        begin
          for I := 1 to Indent + 2 do Write(' ');
          Write('"', StrPas(JsonGetStr(K)), '": ');
          if (UnsafeIsStr(Val)) then
            Writeln('"', StrPas(JsonGetStr(Val)), '"')
          else if (UnsafeIsNum(Val)) then
            Writeln(WriteJsonNumber(Val, []))
          else if (UnsafeIsBool(Val)) then
            if UnsafeIsTrue(Val) then Writeln('true') else Writeln('false')
          else if (UnsafeIsNull(Val)) then
            Writeln('null')
          else
          begin
            Writeln;
            PrintValue(Val, Indent + 2);
          end;
        end;
        for I := 1 to Indent do Write(' ');
        Writeln('}');
      end;
  end;
end;

var
  Doc: TJsonDocument;
  Err: TJsonError;
  JsonText: AnsiString;
begin
  JsonText := '{"msg":"hello","arr":[1,2,3],"ok":true}';
  Doc := JsonReadOpts(PChar(JsonText), Length(JsonText), [jrfDefault], GetRtlAllocator(), Err);
  if not Assigned(Doc) then
  begin
    Writeln('Read error: ', Err.Message);
    Halt(1);
  end;
  try
    PrintValue(Doc.Root, 0);
  finally
    Doc.Free;
  end;
end.

