{
# fafafa.core.mem.allocator.foundation

Low-level allocator convenience facade.

This unit re-exports the allocator contract together with the small concrete
backends that remain convenient for the mem domain, but it is no longer the
strict L0 source-of-truth boundary.
}

unit fafafa.core.mem.allocator.foundation;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.allocator.rtlAllocator,
  fafafa.core.mem.allocator.callbackAllocator;

type
  IAllocator = fafafa.core.mem.allocator.base.IAllocator;
  TAllocator = fafafa.core.mem.allocator.base.TAllocator;

  TGetMemCallback = fafafa.core.mem.allocator.callbackAllocator.TGetMemCallback;
  TAllocMemCallback = fafafa.core.mem.allocator.callbackAllocator.TAllocMemCallback;
  TReallocMemCallback = fafafa.core.mem.allocator.callbackAllocator.TReallocMemCallback;
  TFreeMemCallback = fafafa.core.mem.allocator.callbackAllocator.TFreeMemCallback;

  TRtlAllocator = fafafa.core.mem.allocator.rtlAllocator.TRtlAllocator;
  TCallbackAllocator = fafafa.core.mem.allocator.callbackAllocator.TCallbackAllocator;

function GetRtlAllocator: IAllocator;
function CreateCallbackAllocator(aGetMem: TGetMemCallback;
                                 aAllocMem: TAllocMemCallback;
                                 aReallocMem: TReallocMemCallback;
                                 aFreeMem: TFreeMemCallback): TCallbackAllocator;

implementation

function GetRtlAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.rtlAllocator.GetRtlAllocator;
end;

function CreateCallbackAllocator(aGetMem: TGetMemCallback;
  aAllocMem: TAllocMemCallback; aReallocMem: TReallocMemCallback; aFreeMem: TFreeMemCallback): TCallbackAllocator;
begin
  Result := fafafa.core.mem.allocator.callbackAllocator.CreateCallbackAllocator(aGetMem, aAllocMem, aReallocMem, aFreeMem);
end;

end.
