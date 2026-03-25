unit test_allocator_foundation_contract;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator.foundation;

type
  TTestCase_AllocatorFoundationContract = class(TTestCase)
  published
    procedure Test_api_compile_contract;
  end;

implementation

function CallbackGetMem(aSize: SizeUInt): Pointer;
begin
  Result := System.GetMem(aSize);
end;

function CallbackAllocMem(aSize: SizeUInt): Pointer;
begin
  Result := System.AllocMem(aSize);
end;

function CallbackReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
begin
  Result := System.ReallocMem(aDst, aSize);
end;

procedure CallbackFreeMem(aDst: Pointer);
begin
  System.FreeMem(aDst);
end;

procedure TTestCase_AllocatorFoundationContract.Test_api_compile_contract;
var
  LAllocator: IAllocator;
  LAllocatorClass: TAllocator;
  LRtlAllocator: TRtlAllocator;
  LCallbackAllocator: TCallbackAllocator;
  LGetMem: TGetMemCallback;
  LAllocMem: TAllocMemCallback;
  LReallocMem: TReallocMemCallback;
  LFreeMem: TFreeMemCallback;
begin
  LAllocator := GetRtlAllocator;
  AssertTrue('GetRtlAllocator should expose IAllocator', LAllocator <> nil);

  LRtlAllocator := TRtlAllocator.Create;
  try
    LAllocatorClass := LRtlAllocator;
    AssertTrue('TRtlAllocator should be assignable to TAllocator', LAllocatorClass <> nil);
  finally
    LRtlAllocator.Free;
  end;

  LGetMem := @CallbackGetMem;
  LAllocMem := @CallbackAllocMem;
  LReallocMem := @CallbackReallocMem;
  LFreeMem := @CallbackFreeMem;

  LCallbackAllocator := CreateCallbackAllocator(LGetMem, LAllocMem, LReallocMem, LFreeMem);
  try
    AssertTrue('CreateCallbackAllocator should return TCallbackAllocator', LCallbackAllocator <> nil);
  finally
    LCallbackAllocator.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_AllocatorFoundationContract);

end.
