program simd_ops_demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.api;

procedure Demo;
var
  ops: TSimdOps;
  buf: array[0..63] of Byte;
  hay: array[0..31] of Byte;
  ned: array[0..7] of Byte;
  i: Integer;
  idx: PtrInt;
begin
  ops := SimdOps;

  // Fill/Zero
  ops.Mem.Fill(@buf[0], SizeOf(buf), Ord('A'));
  Writeln('Filled first byte: ', Chr(buf[0]));
  ops.Mem.Zero(@buf[0], SizeOf(buf));
  Writeln('Zeroed first byte: ', buf[0]);

  // Copy/Move (允许重叠)
  for i := 0 to High(buf) do buf[i] := i and $FF;
  ops.Mem.Copy(@buf[0], @buf[16], 16);
  Writeln('Copy overlap ok: ', buf[16], ',', buf[31]);

  // FindByte / BytesIndexOf
  FillChar(hay, SizeOf(hay), 0);
  Move(PAnsiChar(AnsiString('hello world'))^, hay[0], 11);
  Move(PAnsiChar(AnsiString('world'))^, ned[0], 5);
  idx := ops.Mem.FindByte(@hay[0], 11, Ord('w'));
  Writeln('FindByte("w") = ', idx);
  idx := ops.Search.BytesIndexOf(@hay[0], 11, @ned[0], 5);
  Writeln('BytesIndexOf("world") = ', idx);

  // FindEOL
  Move(PAnsiChar(AnsiString('abc'+#13#10+'def'))^, hay[0], 5);
  idx := ops.Search.FindEOL(@hay[0], 5);
  Writeln('FindEOL("abc\\r\\n...") = ', idx);
end;

begin
  try
    Demo;
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

