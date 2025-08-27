unit fafafa.core.lockfree.michaelScottQueue;


{$mode objfpc}{$H+}

interface


uses
  fafafa.core.collections.queue;




type
  generic TMichaelScottQueue<T> = class(TInterfacedObject, specialize IQueue<T>)
  public
    type
      PNode = ^TNode;
      TNode = record
        Data: T;
        Next: PNode;
        HasData: Boolean;
      end;
  private
    FHead: PNode;
    FTail: PNode;
  public
    constructor Create;
      // IQueue<T> 额外语义在实现节提供

    destructor Destroy; override;
    procedure Enqueue(const AItem: T);
    // IQueue<T>
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    function  Pop(out aElement: T): Boolean; overload;
    function  Pop: T; overload;
    function  TryPeek(out aElement: T): Boolean; overload;
    function  Peek: T; overload;
    procedure Clear;
    function  Count: SizeUInt;

    function Dequeue(out AItem: T): Boolean;
    function IsEmpty: Boolean;
  end;

implementation

uses
  SysUtils, fafafa.core.atomic,
  fafafa.core.lockfree.reclaim;

procedure MSQ_DisposeNode(p: Pointer);
begin
  if p <> nil then
    Dispose(PNode(p));
end;

constructor TMichaelScottQueue.Create;
begin
  inherited Create;
  New(FHead);
  FHead^.Next := nil;
  FHead^.HasData := False;
  FTail := FHead;
end;

destructor TMichaelScottQueue.Destroy;
var
  LNode, LNext: PNode;
begin
  LNode := FHead;
  while LNode <> nil do
  begin
    LNext := LNode^.Next;
    // retire nodes; in Immediate mode this frees directly
    lf_retire(LNode, @MSQ_DisposeNode);
    LNode := LNext;
  end;
  // ensure all retired nodes are reclaimed (Immediate: no-op)
  lf_drain;
  inherited Destroy;
end;

procedure TMichaelScottQueue.Enqueue(const AItem: T);
var
  LNewNode: PNode;
  LTail, LNext: PNode;
  LExpected: Pointer;
begin
  New(LNewNode);
  LNewNode^.Data := AItem;
  LNewNode^.Next := nil;
  LNewNode^.HasData := True;
  repeat
    // HB-1: acquire read tail to see newest published tail value
    LTail := atomic_load_ptr(PPointer(@FTail)^, memory_order_acquire);
    // HB-2: acquire read next to observe enqueuer's release of new node link
    LNext := PNode(atomic_load_ptr(PPointer(@LTail^.Next)^, memory_order_acquire));
    // Re-read tail (acquire) and compare to avoid torn observation
    if LTail = atomic_load_ptr(PPointer(@FTail)^, memory_order_acquire) then
    begin
      if LNext = nil then
      begin
        LExpected := nil;
        if atomic_compare_exchange_strong_ptr(PPointer(@LTail^.Next)^, LExpected, Pointer(LNewNode), memory_order_acq_rel) then
        begin
          LExpected := LTail;
          atomic_compare_exchange_strong_ptr(PPointer(@FTail)^, LExpected, Pointer(LNewNode), memory_order_acq_rel);
          Break;
        end;
      end
      else
      begin
        LExpected := LTail;
        atomic_compare_exchange_strong_ptr(PPointer(@FTail)^, LExpected, Pointer(LNext), memory_order_acq_rel);
      end;
    end;
  until False;
end;

function TMichaelScottQueue.Dequeue(out AItem: T): Boolean;
var
  LHead, LTail, LNext: PNode;
  LExpected: Pointer;
  G: Pointer;
begin
  G := lf_enter;
  try
    repeat
      LHead := atomic_load_ptr(PPointer(@FHead)^, memory_order_acquire);
      LTail := atomic_load_ptr(PPointer(@FTail)^, memory_order_acquire);
      // Acquire read of next ensures we see the enqueuer's data published before linking
      LNext := PNode(atomic_load_ptr(PPointer(@LHead^.Next)^, memory_order_acquire));
      if LHead = FHead then
      begin
        if LHead = LTail then
        begin
          if LNext = nil then Exit(False);
          LExpected := LTail;
          // HB-3: acq_rel CAS on tail to help advance tail publishes new tail
          atomic_compare_exchange_strong_ptr(PPointer(@FTail)^, LExpected, Pointer(LNext), memory_order_acq_rel);
        end
        else
        begin
          if LNext <> nil then
          begin
            if LNext^.HasData then
              AItem := LNext^.Data;
            LExpected := LHead;
            // HB-4: acq_rel CAS moves head to next; publish new head and ensures prior reads of LNext^.Data are visible
            if atomic_compare_exchange_strong_ptr(PPointer(@FHead)^, LExpected, Pointer(LNext), memory_order_acq_rel) then
            begin
              // retire old head after unlink; immediate mode frees it directly
              lf_retire(LHead, @MSQ_DisposeNode);
              Exit(LNext^.HasData);
            end;
          end;
        end;
      end;
    until False;
  finally
    lf_exit(G);
  end;

{ IQueue<T> 显式实现 }

procedure TMichaelScottQueue.Push(const aElement: T);
begin
  Enqueue(aElement);
end;

procedure TMichaelScottQueue.Push(const aSrc: array of T);
var i: SizeInt;
begin
  for i := Low(aSrc) to High(aSrc) do Enqueue(aSrc[i]);
end;

procedure TMichaelScottQueue.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type PEl = ^T; var i: SizeUInt; p: PEl;
begin
  if (aSrc = nil) and (aElementCount > 0) then
    raise Exception.Create('IQueue.Push(pointer): aSrc is nil');
  p := PEl(aSrc);
  for i := 0 to aElementCount - 1 do begin Enqueue(p^); Inc(p); end;
end;

function TMichaelScottQueue.Pop(out aElement: T): Boolean;
begin
  Result := Dequeue(aElement);
end;

function TMichaelScottQueue.Pop: T;
begin
  if not Dequeue(Result) then
    raise Exception.Create('IQueue.Pop: queue is empty');
end;

function TMichaelScottQueue.TryPeek(out aElement: T): Boolean;
begin
  aElement := Default(T);
  Result := False;
end;

function TMichaelScottQueue.Peek: T;
begin
  raise Exception.Create('IQueue.Peek: not supported');
end;

procedure TMichaelScottQueue.Clear;
var v: T;
begin
  while Dequeue(v) do ;
end;

function TMichaelScottQueue.Count: SizeUInt;
begin
  Result := 0;
end;

end;

function TMichaelScottQueue.IsEmpty: Boolean;
begin
  Result := (FHead = FTail) and (FHead^.Next = nil);
end;

end.

