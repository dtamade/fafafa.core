program example_ensure_vs_capacity;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.collections.vec,
  fafafa.core.mem.allocator;

var
  V: specialize TVec<String>;
  OldCount, OldCap: SizeUInt;
begin
  Writeln('== TVec Ensure vs EnsureCapacity Demo ==');
  V := specialize TVec<String>.Create(['A','B']);
  try
    Writeln('Initial: Count=', V.GetCount, ' Capacity=', V.GetCapacity);

    OldCount := V.GetCount;
    OldCap   := V.GetCapacity;

    V.EnsureCapacity(OldCap + 8);
    Writeln('After EnsureCapacity(+8): Count=', V.GetCount, ' Capacity=', V.GetCapacity,
            ' (Count should stay ', OldCount, ')');

    V.Ensure(5); // legacy behavior: increases Count
    Writeln('After Ensure(5): Count=', V.GetCount, ' Capacity=', V.GetCapacity,
            ' (Count should be >= 5)');

    // Show newly grown slots are initialized (safe for managed types)
    V[2] := 'C';
    V[3] := 'D';
    V[4] := 'E';
    Writeln('Values: ', V[0], ',', V[1], ',', V[2], ',', V[3], ',', V[4]);
  finally
    V.Free;
  end;
end.

