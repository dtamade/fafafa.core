program example_arr_quickstart;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.collections.arr,        // TArray<T>, IArray<T>
  fafafa.core.collections.base,       // TGenericArray<T>
  fafafa.core.mem.allocator;          // GetRtlAllocator

var
  A: specialize TArray<Integer>;
  Src: array[0..3] of Integer = (1,2,3,4);
  Buf: specialize TGenericArray<Integer>;
  i: Integer;
begin
  try
    // 空数组（默认分配器）
    A := specialize TArray<Integer>.Create(4, GetRtlAllocator);
    for i := 0 to 3 do A.Put(i, i+1);

    // 从静态数组构造（复制）
    A := specialize TArray<Integer>.Create(Src, GetRtlAllocator);

    // 基本操作
    A.Put(0, 42);
    if A.Get(0) = 42 then WriteLn('OK: Put/Get');

    // 批量覆写与反转（指针重载）
    A.OverWrite(0, @Src[0], Length(Src));
    A.Reverse(0, Length(Src));

    // 读取到动态数组
    A.Read(0, Buf, Length(Src));
    WriteLn('Buf length: ', Length(Buf));
    for i := 0 to High(Buf) do Write(Format('%d ', [Buf[i]]));
    WriteLn;
  except
    on E: Exception do
    begin
      WriteLn('Example error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

