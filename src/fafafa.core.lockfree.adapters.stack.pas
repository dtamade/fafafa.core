unit fafafa.core.lockfree.adapters.stack;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  // collections interfaces
  fafafa.core.collections.stack,
  // lock-free implementations
  fafafa.core.lockfree.stack;

{ 封装 lockfree 栈为 collections 的 IStack<T> 接口 }

type
  generic TTreiberStackAsIStack<T> = class(TInterfacedObject, specialize IStack<T>)
  private
    FImpl: specialize TTreiberStack<T>;
  public
    constructor Create; reintroduce; overload;
    destructor Destroy; override;
    // Push 重载
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    // Pop 重载
    function  Pop(out aElement: T): Boolean; overload;
    function  Pop: T; overload;
    // Peek
    function  TryPeek(out aElement: T): Boolean; overload;
    function  Peek: T; overload;
    // 状态
    function  IsEmpty: Boolean;
    procedure Clear;
    function  Count: SizeUInt;
  end;

  generic TPreAllocStackAsIStack<T> = class(TInterfacedObject, specialize IStack<T>)
  private
    FImpl: specialize TPreAllocStack<T>;
  public
    constructor Create(ACapacity: Integer = 1024); reintroduce; overload;
    destructor Destroy; override;
    // Push 重载
    procedure Push(const aElement: T); overload;
    procedure Push(const aSrc: array of T); overload;
    procedure Push(const aSrc: Pointer; aElementCount: SizeUInt); overload;
    // Pop 重载
    function  Pop(out aElement: T): Boolean; overload;
    function  Pop: T; overload;
    // Peek
    function  TryPeek(out aElement: T): Boolean; overload;
    function  Peek: T; overload;
    // 状态
    function  IsEmpty: Boolean;
    procedure Clear;
    function  Count: SizeUInt;
  end;

// 工厂函数（便于快速创建 IStack 接口）

generic function MakeTreiberIStack<T>: specialize IStack<T>;

generic function MakePreAllocIStack<T>(ACapacity: Integer = 1024): specialize IStack<T>;

implementation

{ TTreiberStackAsIStack<T> }

constructor TTreiberStackAsIStack.Create;
begin
  inherited Create;
  FImpl := specialize TTreiberStack<T>.Create;
end;

destructor TTreiberStackAsIStack.Destroy;
begin
  FreeAndNil(FImpl);
  inherited Destroy;
end;

procedure TTreiberStackAsIStack.Push(const aElement: T);
begin
  FImpl.Push(aElement);
end;

procedure TTreiberStackAsIStack.Push(const aSrc: array of T);
var
  i: SizeInt;
begin
  for i := Low(aSrc) to High(aSrc) do
    FImpl.Push(aSrc[i]);
end;

procedure TTreiberStackAsIStack.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type
  PEl = ^T;
var
  i: SizeUInt;
  p: PEl;
begin
  if (aSrc = nil) and (aElementCount > 0) then
    raise Exception.Create('IStack.Push(pointer): aSrc is nil');
  p := PEl(aSrc);
  for i := 0 to aElementCount - 1 do
  begin
    FImpl.Push(p^);
    Inc(p);
  end;
end;

function TTreiberStackAsIStack.Pop(out aElement: T): Boolean;
begin
  Result := FImpl.Pop(aElement);
end;

function TTreiberStackAsIStack.Pop: T;
begin
  if not FImpl.Pop(Result) then
    raise Exception.Create('IStack.Pop: stack is empty');
end;

function TTreiberStackAsIStack.TryPeek(out aElement: T): Boolean;
begin
  Result := FImpl.TryPeek(aElement);
end;

function TTreiberStackAsIStack.Peek: T;
begin
  if not TryPeek(Result) then
    raise Exception.Create('IStack.Peek: stack is empty');
end;

function TTreiberStackAsIStack.IsEmpty: Boolean;
begin
  Result := FImpl.IsEmpty;
end;

procedure TTreiberStackAsIStack.Clear;
var
  dummy: T;
begin
  while FImpl.Pop(dummy) do ;
end;

function TTreiberStackAsIStack.Count: SizeUInt;
begin
  // TTreiberStack.GetSize 为估算值（非原子快照）；满足 IStack:Count 的“最佳努力”含义
  Result := SizeUInt(FImpl.GetSize);
end;

{ TPreAllocStackAsIStack<T> }

constructor TPreAllocStackAsIStack.Create(ACapacity: Integer);
begin
  inherited Create;
  FImpl := specialize TPreAllocStack<T>.Create(ACapacity);
end;

destructor TPreAllocStackAsIStack.Destroy;
begin
  FreeAndNil(FImpl);
  inherited Destroy;
end;

procedure TPreAllocStackAsIStack.Push(const aElement: T);
begin
  // 预分配栈满时 Push 返回 False；IStack 的 Push 无返回，采用抛异常策略
  if not FImpl.Push(aElement) then
    raise Exception.Create('IStack.Push: pre-alloc stack is full');
end;

procedure TPreAllocStackAsIStack.Push(const aSrc: array of T);
var
  i: SizeInt;
begin
  for i := Low(aSrc) to High(aSrc) do
    Push(aSrc[i]);
end;

procedure TPreAllocStackAsIStack.Push(const aSrc: Pointer; aElementCount: SizeUInt);
type
  PEl = ^T;
var
  i: SizeUInt;
  p: PEl;
begin
  if (aSrc = nil) and (aElementCount > 0) then
    raise Exception.Create('IStack.Push(pointer): aSrc is nil');
  p := PEl(aSrc);
  for i := 0 to aElementCount - 1 do
  begin
    Push(p^);
    Inc(p);
  end;
end;

function TPreAllocStackAsIStack.Pop(out aElement: T): Boolean;
begin
  Result := FImpl.Pop(aElement);
end;

function TPreAllocStackAsIStack.Pop: T;
begin
  if not FImpl.Pop(Result) then
    raise Exception.Create('IStack.Pop: stack is empty');
end;

function TPreAllocStackAsIStack.TryPeek(out aElement: T): Boolean;
begin
  // 预分配栈暂不支持无锁 Peek；返回 False 即可
  aElement := Default(T);
  Result := False;
end;

function TPreAllocStackAsIStack.Peek: T;
begin
  if not TryPeek(Result) then
    raise Exception.Create('IStack.Peek: not supported or stack is empty');
end;

function TPreAllocStackAsIStack.IsEmpty: Boolean;
begin
  Result := FImpl.IsEmpty;
end;

procedure TPreAllocStackAsIStack.Clear;
var
  dummy: T;
begin
  while FImpl.Pop(dummy) do ;
end;

function TPreAllocStackAsIStack.Count: SizeUInt;
begin
  Result := SizeUInt(FImpl.GetSize);
end;

{ Factories }

generic function MakeTreiberIStack<T>: specialize IStack<T>;
begin
  Result := specialize TTreiberStackAsIStack<T>.Create;
end;

generic function MakePreAllocIStack<T>(ACapacity: Integer): specialize IStack<T>;
begin
  Result := specialize TPreAllocStackAsIStack<T>.Create(ACapacity);
end;

end.

