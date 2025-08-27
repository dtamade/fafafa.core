program plays_forwardlist;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.collections.forwardList,
  fafafa.core.mem.allocator;

procedure ExerciseInt;
var
  L: specialize TForwardList<Integer>;
  i: Integer;
begin
  Writeln('--- ExerciseInt (unmanaged) ---');
  L := specialize TForwardList<Integer>.Create;
  try
    for i := 1 to 1000 do L.PushFront(i);
    for i := 1 to 500 do L.PopFront;
    L.Clear;
    for i := 1 to 100 do L.PushFront(i);
  finally
    L.Free;
  end;
end;

procedure ExerciseString;
var
  L: specialize TForwardList<String>;
  i: Integer;
begin
  Writeln('--- ExerciseString (managed) ---');
  L := specialize TForwardList<String>.Create;
  try
    for i := 1 to 1000 do L.PushFront('S' + IntToStr(i));
    for i := 1 to 500 do L.PopFront;
    L.Clear; // ensure manager finalizes remaining
    for i := 1 to 100 do L.PushFront('X' + IntToStr(i));
  finally
    L.Free;
  end;

end;

procedure ExerciseCtorDtorOnly;
var
  i: Integer;
  L: specialize TForwardList<Integer>;
begin
  Writeln('--- ExerciseCtorDtorOnly (1000x) ---');
  for i := 1 to 1000 do
  begin
    L := specialize TForwardList<Integer>.Create;
    L.Free;
  end;
end;

procedure ExercisePushPopSingleNode;
var
  i: Integer;
  L: specialize TForwardList<Integer>;
begin
  Writeln('--- ExercisePushPopSingleNode (1000x) ---');
  for i := 1 to 1000 do
  begin
    L := specialize TForwardList<Integer>.Create;
    try
      L.PushFront(42);
      if L.PopFront <> 42 then Writeln('PopFront mismatch');
    finally
      L.Free;
    end;
  end;
end;

begin
  Writeln('== ForwardList heaptrc play ==');
  ExerciseCtorDtorOnly;
  ExercisePushPopSingleNode;
  ExerciseInt;
  ExerciseString;
  {$IFDEF DEBUG}
  Writeln('Ctor/Dtor: ', FL_GetCtorCount, ' / ', FL_GetDtorCount, '  Δ=', FL_GetCtorDtorDelta);
  {$ELSE}
  Writeln('Ctor/Dtor counters require DEBUG define');
  {$ENDIF}
  Writeln('Done.');
end.

