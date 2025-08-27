program example_thread_future_helpers;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.thread;

function Work(Data: Pointer): Boolean;
begin
  Sleep(NativeUInt(Data));
  Result := True;
end;

var F1,F2: IFuture; I: Integer; AllOk, OneOk: Boolean;
begin
  F1 := Spawn(@Work, Pointer(100));
  F2 := Spawn(@Work, Pointer(200));

  AllOk := FutureAll([F1,F2], 3000);
  I := FutureAny([F1,F2], 100);
  OneOk := FutureTimeout(F1, 1000);

  Writeln('{"allOk":', LowerCase(BoolToStr(AllOk, True)), ',"anyIndex":', I, ',"timeoutOk":', LowerCase(BoolToStr(OneOk, True)), '}');
end.

