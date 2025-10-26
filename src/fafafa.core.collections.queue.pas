unit fafafa.core.collections.queue;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.math,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;  // TVecDeque 实现了 IQueue

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

  { TArrayQueue 数组队列实现 - 基于环形缓冲区的高性能 FIFO 队列 }
  generic TArrayQueue<T> = class(specialize IQueue<T>)
  type
    TInternalQueue = specialize TVecDeque<T>;
  private
    FQueue: TInternalQueue;
    FAllocator: IAllocator;

  public
    constructor Create(const aAllocator: IAllocator = nil); overload;
    constructor Create(const aElements: array of T; const aAllocator: IAllocator = nil); overload;
    destructor Destroy; override;

    { IQueue 接口实现 }
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;

    function Pop(out aElement: T): Boolean; overload;
    function Pop: T; overload;

    function TryPeek(out aElement: T): Boolean; overload;
    function Peek: T; overload;

    function IsEmpty: Boolean;
    procedure Clear;
    function Count: SizeUInt;
  end;

  { 泛型队列工厂函数 }
  generic function MakeQueue<T>(const aAllocator: IAllocator = nil): specialize IQueue<T>;
  generic function MakeQueue<T>(const aElements: array of T; const aAllocator: IAllocator = nil): specialize IQueue<T>;

implementation

{ TArrayQueue<T> }

constructor TArrayQueue.Create(const aAllocator: IAllocator = nil);
begin
  inherited Create;
  if aAllocator <> nil then
    FAllocator := aAllocator
  else
    FAllocator := GetRtlAllocator;
  FQueue := TInternalQueue.Create(FAllocator);
end;

constructor TArrayQueue.Create(const aElements: array of T; const aAllocator: IAllocator = nil);
begin
  inherited Create;
  if aAllocator <> nil then
    FAllocator := aAllocator
  else
    FAllocator := GetRtlAllocator;
  FQueue := TInternalQueue.Create(FAllocator);
  FQueue.Push(aElements);
end;

destructor TArrayQueue.Destroy;
begin
  FQueue.Free;
  inherited Destroy;
end;

procedure TArrayQueue.Push(const aElement: T);
begin
  FQueue.PushBack(aElement);
end;

procedure TArrayQueue.Push(const aSrc: array of T);
var
  I: SizeUInt;
begin
  for I := 0 to High(aSrc) do
    FQueue.PushBack(aSrc[I]);
end;

procedure TArrayQueue.Push(const aSrc: Pointer; aElementCount: SizeUInt);
var
  I: SizeUInt;
  LElement: T;
begin
  for I := 0 to aElementCount - 1 do
  begin
    LElement := PElement(aSrc)[I];
    FQueue.PushBack(LElement);
  end;
end;

function TArrayQueue.Pop(out aElement: T): Boolean;
begin
  if FQueue.IsEmpty then
    Exit(False);
  aElement := FQueue.PopFront;
  Result := True;
end;

function TArrayQueue.Pop: T;
begin
  if FQueue.IsEmpty then
    raise EArgumentOutOfRangeException.Create('Queue is empty');
  Result := FQueue.PopFront;
end;

function TArrayQueue.TryPeek(out aElement: T): Boolean;
begin
  if FQueue.IsEmpty then
    Exit(False);
  aElement := FQueue.Front;
  Result := True;
end;

function TArrayQueue.Peek: T;
begin
  if FQueue.IsEmpty then
    raise EArgumentOutOfRangeException.Create('Queue is empty');
  Result := FQueue.Front;
end;

function TArrayQueue.IsEmpty: Boolean;
begin
  Result := FQueue.IsEmpty;
end;

procedure TArrayQueue.Clear;
begin
  FQueue.Clear;
end;

function TArrayQueue.Count: SizeUInt;
begin
  Result := FQueue.Count;
end;

{ 泛型工厂函数实现 }

generic function MakeQueue<T>(const aAllocator: IAllocator = nil): specialize IQueue<T>;
var
  LQueue: TArrayQueue;
begin
  LQueue := TArrayQueue.Create(aAllocator);
  Result := LQueue;  // 接口引用
end;

generic function MakeQueue<T>(const aElements: array of T; const aAllocator: IAllocator = nil): specialize IQueue<T>;
var
  LQueue: TArrayQueue;
begin
  LQueue := TArrayQueue.Create(aElements, aAllocator);
  Result := LQueue;  // 接口引用
end;

end.