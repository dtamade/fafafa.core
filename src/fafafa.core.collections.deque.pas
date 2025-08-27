unit fafafa.core.collections.deque;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.collections.queue;

type

  { IDeque 泛型双端队列接口：在 IQueue 基础上提供双端/随机访问/容量管理等扩展能力 }
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
