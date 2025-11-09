unit fafafa.core.collections.queue;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base;

type

  { IQueue 泛型队列接口（最小且完整的 FIFO 语义；不继承 IGenericCollection） }
  generic IQueue<T> = interface
  ['{8D2A4A2F-3C7C-4E94-A763-6E2E7D6C5D37}']
    { 入队（同名重载） }
    procedure Push(const aElement: T); overload;              // 失败抛异常（如有容量上限）
    procedure Push(const aSrc: array of T); overload;         // 全部入队，遇满抛异常
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload; // 指针批量

    { 出队（Try 语义与异常语义） }
    function  Pop(out aElement: T): Boolean; overload;        // 空返回 False
    function  Pop: T; overload;                               // 空抛异常

    { 预览（不移除）— 若实现不支持可返回 False/抛异常 }
    function  TryPeek(out aElement: T): Boolean; overload;    // 空或不支持返回 False
    function  Peek: T; overload;                              // 空或不支持抛异常

    { 状态与维护（最佳努力） }
    function  IsEmpty: Boolean;                               // 并发下允许竞态
    procedure Clear;                                          // 最佳努力清空
    function  Count: SizeUInt;                                // 精确或最佳努力计数（不支持可返回 0）
  end;

  { IDeque 双端队列接口 - 扩展IQueue支持双端操作 }
  generic IDeque<T> = interface(specialize IQueue<T>)
  ['{F1A2B3C4-D5E6-4F78-9A0B-1C2D3E4F5A6B}']
    // Front/Back 访问
    function Front: T; overload;
    function Front(var aElement: T): Boolean; overload;
    function Back: T; overload;
    function Back(var aElement: T): Boolean; overload;

    // 双端 Push/Pop
    procedure PushFront(const aElement: T); overload;
    procedure PushFront(const aElements: array of T); overload;
    procedure PushFront(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    procedure PushBack(const aElement: T); overload;
    procedure PushBack(const aElements: array of T); overload;
    procedure PushBack(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    function PopFront: T; overload;
    function PopFront(var aElement: T): Boolean; overload;
    function PopBack: T; overload;
    function PopBack(var aElement: T): Boolean; overload;

    // 随机访问与修改
    procedure Swap(aIndex1, aIndex2: SizeUInt);
    function Get(aIndex: SizeUInt): T;
    function TryGet(aIndex: SizeUInt; var aElement: T): Boolean;
    procedure Insert(aIndex: SizeUInt; const aElement: T);
    function Remove(aIndex: SizeUInt): T;
    function TryRemove(aIndex: SizeUInt; var aElement: T): Boolean;

    // 容量与尺寸管理
    procedure Reserve(aAdditional: SizeUInt);
    procedure ReserveExact(aAdditional: SizeUInt);
    procedure ShrinkToFit;
    procedure ShrinkTo(aMinCapacity: SizeUInt);
    procedure Truncate(aLen: SizeUInt);
    procedure Resize(aNewSize: SizeUInt; const aValue: T);

    // 批量与结构操作
    procedure Append(const aOther: specialize IQueue<T>);
    function SplitOff(aAt: SizeUInt): specialize IQueue<T>;
  end;

implementation

end.
