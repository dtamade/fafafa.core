program debug_incr_utf8;
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.incr;

var
  Al: TAllocator;
  Err: TJsonError;
  Doc: TJsonDocument;
  St: PJsonIncrState;
  S, Buf: AnsiString;
  Mem: PAnsiChar;
  Len, Cut: SizeUInt;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '你好';
  Buf := '{"s":"' + S + '"}';
  Len := Length(Buf);
  GetMem(Mem, Len);
  Move(PChar(Buf)^, Mem^, Len);
  St := JsonIncrNew(Mem, Len, [], Al);
  Writeln('Len=', Len);
  Cut := Pos('"s":"', Buf) + Length('"s":"');
  Cut := Cut + 1;
  Writeln('Cut=', Cut);

  Doc := JsonIncrRead(St, Cut, Err);
  if Doc=nil then Writeln('First: Doc=nil Code=', Ord(Err.Code), ' Pos=', Err.Position, ' Msg=', Err.Message) else Writeln('First: Doc ok');

  Doc := JsonIncrRead(St, Len - Cut, Err);
  if Doc=nil then Writeln('Second: Doc=nil Code=', Ord(Err.Code), ' Pos=', Err.Position, ' Msg=', Err.Message) else Writeln('Second: Doc ok, BytesRead=', JsonDocGetReadSize(Doc));

  if Assigned(Doc) then Doc.Free;
  JsonIncrFree(St);
  FreeMem(Mem);
end.

