{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
program example_json_noexcept_writer;

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json,            // 引入门面单元以带入 Flag 常量
  fafafa.core.json.interfaces,
  fafafa.core.json.noexcept;

var
  R: TJsonReaderNoExcept;
  D: IJsonDocument;
  Code: Integer;
  S: String;
begin
  R := TJsonReaderNoExcept.New(GetRtlAllocator);
  Code := R.ReadFromString('{"ok":true,"n":42}', D, [jrfDefault]);
  if Code <> 0 then
  begin
    Writeln('Read failed, Code=', Code);
    Halt(1);
  end;
  Code := TJsonWriterNoExcept.WriteToString(D, S, [jwfPretty]);
  if Code <> 0 then
  begin
    Writeln('Write failed, Code=', Code);
    Halt(2);
  end;
  Writeln('Output:');
  Writeln(S);
end.

