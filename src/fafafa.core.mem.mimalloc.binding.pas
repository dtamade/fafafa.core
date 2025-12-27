{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.mimalloc.binding - Mimalloc C Library Binding (Dynamic)

## Abstract 摘要

Dynamic FFI binding to Microsoft's mimalloc C library.
使用动态加载绑定微软 mimalloc C 库的 FFI 接口。
支持运行时检测库是否可用，自动回退到 Pascal 实现。

## Prerequisites 前置条件

Linux: sudo apt install libmimalloc-dev
       或从源码编译: https://github.com/microsoft/mimalloc

Windows: 下载预编译 DLL 或从源码编译

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.mimalloc.binding;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.mem.layout,
  fafafa.core.mem.error,
  fafafa.core.mem.alloc;

const
  {$IFDEF WINDOWS}
  MIMALLOC_LIB = 'mimalloc.dll';
  MIMALLOC_LIB_ALT = 'mimalloc.dll';
  {$ELSE}
  MIMALLOC_LIB = 'libmimalloc.so.2';
  MIMALLOC_LIB_ALT = 'libmimalloc.so';
  {$ENDIF}

{------------------------------------------------------------------------------
  Mimalloc C API 函数类型定义
  Function type definitions for dynamic loading
------------------------------------------------------------------------------}

type
  mi_heap_t = Pointer;  // 不透明堆句柄

  {** 基础分配函数类型 *}
  Tmi_malloc = function(size: SizeUInt): Pointer; cdecl;
  Tmi_calloc = function(count: SizeUInt; size: SizeUInt): Pointer; cdecl;
  Tmi_realloc = function(p: Pointer; newsize: SizeUInt): Pointer; cdecl;
  Tmi_free = procedure(p: Pointer); cdecl;

  {** 对齐分配函数类型 *}
  Tmi_malloc_aligned = function(size: SizeUInt; alignment: SizeUInt): Pointer; cdecl;
  Tmi_zalloc_aligned = function(size: SizeUInt; alignment: SizeUInt): Pointer; cdecl;
  Tmi_realloc_aligned = function(p: Pointer; newsize: SizeUInt; alignment: SizeUInt): Pointer; cdecl;
  Tmi_free_aligned = procedure(p: Pointer; alignment: SizeUInt); cdecl;

  {** 清零分配函数类型 *}
  Tmi_zalloc = function(size: SizeUInt): Pointer; cdecl;

  {** 扩展函数类型 *}
  Tmi_malloc_size = function(p: Pointer): SizeUInt; cdecl;
  Tmi_good_size = function(size: SizeUInt): SizeUInt; cdecl;

  {** 堆管理函数类型 *}
  Tmi_heap_new = function: mi_heap_t; cdecl;
  Tmi_heap_delete = procedure(heap: mi_heap_t); cdecl;
  Tmi_heap_destroy = procedure(heap: mi_heap_t); cdecl;
  Tmi_heap_malloc = function(heap: mi_heap_t; size: SizeUInt): Pointer; cdecl;
  Tmi_heap_zalloc = function(heap: mi_heap_t; size: SizeUInt): Pointer; cdecl;
  Tmi_heap_malloc_aligned = function(heap: mi_heap_t; size: SizeUInt; alignment: SizeUInt): Pointer; cdecl;
  Tmi_heap_realloc = function(heap: mi_heap_t; p: Pointer; newsize: SizeUInt): Pointer; cdecl;

{------------------------------------------------------------------------------
  IAlloc 适配器 - 包装 mimalloc C API (动态加载)
------------------------------------------------------------------------------}

type
  {**
   * TMimallocBinding
   *
   * @desc 直接调用 mimalloc C 库的分配器（动态加载）
   *       Allocator that dynamically loads and calls mimalloc C library
   *
   * @performance
   *   - 小对象: ~20-40 ns/op
   *   - 多线程: 近线性扩展
   *   - 内存碎片: 极低
   *
   * @thread-safety 线程安全（mimalloc 内部处理）
   *}
  TMimallocBinding = class(TAllocBase)
  private
    FHeap: mi_heap_t;
    FUsePrivateHeap: Boolean;
  protected
    function DoAlloc(aSize: SizeUInt; aAlign: SizeUInt): Pointer; override;
    procedure DoDealloc(aPtr: Pointer; aSize: SizeUInt; aAlign: SizeUInt); override;
    function DoRealloc(aPtr: Pointer; aOldSize, aNewSize, aAlign: SizeUInt): Pointer; override;
  public
    {**
     * Create
     *
     * @desc 创建分配器
     * @param aUsePrivateHeap 是否使用私有堆（隔离分配）
     * @raises Exception 如果 mimalloc 库不可用
     *}
    constructor Create(aUsePrivateHeap: Boolean = False); reintroduce;
    destructor Destroy; override;

    {** 获取 mimalloc 堆句柄 *}
    property Heap: mi_heap_t read FHeap;
    property UsePrivateHeap: Boolean read FUsePrivateHeap;
  end;

{**
 * GetMimallocBinding
 *
 * @desc 获取全局 mimalloc 绑定分配器单例
 *       Get global mimalloc binding allocator singleton
 *
 * @return IAlloc mimalloc 绑定分配器
 *
 * @note 使用默认堆，线程安全
 * @raises Exception 如果 mimalloc 库不可用
 *}
function GetMimallocBinding: IAlloc;

{**
 * IsMimallocAvailable
 *
 * @desc 检查 mimalloc 库是否可用（运行时检测）
 *       Check if mimalloc library is available at runtime
 *
 * @return True 如果 mimalloc 库可以被加载
 *
 * @note 此函数不会抛出异常，安全用于检测
 *}
function IsMimallocAvailable: Boolean;

{**
 * LoadMimalloc
 *
 * @desc 尝试加载 mimalloc 库
 *       Try to load mimalloc library
 *
 * @return True 如果加载成功
 *}
function LoadMimalloc: Boolean;

{**
 * UnloadMimalloc
 *
 * @desc 卸载 mimalloc 库
 *       Unload mimalloc library
 *}
procedure UnloadMimalloc;

implementation

uses
  DynLibs,
  SysUtils;

var
  GMimallocBinding: IAlloc = nil;
  GMimallocLib: TLibHandle = NilHandle;
  GMimallocLoaded: Boolean = False;
  GMimallocChecked: Boolean = False;

  {** 函数指针 *}
  _mi_malloc: Tmi_malloc = nil;
  _mi_calloc: Tmi_calloc = nil;
  _mi_realloc: Tmi_realloc = nil;
  _mi_free: Tmi_free = nil;
  _mi_malloc_aligned: Tmi_malloc_aligned = nil;
  _mi_zalloc_aligned: Tmi_zalloc_aligned = nil;
  _mi_realloc_aligned: Tmi_realloc_aligned = nil;
  _mi_zalloc: Tmi_zalloc = nil;
  _mi_malloc_size: Tmi_malloc_size = nil;
  _mi_good_size: Tmi_good_size = nil;
  _mi_heap_new: Tmi_heap_new = nil;
  _mi_heap_delete: Tmi_heap_delete = nil;
  _mi_heap_destroy: Tmi_heap_destroy = nil;
  _mi_heap_malloc: Tmi_heap_malloc = nil;
  _mi_heap_zalloc: Tmi_heap_zalloc = nil;
  _mi_heap_malloc_aligned: Tmi_heap_malloc_aligned = nil;
  _mi_heap_realloc: Tmi_heap_realloc = nil;

function TryLoadLibrary(const aName: string): TLibHandle;
begin
  Result := LoadLibrary(aName);
end;

function LoadMimalloc: Boolean;
begin
  if GMimallocLoaded then
    Exit(True);

  // 尝试加载库
  GMimallocLib := TryLoadLibrary(MIMALLOC_LIB);
  if GMimallocLib = NilHandle then
    GMimallocLib := TryLoadLibrary(MIMALLOC_LIB_ALT);

  if GMimallocLib = NilHandle then
    Exit(False);

  // 加载函数指针
  Pointer(_mi_malloc) := GetProcedureAddress(GMimallocLib, 'mi_malloc');
  Pointer(_mi_calloc) := GetProcedureAddress(GMimallocLib, 'mi_calloc');
  Pointer(_mi_realloc) := GetProcedureAddress(GMimallocLib, 'mi_realloc');
  Pointer(_mi_free) := GetProcedureAddress(GMimallocLib, 'mi_free');
  Pointer(_mi_malloc_aligned) := GetProcedureAddress(GMimallocLib, 'mi_malloc_aligned');
  Pointer(_mi_zalloc_aligned) := GetProcedureAddress(GMimallocLib, 'mi_zalloc_aligned');
  Pointer(_mi_realloc_aligned) := GetProcedureAddress(GMimallocLib, 'mi_realloc_aligned');
  Pointer(_mi_zalloc) := GetProcedureAddress(GMimallocLib, 'mi_zalloc');
  Pointer(_mi_malloc_size) := GetProcedureAddress(GMimallocLib, 'mi_malloc_size');
  Pointer(_mi_good_size) := GetProcedureAddress(GMimallocLib, 'mi_good_size');
  Pointer(_mi_heap_new) := GetProcedureAddress(GMimallocLib, 'mi_heap_new');
  Pointer(_mi_heap_delete) := GetProcedureAddress(GMimallocLib, 'mi_heap_delete');
  Pointer(_mi_heap_destroy) := GetProcedureAddress(GMimallocLib, 'mi_heap_destroy');
  Pointer(_mi_heap_malloc) := GetProcedureAddress(GMimallocLib, 'mi_heap_malloc');
  Pointer(_mi_heap_zalloc) := GetProcedureAddress(GMimallocLib, 'mi_heap_zalloc');
  Pointer(_mi_heap_malloc_aligned) := GetProcedureAddress(GMimallocLib, 'mi_heap_malloc_aligned');
  Pointer(_mi_heap_realloc) := GetProcedureAddress(GMimallocLib, 'mi_heap_realloc');

  // 检查核心函数是否加载成功
  if (_mi_malloc = nil) or (_mi_free = nil) then
  begin
    UnloadLibrary(GMimallocLib);
    GMimallocLib := NilHandle;
    Exit(False);
  end;

  GMimallocLoaded := True;
  Result := True;
end;

procedure UnloadMimalloc;
begin
  if GMimallocLib <> NilHandle then
  begin
    UnloadLibrary(GMimallocLib);
    GMimallocLib := NilHandle;
  end;
  GMimallocLoaded := False;

  // 清空函数指针
  _mi_malloc := nil;
  _mi_calloc := nil;
  _mi_realloc := nil;
  _mi_free := nil;
  _mi_malloc_aligned := nil;
  _mi_zalloc_aligned := nil;
  _mi_realloc_aligned := nil;
  _mi_zalloc := nil;
  _mi_malloc_size := nil;
  _mi_good_size := nil;
  _mi_heap_new := nil;
  _mi_heap_delete := nil;
  _mi_heap_destroy := nil;
  _mi_heap_malloc := nil;
  _mi_heap_zalloc := nil;
  _mi_heap_malloc_aligned := nil;
  _mi_heap_realloc := nil;
end;

function IsMimallocAvailable: Boolean;
begin
  if not GMimallocChecked then
  begin
    GMimallocChecked := True;
    LoadMimalloc;
  end;
  Result := GMimallocLoaded;
end;

{ TMimallocBinding }

constructor TMimallocBinding.Create(aUsePrivateHeap: Boolean);
var
  LCaps: TAllocCaps;
begin
  if not IsMimallocAvailable then
    raise Exception.Create('mimalloc library not found. Install: sudo apt install libmimalloc-dev');

  LCaps := TAllocCaps.Create(
    False,  // ZeroOnAlloc - 使用 mi_zalloc 时为 True
    True,   // ThreadSafe
    True,   // KnowsSize - mi_malloc_size
    True,   // NativeAligned - mi_malloc_aligned
    True,   // CanRealloc
    MEM_PAGE_SIZE  // MaxAlign
  );
  inherited Create(LCaps);

  FUsePrivateHeap := aUsePrivateHeap;
  if FUsePrivateHeap and Assigned(_mi_heap_new) then
    FHeap := _mi_heap_new()
  else
    FHeap := nil;  // 使用默认堆
end;

destructor TMimallocBinding.Destroy;
begin
  if FUsePrivateHeap and (FHeap <> nil) and Assigned(_mi_heap_destroy) then
    _mi_heap_destroy(FHeap);
  inherited Destroy;
end;

function TMimallocBinding.DoAlloc(aSize: SizeUInt; aAlign: SizeUInt): Pointer;
begin
  if aAlign <= MEM_DEFAULT_ALIGN then
  begin
    // 默认对齐
    if FUsePrivateHeap and (FHeap <> nil) and Assigned(_mi_heap_malloc) then
      Result := _mi_heap_malloc(FHeap, aSize)
    else
      Result := _mi_malloc(aSize);
  end
  else
  begin
    // 自定义对齐
    if FUsePrivateHeap and (FHeap <> nil) and Assigned(_mi_heap_malloc_aligned) then
      Result := _mi_heap_malloc_aligned(FHeap, aSize, aAlign)
    else if Assigned(_mi_malloc_aligned) then
      Result := _mi_malloc_aligned(aSize, aAlign)
    else
      Result := _mi_malloc(aSize);  // 回退
  end;
end;

procedure TMimallocBinding.DoDealloc(aPtr: Pointer; aSize: SizeUInt; aAlign: SizeUInt);
begin
  // mimalloc 的 mi_free 可以释放任何 mi_malloc* 分配的内存
  // 对齐信息不需要，mimalloc 内部跟踪
  _mi_free(aPtr);
end;

function TMimallocBinding.DoRealloc(aPtr: Pointer; aOldSize, aNewSize, aAlign: SizeUInt): Pointer;
begin
  if aAlign <= MEM_DEFAULT_ALIGN then
  begin
    if FUsePrivateHeap and (FHeap <> nil) and Assigned(_mi_heap_realloc) then
      Result := _mi_heap_realloc(FHeap, aPtr, aNewSize)
    else
      Result := _mi_realloc(aPtr, aNewSize);
  end
  else
  begin
    // 对齐 realloc
    if Assigned(_mi_realloc_aligned) then
      Result := _mi_realloc_aligned(aPtr, aNewSize, aAlign)
    else
      Result := _mi_realloc(aPtr, aNewSize);  // 回退
  end;
end;

{ Global accessors }

function GetMimallocBinding: IAlloc;
begin
  if GMimallocBinding = nil then
  begin
    if not IsMimallocAvailable then
      raise Exception.Create('mimalloc library not found. Install: sudo apt install libmimalloc-dev');
    GMimallocBinding := TMimallocBinding.Create(False);
  end;
  Result := GMimallocBinding;
end;

finalization
  GMimallocBinding := nil;
  UnloadMimalloc;

end.
