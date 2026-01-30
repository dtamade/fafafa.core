unit fafafa.core.json.mut.util;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

// Clone immutable value to mutable value using given mutable document
function CloneImmToMut(ADoc: TJsonMutDocument; AVal: PJsonValue): PJsonMutValue;

// Serialize a mutable value to JSON string (minimal, aligned with writer flags)
function WriteJsonMutValue(AVal: PJsonMutValue; AFlags: TJsonWriteFlags; AIndent: Integer = 0): String;

implementation

function CloneImmToMut(ADoc: TJsonMutDocument; AVal: PJsonValue): PJsonMutValue;
var t: UInt8; it: TJsonArrayIterator; o: TJsonObjectIterator; k, v: PJsonValue; arr, obj, child: PJsonMutValue; s: String;
begin
  if not Assigned(AVal) then Exit(nil);
  t := UnsafeGetType(AVal);
  case t of
    YYJSON_TYPE_NULL:   Exit(JsonMutNull(ADoc));
    YYJSON_TYPE_BOOL:   Exit(JsonMutBool(ADoc, UnsafeIsTrue(AVal)));
    YYJSON_TYPE_NUM:    begin
      if JsonIsReal(AVal) then Exit(JsonMutReal(ADoc, JsonGetReal(AVal)));
      if JsonIsSint(AVal) then Exit(JsonMutSint(ADoc, JsonGetSint(AVal)));
      Exit(JsonMutUint(ADoc, JsonGetUint(AVal)));
    end;
    YYJSON_TYPE_STR:    begin s := Copy(AVal^.Data.Str, 1, UnsafeGetLen(AVal)); Exit(JsonMutStr(ADoc, s)); end;
    YYJSON_TYPE_ARR:    begin
      arr := JsonMutArr(ADoc);
      if JsonArrIterInit(AVal, @it) then
        while JsonArrIterHasNext(@it) do
        begin
          v := JsonArrIterNext(@it);
          child := CloneImmToMut(ADoc, v);
          if not JsonMutArrAppend(arr, child) then Exit(nil);
        end;
      Exit(arr);
    end;
    YYJSON_TYPE_OBJ:    begin
      obj := JsonMutObj(ADoc);
      if JsonObjIterInit(AVal, @o) then
        while JsonObjIterHasNext(@o) do
        begin
          k := JsonObjIterNext(@o);
          v := JsonObjIterGetVal(k);
          s := Copy(k^.Data.Str, 1, UnsafeGetLen(k));
          child := CloneImmToMut(ADoc, v);
          if not JsonMutObjAddVal(ADoc, obj, s, child) then Exit(nil);
        end;
      Exit(obj);
    end;
  else
    Exit(nil);
  end;
end;

function WriteJsonMutValue(AVal: PJsonMutValue; AFlags: TJsonWriteFlags; AIndent: Integer): String;
var
  t: UInt8;
  itO: TJsonMutObjectIterator;
  k, v: PJsonMutValue;
  LIndentStr, LNewIndentStr: String;
  LFirst: Boolean;
  LLast, LCur: PJsonMutValue;
begin
  LIndentStr := '';
  LNewIndentStr := '';
  if not Assigned(AVal) then Exit('null');
  t := UnsafeGetType(PJsonValue(AVal));
  case t of
    YYJSON_TYPE_NULL:   Exit('null');
    YYJSON_TYPE_BOOL:   if UnsafeIsTrue(PJsonValue(AVal)) then Exit('true') else Exit('false');
    YYJSON_TYPE_NUM:    Exit(WriteJsonNumber(PJsonValue(AVal), AFlags));
    YYJSON_TYPE_STR:    Exit(WriteJsonString(AVal^.Data.Str, UnsafeGetLen(PJsonValue(AVal)), AFlags));
    YYJSON_TYPE_ARR:    begin
      Result := '[';
      // Traverse ring from head; do not rely on possibly stale length metadata
      LLast := PJsonMutValue(AVal^.Data.Ptr);
      if Assigned(LLast) then
      begin
        LCur := LLast^.Next; // head (first element)
        LFirst := True;
        repeat
          if not LFirst then Result := Result + ',' else LFirst := False;
          if jwfPretty in AFlags then
          begin
            if LIndentStr = '' then LIndentStr := StringOfChar(' ', AIndent*2);
            LNewIndentStr := LIndentStr + '  ';
            Result := Result + sLineBreak + LNewIndentStr;
          end;
          Result := Result + WriteJsonMutValue(LCur, AFlags, AIndent + 1);
          LCur := LCur^.Next;
        until LCur = LLast^.Next;
      end;
      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + ']'
      else
        Result := Result + ']';
      Exit;
    end;
    YYJSON_TYPE_OBJ:    begin
      Result := '{';
      if JsonMutObjIterInit(AVal, @itO) then
      begin
        LFirst := True;
        while JsonMutObjIterHasNext(@itO) do
        begin
          k := JsonMutObjIterNext(@itO);
          v := k^.Next;
          if not LFirst then Result := Result + ',' else LFirst := False;
          if jwfPretty in AFlags then
          begin
            if LIndentStr = '' then LIndentStr := StringOfChar(' ', AIndent*2);
            LNewIndentStr := LIndentStr + '  ';
            Result := Result + sLineBreak + LNewIndentStr;
          end;
          Result := Result + WriteJsonString(k^.Data.Str, UnsafeGetLen(PJsonValue(k)), AFlags) + ':';
          if (jwfPretty in AFlags) then Result := Result + ' ';
          Result := Result + WriteJsonMutValue(v, AFlags, AIndent + 1);
        end;
      end;
      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + '}'
      else
        Result := Result + '}';
      Exit;
    end;
  else
    Exit('null');
  end;
end;

end.

