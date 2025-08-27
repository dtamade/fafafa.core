unit test_ring_buffer_try_ops;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.mem.ringBuffer;

procedure RegisterRingBufferTryOpsTests;

implementation

type
  TRingBufferTryOpsCase = class(TTestCase)
  published
    procedure Test_TryPush_Full_ReturnsFull;
    procedure Test_TryPop_Empty_ReturnsEmpty;
    procedure Test_Try_BadArg_ReturnsBadArg;
    procedure Test_Try_Ok_ReturnsOk;
  end;

procedure TRingBufferTryOpsCase.Test_TryPush_Full_ReturnsFull;
var
  rb: TRingBuffer;
  v: UInt32;
  i: Integer;
  r: TRingOpResult;
begin
  rb := TRingBuffer.Create(2, SizeOf(UInt32));
  try
    v := 1; for i := 1 to 2 do CheckTrue(rb.Push(@v));
    v := 3; r := rb.TryPush(@v);
    CheckEquals(Ord(rrFull), Ord(r));
  finally
    rb.Free;
  end;
end;

procedure TRingBufferTryOpsCase.Test_TryPop_Empty_ReturnsEmpty;
var
  rb: TRingBuffer;
  v: UInt32;
  r: TRingOpResult;
begin
  rb := TRingBuffer.Create(1, SizeOf(UInt32));
  try
    r := rb.TryPop(@v);
    CheckEquals(Ord(rrEmpty), Ord(r));
  finally
    rb.Free;
  end;
end;

procedure TRingBufferTryOpsCase.Test_Try_BadArg_ReturnsBadArg;
var
  rb: TRingBuffer;
  r: TRingOpResult;
begin
  rb := TRingBuffer.Create(1, SizeOf(UInt32));
  try
    r := rb.TryPush(nil); CheckEquals(Ord(rrBadArg), Ord(r));
    r := rb.TryPop(nil);  CheckEquals(Ord(rrBadArg), Ord(r));
  finally
    rb.Free;
  end;
end;

procedure TRingBufferTryOpsCase.Test_Try_Ok_ReturnsOk;
var
  rb: TRingBuffer;
  vIn, vOut: UInt32;
  r: TRingOpResult;
begin
  rb := TRingBuffer.Create(2, SizeOf(UInt32));
  try
    vIn := 42; r := rb.TryPush(@vIn); CheckEquals(Ord(rrOk), Ord(r));
    r := rb.TryPop(@vOut); CheckEquals(Ord(rrOk), Ord(r));
    CheckEquals(vIn, vOut);
  finally
    rb.Free;
  end;
end;

procedure RegisterRingBufferTryOpsTests;
begin
  RegisterTest('ringbuffer-tryops', TRingBufferTryOpsCase);
end;

end.

