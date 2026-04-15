{$CODEPAGE UTF8}
program example_json;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

function JsonStringOf(aValue: PJsonValue): String;
begin
  if Assigned(aValue) and JsonIsStr(aValue) then
    Result := String(JsonGetStrUtf8(aValue))
  else
    Result := '';
end;

procedure PrintValue(aValue: PJsonValue; aIndent: Integer);
var
  LIndex: SizeUInt;
  LArrIter: TJsonArrayIterator;
  LObjIter: TJsonObjectIterator;
  LKey: PJsonValue;
  LNestedValue: PJsonValue;
begin
  if not Assigned(aValue) then
    Exit;

  for LIndex := 1 to aIndent do
    Write(' ');

  case UnsafeGetType(aValue) of
    YYJSON_TYPE_NULL:
      Writeln('null');
    YYJSON_TYPE_BOOL:
      if UnsafeIsTrue(aValue) then
        Writeln('true')
      else
        Writeln('false');
    YYJSON_TYPE_NUM:
      Writeln(WriteJsonNumber(aValue, []));
    YYJSON_TYPE_STR:
      Writeln('"', JsonStringOf(aValue), '"');
    YYJSON_TYPE_ARR:
      begin
        Writeln('[');
        if JsonArrIterInit(aValue, @LArrIter) then
        begin
          while JsonArrIterHasNext(@LArrIter) do
          begin
            LNestedValue := JsonArrIterNext(@LArrIter);
            PrintValue(LNestedValue, aIndent + 2);
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
            LNestedValue := JsonObjIterGetVal(LKey);
            for LIndex := 1 to aIndent + 2 do
              Write(' ');
            Write('"', JsonStringOf(LKey), '": ');
            if UnsafeIsStr(LNestedValue) then
              Writeln('"', JsonStringOf(LNestedValue), '"')
            else if UnsafeIsNum(LNestedValue) then
              Writeln(WriteJsonNumber(LNestedValue, []))
            else if UnsafeIsBool(LNestedValue) then
            begin
              if UnsafeIsTrue(LNestedValue) then
                Writeln('true')
              else
                Writeln('false');
            end
            else if UnsafeIsNull(LNestedValue) then
              Writeln('null')
            else
            begin
              Writeln;
              PrintValue(LNestedValue, aIndent + 2);
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
  FillChar(LErr, SizeOf(LErr), 0);
  LDoc := JsonReadOpts(PChar(LJsonText), Length(LJsonText), [jrfDefault], GetRtlAllocator, LErr);
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
