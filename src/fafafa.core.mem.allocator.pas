{
# fafafa.core.mem.allocator

## 摘要

提供内存分配器的接口和实现.

本单元所有接口完全遵守 `空操作原则`, 输入参数 `count = 0` 时, 不进行任何操作.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.allocator;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.allocator.rtlAllocator,
  fafafa.core.mem.allocator.callbackAllocator,
  fafafa.core.mem.allocator.mimalloc
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  ,fafafa.core.mem.allocator.crtAllocator
  {$ENDIF}
  ;

type
  // 门面导出：接口与抽象基类（保留 IAllocator 名称于本单元，通过别名重导出）
  IAllocator = fafafa.core.mem.allocator.base.IAllocator;
  TAllocator = fafafa.core.mem.allocator.base.TAllocator;

  // 回调类型重导出（从 callbackAllocator 单元）
  TGetMemCallback     = fafafa.core.mem.allocator.callbackAllocator.TGetMemCallback;
  TAllocMemCallback   = fafafa.core.mem.allocator.callbackAllocator.TAllocMemCallback;
  TReallocMemCallback = fafafa.core.mem.allocator.callbackAllocator.TReallocMemCallback;
  TFreeMemCallback    = fafafa.core.mem.allocator.callbackAllocator.TFreeMemCallback;

  // 具体分配器类型重导出
  TRtlAllocator = fafafa.core.mem.allocator.rtlAllocator.TRtlAllocator;
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  TCrtAllocator = fafafa.core.mem.allocator.crtAllocator.TCrtAllocator;
  {$ENDIF}
  TCallbackAllocator = fafafa.core.mem.allocator.callbackAllocator.TCallbackAllocator;

  // 获取/工厂函数声明（门面转发）
  function GetRtlAllocator: IAllocator;
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  function GetCrtAllocator: IAllocator;
  {$ENDIF}
  function GetMimallocAllocator: IAllocator;
  function TryGetMimallocAllocator(out A: IAllocator): Boolean;
  function CreateCallbackAllocator(aGetMem: TGetMemCallback;
                                   aAllocMem: TAllocMemCallback;
                                   aReallocMem: TReallocMemCallback;
                                   aFreeMem: TFreeMemCallback): TCallbackAllocator;

implementation

function GetRtlAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.rtlAllocator.GetRtlAllocator;
end;

function GetMimallocAllocator: IAllocator; inline;
begin
  Result := fafafa.core.mem.allocator.mimalloc.GetMimallocAllocator;
end;

function TryGetMimallocAllocator(out A: IAllocator): Boolean; inline;
begin
  Result := fafafa.core.mem.allocator.mimalloc.TryGetMimallocAllocator(A);
end;

{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
function GetCrtAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.crtAllocator.GetCrtAllocator;
end;
{$ENDIF}


function CreateCallbackAllocator(aGetMem: TGetMemCallback;
  aAllocMem: TAllocMemCallback; aReallocMem: TReallocMemCallback; aFreeMem: TFreeMemCallback): TCallbackAllocator;
begin
  Result := fafafa.core.mem.allocator.callbackAllocator.CreateCallbackAllocator(aGetMem, aAllocMem, aReallocMem, aFreeMem);
end;

end.
