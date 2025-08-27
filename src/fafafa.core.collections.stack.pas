unit fafafa.core.collections.stack;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type

  { IStack 泛型栈接口（最小且完整的栈语义；不继承 IGenericCollection） }
  generic IStack<T> = interface
  ['{b2d0130d-760b-4369-86c8-4ccd5ddac18c}']
    { 基本压栈（同名重载） }
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;

    { 弹栈（Try 语义与异常语义） }
    function  Pop(out aElement: T): Boolean; overload; // 空返回 False
    function  Pop: T; overload;                        // 空抛异常

    { 预览（不弹出） }
    function  TryPeek(out aElement: T): Boolean; overload; // 空返回 False（快照语义）
    function  Peek: T; overload;                            // 空抛异常

    { 状态与维护 }
    function  IsEmpty: Boolean;
    procedure Clear;                 // 最佳努力；并发下允许竞态
    function  Count: SizeUInt;       // 精确或最佳努力计数
  end;

  { 数组栈 }

  generic function MakeArrayStack<T>: specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeArrayStack<T>(const aSrc: Pointer; aElementCount: SizeUInt): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeArrayStack<T>(const aSrc: array of T): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: array of T; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeArrayStack<T>(const aSrc: TCollection): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: TCollection; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeArrayStack<T>(const aSrc: TCollection; aElementCount: SizeUInt): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeArrayStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  { 链表栈 }

  generic function MakeLinkedStack<T>: specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeLinkedStack<T>(const aSrc: Pointer; aElementCount: SizeUInt): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeLinkedStack<T>(const aSrc: array of T): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: array of T; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeLinkedStack<T>(const aSrc: TCollection): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: TCollection; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

  generic function MakeLinkedStack<T>(const aSrc: TCollection; aElementCount: SizeUInt): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>; overload;
  generic function MakeLinkedStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;

implementation

uses
  fafafa.core.collections.arr;

generic function MakeArrayStack<T>: specialize IStack<T>;
begin
  
end;

generic function MakeArrayStack<T>(aAllocator: IAllocator): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(aAllocator: IAllocator; aData: Pointer): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: Pointer; aElementCount: SizeUInt): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: array of T): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: array of T; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: TCollection): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: TCollection; aAllocator: IAllocator): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: TCollection; aElementCount: SizeUInt): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>;
begin

end;

generic function MakeArrayStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>;
begin

end;


generic function MakeLinkedStack<T>: specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(aAllocator: IAllocator): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: Pointer; aElementCount: SizeUInt): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: Pointer; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: array of T): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: array of T; aAllocator: IAllocator): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: array of T; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: TCollection): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: TCollection; aAllocator: IAllocator): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: TCollection; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: TCollection; aElementCount: SizeUInt): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator): specialize IStack<T>; overload;
begin

end;

generic function MakeLinkedStack<T>(const aSrc: TCollection; aElementCount: SizeUInt; aAllocator: IAllocator; aData: Pointer): specialize IStack<T>; overload;
begin

end;




end.