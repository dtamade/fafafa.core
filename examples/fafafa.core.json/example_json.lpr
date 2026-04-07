{$CODEPAGE UTF8}
program example_json;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

procedure PrintValue(aValue: PJsonValue; aIndent: Integer);
var
  LIndex: SizeUInt;
  LArrIter: TJsonArrayIterator;
  LObjIter: TJsonObjectIterator;
  LKey: PJsonValue;
  LVal: PJsonValue;
begin
  if not Assigned(aValue) then
    Exit;

  for LIndex := 1 to aIndent do
    Write(' ');

  case UnsafeGetType(aValue) of
    YYJSON_TYPE_NULL: Writeln('null');
    YYJSON_TYPE_BOOL:
      if UnsafeIsTrue(aValue) then
        Writeln('true')
      else
        Writeln('false');
    YYJSON_TYPE_NUM: Writeln(WriteJsonNumber(aValue, []));
    YYJSON_TYPE_STR: Writeln('"', String(JsonGetStrUtf8(aValue)), '"');
    YYJSON_TYPE_ARR:
      begin
        Writeln('[');
        if JsonArrIterInit(aValue, @LArrIter) then
        begin
          while JsonArrIterHasNext(@LArrIter) do
          begin
            LVal := JsonArrIterNext(@LArrIter);
            PrintValue(LVal, aIndent + 2);
          end;
        end;
        for LIndex := 1 to aIndent do
          Write(' ');
        Writeln(']');
      end;
    YYJSON_TYPE_OBJ:
      begin
        Writeln('{');
        if JsonObjIterInit(aValue, @LObjIter) then
        begin
          while JsonObjIterHasNext(@LObjIter) do
          begin
            LKey := JsonObjIterNext(@LObjIter);
            LVal := JsonObjIterGetVal(LKey);
            for LIndex := 1 to aIndent + 2 do
              Write(' ');
            Write('"', String(JsonGetStrUtf8(LKey)), '": ');
            if UnsafeIsStr(LVal) then
              Writeln('"', String(JsonGetStrUtf8(LVal)), '"')
            else if UnsafeIsNum(LVal) then
              Writeln(WriteJsonNumber(LVal, []))
            else if UnsafeIsBool(LVal) then
              if UnsafeIsTrue(LVal) then
                Writeln('true')
              else
                Writeln('false')
            else if UnsafeIsNull(LVal) then
              Writeln('null')
            else
            begin
              Writeln;
              PrintValue(LVal, aIndent + 2);
            end;
          end;
        end;
        for LIndex := 1 to aIndent do
          Write(' ');
        Writeln('}');
      end;
  end;
end;

var
  LDoc: TJsonDocument;
  LErr: TJsonError;
  LJsonText: AnsiString;
begin
  LJsonText := '{"msg":"hello","arr":[1,2,3],"ok":true}';
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts(PChar(LJsonText), Length(LJsonText), [jrfDefault], GetRtlAllocator(), LErr);
  if not Assigned(LDoc) then
  begin
    Writeln('Read error: ', LErr.Message);
    Halt(1);
  end;
  try
    PrintValue(JsonDocGetRoot(LDoc), 0);
  finally
    JsonDocFree(LDoc);
  end;
end.

