program example_reader_flags;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

var
  Doc: TJsonDocument; Err: TJsonError; Root, V: PJsonValue; S: AnsiString;
begin
  S := '{//c1\n"a":1, "b":[1,2,],}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowComments, jrfAllowTrailingCommas], GetRtlAllocator(), Err);
  if not Assigned(Doc) then begin Writeln('parse failed'); Halt(1); end;
  Root := JsonDocGetRoot(Doc);
  V := JsonPtrGet(Root, '/b');
  Writeln('b size = ', JsonArrSize(V));
  Doc.Free;
end.

