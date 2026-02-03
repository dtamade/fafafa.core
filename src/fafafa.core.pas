unit fafafa.core;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  classes,
  SysUtils,
  { fafafa.core }
  fafafa.core.base,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator
  ;

  ///
  /// 异常
  ///

  type

    ECore            = fafafa.core.base.ECore;
    EWow             = fafafa.core.base.EWow;
    EArgumentNil     = fafafa.core.base.EArgumentNil;
    EEmptyCollection = fafafa.core.base.EEmptyCollection;
    EInvalidArgument = fafafa.core.base.EInvalidArgument;
    EOutOfRange      = fafafa.core.base.EOutOfRange;
    ENotSupported    = fafafa.core.base.ENotSupported;
    EOutOfMemory     = fafafa.core.base.EOutOfMemory;


  ///
  /// Allocator 分配器
  ///

    type

    TAllocator    = fafafa.core.mem.allocator.TAllocator;
    IAllocator     = fafafa.core.mem.allocator.IAllocator;
    TRtlAllocator = fafafa.core.mem.allocator.TRtlAllocator;
    TCrtAllocator = fafafa.core.mem.allocator.TCrtAllocator;
    TCallbackAllocator = fafafa.core.mem.allocator.TCallbackAllocator;


  function GetRtlAllocator: IAllocator; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  function GetCrtAllocator: IAllocator; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  {$ENDIF}
  function GetDefaultAllocator: IAllocator; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

  function CreateCallbackAllocator(aGetMem: TGetMemCallback;
                                   aAllocMem: TAllocMemCallback;
                                   aReallocMem: TReallocMemCallback;
                                   aFreeMem: TFreeMemCallback): TCallbackAllocator; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

  ///
  /// 容器
  ///
  /// 注意: IElementManager<T> 和 TElementManager<T> 是泛型类型，
  /// 不能直接作为类型别名导出。请直接使用：
  ///   uses fafafa.core.collections.elementManager;
  /// 然后使用 specialize 关键字特化泛型：
  ///   type TMyElementManager = specialize TElementManager<TMyType>;
  ///

  ///
  /// MemPool 内存池
  ///




  ///
  /// Thread 线程
  ///


implementation

function GetRtlAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.GetRtlAllocator();
end;

{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
function GetCrtAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.GetCrtAllocator();
end;
{$ENDIF}

function GetDefaultAllocator: IAllocator;
begin
  Result := GetRtlAllocator();
end;

function CreateCallbackAllocator(aGetMem: TGetMemCallback;
  aAllocMem: TAllocMemCallback; aReallocMem: TReallocMemCallback;
  aFreeMem: TFreeMemCallback): TCallbackAllocator;
begin
  Result := fafafa.core.mem.allocator.CreateCallbackAllocator(aGetMem, aAllocMem, aReallocMem, aFreeMem);
end;



end.
