program json_smoke;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

var
  Err: TJsonError;
  Alc: TAllocator;
  Doc: TJsonDocument;
  Root, V: PJsonValue;
  ok: boolean;
  it: TJsonObjectIterator;
  k: PJsonValue;
  val: PJsonValue;
begin
  FillChar(Err, SizeOf(Err), 0);
  FillChar(Alc, SizeOf(Alc), 0);
  Doc := JsonRead('{"a":[{"b":1}]}', Length('{"a":[{"b":1}]}'), [jrfDefault]);
  if Doc = nil then begin
    Writeln('FAIL: Doc=nil');
    Halt(1);
  end;
  Root := JsonDocGetRoot(Doc);
  Writeln('RootType=', JsonGetTypeDesc(Root));
  Writeln('ObjSize=', JsonObjSize(Root));
  V := JsonObjGet(Root, 'a');
  if V = nil then Writeln('ObjGet a = nil') else Writeln('ObjGet a type=', JsonGetTypeDesc(V));
  if V <> nil then begin
    Writeln('a.size=', JsonArrSize(V));
    if JsonArrGet(V, 0) = nil then Writeln('a[0]=nil') else begin
      Writeln('a[0] type=', JsonGetTypeDesc(JsonArrGet(V,0)));
      Writeln('a[0] len=', UnsafeGetLen(JsonArrGet(V,0)));
    end;
    if JsonArrGet(V, 0) <> nil then begin
      Writeln('obj0 size=', JsonObjSize(JsonArrGet(V,0)));
      // iterate keys
      begin
        if JsonObjIterInit(JsonArrGet(V,0), @it) then begin
          while JsonObjIterHasNext(@it) do begin
            k := JsonObjIterNext(@it);
            val := JsonObjIterGetVal(k);
            Writeln('key="', Copy(String(k^.Data.Str),1, JsonGetLen(k)) ,'" type=', JsonGetTypeDesc(val));
          end;
        end;
      end;
      if JsonObjGet(JsonArrGet(V,0), 'b') = nil then Writeln('a[0].b=nil') else Writeln('a[0].b type=', JsonGetTypeDesc(JsonObjGet(JsonArrGet(V,0), 'b')));
    end;
  end;
  V := JsonPtrGet(Root, '/a/0/b');
  if V = nil then begin
    Writeln('PTR_NIL');
  end else begin
    Writeln('TYPE=', JsonGetTypeDesc(V));
  end;
  ok := (V <> nil) and JsonIsNum(V);
  if ok then Writeln('OK') else Writeln('FAIL');
  JsonDocFree(Doc);
end.

