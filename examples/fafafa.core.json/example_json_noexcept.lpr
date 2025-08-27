{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
program example_json_noexcept;

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.interfaces,
  fafafa.core.json.noexcept;

procedure DemoOk;
var R: TJsonReaderNoExcept; D: IJsonDocument; Code: Integer;
begin
  R := TJsonReaderNoExcept.New(GetRtlAllocator);
  Code := R.ReadFromString('{"name":"Bob","age":41}', D, [jrfDefault]);
  if Code = 0 then
  begin
    Writeln('OK: name=', D.Root.GetObjectValue('name').GetString, ', age=', D.Root.GetObjectValue('age').GetInteger);
  end
  else
    Writeln('Error Code=', Code);
end;

procedure DemoFail;
var R: TJsonReaderNoExcept; D: IJsonDocument; Code: Integer;
begin
  R := TJsonReaderNoExcept.New(GetRtlAllocator);
  Code := R.ReadFromString('{"a":,}', D, [jrfDefault]);
  if Code = 0 then Writeln('Unexpected OK') else Writeln('Fail as expected, Code=', Code);
end;

begin
  DemoOk;
  DemoFail;
end.

