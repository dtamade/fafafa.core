unit fafafa.core.mem.interfaces;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fafafa.core.mem.allocator;

// 说明：本单元仅声明接口类型（P2 预研）。
// 不改变现有类用法；实现仍由现有类（TMemPool/TStackPool/TSlabPool）提供。

// 基础分配器接口（面向抽象）
type
  IAllocator = interface
    ['{E7B8C1B4-8F0C-4D7F-9E7B-AB3BCD8142F9}']
    function GetMem(ASize: SizeUInt): Pointer;
    function AllocMem(ASize: SizeUInt): Pointer;
    function ReallocMem(APtr: Pointer; ANewSize: SizeUInt): Pointer;
    procedure FreeMem(APtr: Pointer);
  end;

  // 固定块内存池接口
  IMemPool = interface
    ['{B03C5A4C-89D9-462E-8F01-3A4C3E1B7F0B}']
    function Alloc: Pointer;
    function TryAlloc(out APtr: Pointer; ASize: SizeUInt): Boolean; // ASize ignored or must be <= BlockSize
    procedure Free(APtr: Pointer);
    procedure Reset;
    function GetBlockSize: SizeUInt;
    function GetCapacity: Integer;
    function GetAllocatedCount: Integer;
  end;

  // 栈式内存池接口
  IStackPool = interface
    ['{9B1F8A19-3A7E-4F89-9D09-CA3CF57C52B8}']
    function Alloc(ASize: SizeUInt; AAlignment: SizeUInt = SizeOf(Pointer)): Pointer;
    function TryAlloc(out APtr: Pointer; ASize: SizeUInt): Boolean; // default alignment = pointer size
    procedure Reset;
    procedure RestoreState(AOffset: SizeUInt);
    function GetTotalSize: SizeUInt;
    function GetOffset: SizeUInt;
  end;

  // Slab 内存池接口
  ISlabPool = interface
    ['{5C82C90D-7E8D-46C7-8B4E-4E8F3E7E8D1F}']
    function Alloc(ASize: SizeUInt): Pointer;
    function TryAlloc(out APtr: Pointer; ASize: SizeUInt): Boolean;
    procedure Free(APtr: Pointer);
    procedure Reset;
  end;

implementation

end.

