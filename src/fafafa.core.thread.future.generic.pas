unit fafafa.core.thread.future.generic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.thread.future;

// 原型实现：基于现有非泛型 TFuture，提供携带结果值的 generic TFutureT<T>
// 设计要点：
// - 不改动现有 IFuture 与 TFuture 的行为
// - 通过 CompleteWith(AValue) 设置结果，并触发完成
// - Result(Timeout) 在完成后返回值；取消时抛 EFutureCancelledError；超时时抛 EInvalidOperation（后续可引入 ETimeout）
// - TryGetResult 提供非阻塞获取

type
  generic TFutureT<T> = class(TFuture)
  private
    FHasValue: Boolean;
    FValue: T;
  public
    // 将 Future 标记为成功完成并携带结果值
    procedure CompleteWith(const AValue: T);

    // 非阻塞获取结果。完成且未取消/失败时返回 True 并填充 AOut
    function TryGetResult(out AOut: T): Boolean;

    // 阻塞获取结果；可设置超时（毫秒）。
    // - 完成且成功：返回值
    // - 已取消：抛 EFutureCancelledError
    // - 超时未完成：抛 EInvalidOperation（未来可改为 ETimeout）
    function GetResult(ATimeoutMs: Cardinal = INFINITE): T;
  end;

implementation

{ TFutureT<T> }

procedure TFutureT.CompleteWith(const AValue: T);
begin
  // 先写入值，再调用继承的 Complete（持锁变更状态并通知），避免访问继承类的私有成员
  FValue := AValue;
  FHasValue := True;
  inherited Complete;
end;

function TFutureT.TryGetResult(out AOut: T): Boolean;
begin
  Result := IsDone and (not IsCancelled) and FHasValue;
  if Result then
    AOut := FValue;
end;

function TFutureT.GetResult(ATimeoutMs: Cardinal): T;
var
  LOk: Boolean;
begin
  // 已完成则直接返回/抛出
  if not IsDone then
  begin
    LOk := WaitFor(ATimeoutMs);
    if not LOk then
      raise EInvalidOperation.Create('Future timeout');
  end;

  if IsCancelled then
    raise EFutureCancelledError.Create('Future is cancelled');

  if not FHasValue then
    raise EInvalidOperation.Create('Future completed without value');

  Result := FValue;
end;

end.

