unit test_allocator_foundation_runtime;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.mem.allocator.foundation;

type
  TTestCase_AllocatorFoundationRuntime = class(TTestCase)
  published
    procedure Test_GetRtlAllocator_ZeroSize_NoOp;
    procedure Test_GetRtlAllocator_ReallocNil_Allocates;
    procedure Test_GetRtlAllocator_ReallocZero_Frees;
    procedure Test_CreateCallbackAllocator_ForwardsCalls;
    procedure Test_CreateCallbackAllocator_RejectsNilCallbacks;
  end;

implementation

var
  GGetMemCalls: SizeInt = 0;
  GAllocMemCalls: SizeInt = 0;
  GReallocMemCalls: SizeInt = 0;
  GFreeMemCalls: SizeInt = 0;

function RuntimeGetMem(aSize: SizeUInt): Pointer;
begin
  Inc(GGetMemCalls);
  Result := System.GetMem(aSize);
end;

function RuntimeAllocMem(aSize: SizeUInt): Pointer;
begin
  Inc(GAllocMemCalls);
  Result := System.AllocMem(aSize);
end;

function RuntimeReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
begin
  Inc(GReallocMemCalls);
  Result := System.ReallocMem(aDst, aSize);
end;

procedure RuntimeFreeMem(aDst: Pointer);
begin
  Inc(GFreeMemCalls);
  System.FreeMem(aDst);
end;

procedure ResetCallbackCounters;
begin
  GGetMemCalls := 0;
  GAllocMemCalls := 0;
  GReallocMemCalls := 0;
  GFreeMemCalls := 0;
end;

procedure TTestCase_AllocatorFoundationRuntime.Test_GetRtlAllocator_ZeroSize_NoOp;
var
  LAllocator: IAllocator;
begin
  LAllocator := GetRtlAllocator;
  AssertNull('GetMem(0) should return nil', LAllocator.GetMem(0));
  AssertNull('AllocMem(0) should return nil', LAllocator.AllocMem(0));
end;

procedure TTestCase_AllocatorFoundationRuntime.Test_GetRtlAllocator_ReallocNil_Allocates;
var
  LAllocator: IAllocator;
  LPtr: Pointer;
begin
  LAllocator := GetRtlAllocator;
  LPtr := LAllocator.ReallocMem(nil, 64);
  try
    AssertNotNull('ReallocMem(nil, 64) should allocate', LPtr);
  finally
    LAllocator.FreeMem(LPtr);
  end;
end;

procedure TTestCase_AllocatorFoundationRuntime.Test_GetRtlAllocator_ReallocZero_Frees;
var
  LAllocator: IAllocator;
  LPtr: Pointer;
begin
  LAllocator := GetRtlAllocator;
  LPtr := LAllocator.GetMem(32);
  AssertNotNull('GetMem(32) should allocate', LPtr);
  AssertNull('ReallocMem(ptr, 0) should free and return nil', LAllocator.ReallocMem(LPtr, 0));
end;

procedure TTestCase_AllocatorFoundationRuntime.Test_CreateCallbackAllocator_ForwardsCalls;
var
  LAllocator: TCallbackAllocator;
  LPtr: Pointer;
begin
  ResetCallbackCounters;
  LAllocator := CreateCallbackAllocator(@RuntimeGetMem, @RuntimeAllocMem, @RuntimeReallocMem, @RuntimeFreeMem);
  try
    LPtr := LAllocator.GetMem(16);
    AssertEquals('GetMem callback should be invoked once', 1, GGetMemCalls);
    AssertNotNull('GetMem should return non-nil pointer', LPtr);

    LPtr := LAllocator.ReallocMem(LPtr, 48);
    AssertEquals('ReallocMem callback should be invoked once', 1, GReallocMemCalls);
    AssertNotNull('ReallocMem should return non-nil pointer', LPtr);

    LAllocator.FreeMem(LPtr);
    AssertEquals('FreeMem callback should be invoked once', 1, GFreeMemCalls);

    LPtr := LAllocator.AllocMem(24);
    AssertEquals('AllocMem callback should be invoked once', 1, GAllocMemCalls);
    AssertNotNull('AllocMem should return non-nil pointer', LPtr);
    LAllocator.FreeMem(LPtr);
    AssertEquals('FreeMem callback should be invoked twice', 2, GFreeMemCalls);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_AllocatorFoundationRuntime.Test_CreateCallbackAllocator_RejectsNilCallbacks;
begin
  AssertException('CreateCallbackAllocator should reject nil callbacks', EArgumentNil, procedure
  begin
    CreateCallbackAllocator(nil, @RuntimeAllocMem, @RuntimeReallocMem, @RuntimeFreeMem).Free;
  end);
end;

initialization
  RegisterTest(TTestCase_AllocatorFoundationRuntime);

end.
