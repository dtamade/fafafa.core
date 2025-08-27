{$CODEPAGE UTF8}
unit Test_shared_memory;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.mem,
  fafafa.core.mem.memoryMap;

type
  TTestCase_SharedMemory = class(TTestCase)
  private
    procedure WriteBytes(p: PByte; const buf: RawByteString);
    function ReadBytes(p: PByte): RawByteString;
  published
    procedure Test_Shared_Create_Write_Read_Close;
    procedure Test_LPBytes_RW_Shared;
    procedure Test_LPUTF8_RW_Shared;
  end;

implementation

procedure TTestCase_SharedMemory.WriteBytes(p: PByte; const buf: RawByteString);
var
  L: UInt32;
begin
  L := Length(buf);
  Move(L, p^, SizeOf(L));
  Inc(p, SizeOf(L));
  if L > 0 then
    Move(buf[1], p^, L);
end;

function TTestCase_SharedMemory.ReadBytes(p: PByte): RawByteString;
var
  L: UInt32;
begin
  Move(p^, L, SizeOf(L));
  Inc(p, SizeOf(L));
  SetLength(Result, L);
  if L > 0 then
    Move(p^, Result[1], L);
end;

procedure TTestCase_SharedMemory.Test_Shared_Create_Write_Read_Close;
var
  sh: TSharedMemory;
  dataW, dataR: RawByteString;
  base: PByte;
begin
  sh := TSharedMemory.Create;
  try
    AssertTrue('CreateShared should succeed', sh.CreateShared('UT_SharedMem_' + IntToHex(Random(MaxInt), 8), 1024, mmaReadWrite));
    AssertTrue('IsValid should be true', sh.IsValid);
    AssertTrue('IsCreator should be true', sh.IsCreator);
    AssertEquals('Size should match', UInt64(1024), sh.Size);

    dataW := UTF8Encode('共享内存单元测试/Shared');
    base := PByte(sh.BaseAddress);
    WriteBytes(base, dataW);

    dataR := ReadBytes(PByte(sh.BaseAddress));
    SetCodePage(dataR, CP_UTF8, False);
    SetCodePage(dataW, CP_UTF8, False);
    AssertEquals('Roundtrip bytes should match', UTF8String(dataW), UTF8String(dataR));
  finally
    sh.Free;
  end;
end;

procedure TTestCase_SharedMemory.Test_LPBytes_RW_Shared;
var
  sh: TSharedMemory;
  w, r: RawByteString;
  ok: Boolean;
begin
  sh := TSharedMemory.Create;
  try
    AssertTrue(sh.CreateShared('UT_Shared_LP_' + IntToHex(Random(MaxInt), 8), 1024, mmaReadWrite));
    w := UTF8Encode('共享LPBytes测试');
    ok := sh.WriteLPBytes(0, w);
    AssertTrue('WriteLPBytes ok', ok);
    ok := sh.ReadLPBytes(0, r);
    AssertTrue('ReadLPBytes ok', ok);
    SetCodePage(w, CP_UTF8, False);
    SetCodePage(r, CP_UTF8, False);
    AssertEquals(UTF8String(w), UTF8String(r));
  finally
    sh.Free;
  end;
end;

procedure TTestCase_SharedMemory.Test_LPUTF8_RW_Shared;
var
  sh: TSharedMemory;
  sW: UnicodeString;
  sR: UTF8String;
  ok: Boolean;
begin
  sh := TSharedMemory.Create;
  try
    AssertTrue(sh.CreateShared('UT_Shared_UTF8_' + IntToHex(Random(MaxInt), 8), 1024, mmaReadWrite));
    sW := 'UTF8混合-🙂/✓/中文abc123';
    ok := sh.WriteLPUTF8(0, sW);
    AssertTrue('WriteLPUTF8 ok', ok);
    ok := sh.ReadLPUTF8(0, sR);
    AssertTrue('ReadLPUTF8 ok', ok);
    AssertEquals(UTF8Encode(sW), sR);
  finally
    sh.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_SharedMemory);

end.

