program example_json_patch_min;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr,
  fafafa.core.json.patch;

procedure Run;
var
  Al: TAllocator;
  M: TJsonMutDocument;
  Root, Obj: PJsonMutValue;
  PatchText: String;
  PatchDoc: TJsonDocument;
  Ok: Boolean;
  Err: String;
  S: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObj(M);
  JsonMutObjAddStr(M, Obj, 'k', 'v');
  JsonMutObjAddVal(M, Root, 'o', Obj);

  PatchText := '[{"op":"replace","path":"/o/k","value":"v2"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  Ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), Err);
  if not Ok then Writeln('Patch failed: ', Err);

  S := '';
  if Assigned(JsonMutPtrGet(Root, '/o/k')) then
    SetString(S, JsonGetStr(PJsonValue(JsonMutPtrGet(Root, '/o/k'))), JsonGetLen(PJsonValue(JsonMutPtrGet(Root, '/o/k'))));
  Writeln('o.k = ', S);

  PatchDoc.Free;
  M.Free;
end;

begin
  Run;
end.

