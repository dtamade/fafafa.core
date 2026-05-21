program example_simd_public_api_v2;

{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.simd.api.v2;

procedure Demo;
var
  LBufA: array[0..15] of Byte;
  LBufB: array[0..15] of Byte;
  LNeedle: array[0..2] of Byte;
  LIndex: Integer;
  LMatchPos: PtrInt;
begin
  if GetBoundPublicApiV2 = nil then
    raise Exception.Create('SIMD public API v2 snapshot is unavailable');

  for LIndex := 0 to High(LBufA) do
  begin
    LBufA[LIndex] := Byte((LIndex * 7) and $FF);
    LBufB[LIndex] := LBufA[LIndex];
  end;

  WriteLn('SnapshotGeneration=', GetSnapshotGeneration);
  WriteLn('SnapshotFlags=', Cardinal(GetSnapshotFlags));
  WriteLn('SupportsDirectDataPlane=', SupportsDirectDataPlane);

  if not MemEqual(@LBufA[0], @LBufB[0], SizeOf(LBufA)) then
    raise Exception.Create('MemEqual should succeed on equal buffers');

  LBufB[6] := $AA;
  if MemEqual(@LBufA[0], @LBufB[0], SizeOf(LBufA)) then
    raise Exception.Create('MemEqual should fail after buffer mutation');

  LNeedle[0] := LBufA[4];
  LNeedle[1] := LBufA[5];
  LNeedle[2] := LBufA[6];
  LMatchPos := BytesIndexOf(@LBufA[0], SizeOf(LBufA), @LNeedle[0], SizeOf(LNeedle));
  WriteLn('BytesIndexOf=', LMatchPos);

  MemCopy(@LBufA[0], @LBufB[0], SizeOf(LBufA));
  if not MemEqual(@LBufA[0], @LBufB[0], SizeOf(LBufA)) then
    raise Exception.Create('MemCopy should restore parity');
end;

begin
  try
    Demo;
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
