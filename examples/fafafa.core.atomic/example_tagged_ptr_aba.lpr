program example_tagged_ptr_aba;

{$APPTYPE CONSOLE}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.atomic;

type
  PNode = ^TNode;
  TNode = record
    data: Int32;
    next: PNode;
  end;

  // 无锁栈（演示 ABA 问题及解决方案）
  TLockFreeStack = class
  private
    head: atomic_tagged_ptr_t;  // 使用 tagged pointer 解决 ABA 问题
  public
    constructor Create;
    procedure Push(data: Int32);
    function Pop(out data: Int32): Boolean;
    function IsEmpty: Boolean;
  end;

constructor TLockFreeStack.Create;
begin
  inherited Create;
  // 初始化为空栈
  atomic_tagged_ptr_store(head, atomic_tagged_ptr(nil, 0));
end;

procedure TLockFreeStack.Push(data: Int32);
var
  new_node: PNode;
  old_head, new_head: atomic_tagged_ptr_t;
begin
  // 分配新节点
  New(new_node);
  new_node^.data := data;
  
  repeat
    // 读取当前头节点
    old_head := atomic_tagged_ptr_load(head);

    // 设置新节点的 next 指针
    new_node^.next := atomic_tagged_ptr_get_ptr(old_head);

    // 创建新的头节点（指针 + 递增的标签）
    new_head := atomic_tagged_ptr(new_node, atomic_tagged_ptr_next(old_head));

    // 尝试 CAS 更新头节点
  until atomic_tagged_ptr_compare_exchange_weak(head, old_head, new_head);
  
  Writeln('Push: ', data, ' (tag: ', atomic_tagged_ptr_get_tag(new_head), ')');
end;

function TLockFreeStack.Pop(out data: Int32): Boolean;
var
  old_head, new_head: atomic_tagged_ptr_t;
  head_ptr, next_ptr: PNode;
begin
  repeat
    // 读取当前头节点
    old_head := atomic_tagged_ptr_load(head);
    head_ptr := atomic_tagged_ptr_get_ptr(old_head);

    // 检查栈是否为空
    if head_ptr = nil then
    begin
      Result := False;
      Exit;
    end;

    // 读取下一个节点
    next_ptr := head_ptr^.next;

    // 创建新的头节点（next 指针 + 递增的标签）
    new_head := atomic_tagged_ptr(next_ptr, atomic_tagged_ptr_next(old_head));

    // 尝试 CAS 更新头节点
    // 即使在此期间 head_ptr 被其他线程释放并重新分配到相同地址，
    // 标签的不同也会让 CAS 失败，避免 ABA 问题
  until atomic_tagged_ptr_compare_exchange_weak(head, old_head, new_head);
  
  // 成功更新，提取数据并释放节点
  data := head_ptr^.data;
  Dispose(head_ptr);
  Result := True;
  
  Writeln('Pop: ', data, ' (tag: ', atomic_tagged_ptr_get_tag(new_head), ')');
end;

function TLockFreeStack.IsEmpty: Boolean;
var
  current_head: atomic_tagged_ptr_t;
begin
  current_head := atomic_tagged_ptr_load(head);
  Result := atomic_tagged_ptr_get_ptr(current_head) = nil;
end;

type
  TWorkerThread = class(TThread)
  private
    FStack: TLockFreeStack;
    FWorkerThreadId: Integer;
    FOperations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(stack: TLockFreeStack; thread_id: Integer; operations: Integer);
  end;

constructor TWorkerThread.Create(stack: TLockFreeStack; thread_id: Integer; operations: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FStack := stack;
  FWorkerThreadId := thread_id;
  FOperations := operations;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  data: Int32;
  success: Boolean;
begin
  for i := 1 to FOperations do
  begin
    // 交替进行 push 和 pop 操作
    if (i mod 2) = 1 then
    begin
      // Push 操作
      data := FWorkerThreadId * 1000 + i;
      FStack.Push(data);
    end
    else
    begin
      // Pop 操作
      success := FStack.Pop(data);
      if not success then
        Writeln('线程 ', FWorkerThreadId, ': Pop 失败（栈为空）');
    end;
    
    // 模拟一些工作
    if (i mod 10) = 0 then
      Sleep(1);
  end;
  
  Writeln('线程 ', FWorkerThreadId, ' 完成 ', FOperations, ' 个操作');
end;

var
  stack: TLockFreeStack;
  threads: array[1..4] of TWorkerThread;
  i: Integer;
  final_data: Int32;

begin
  Writeln('=== Tagged Pointer ABA 问题解决示例 ===');
  Writeln('演示无锁栈的并发操作，使用 tagged pointer 避免 ABA 问题');
  Writeln;

  // 创建无锁栈
  stack := TLockFreeStack.Create;
  try
    // 初始化栈（放入一些数据）
    Writeln('初始化栈：');
    for i := 1 to 5 do
      stack.Push(i * 10);
    Writeln;

    // 创建多个工作线程
    Writeln('启动 4 个工作线程进行并发操作：');
    for i := 1 to 4 do
      threads[i] := TWorkerThread.Create(stack, i, 10);

    // 等待所有线程完成
    for i := 1 to 4 do
      threads[i].WaitFor;

    // 清理线程
    for i := 1 to 4 do
      threads[i].Free;

    Writeln;
    Writeln('=== 最终状态 ===');
    
    // 输出栈中剩余的元素
    i := 0;
    while stack.Pop(final_data) do
    begin
      Inc(i);
      Writeln('剩余元素 ', i, ': ', final_data);
    end;
    
    if i = 0 then
      Writeln('栈为空');
      
    Writeln;
    Writeln('=== ABA 问题说明 ===');
    Writeln('ABA 问题：线程 A 读取值 A，线程 B 将 A 改为 B 再改回 A，');
    Writeln('线程 A 的 CAS 操作会成功，但实际上值已经被修改过。');
    Writeln;
    Writeln('解决方案：使用 tagged pointer，每次修改时递增标签，');
    Writeln('即使指针值相同，标签不同也会让 CAS 失败。');

  finally
    stack.Free;
  end;

  Writeln;
  Writeln('=== 示例完成 ===');
end.
