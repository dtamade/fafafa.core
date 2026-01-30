unit fafafa.core.result.collect;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.result,
  fafafa.core.collections.vec;

{ ResultCollectPtrIntoVec / ResultSequencePtrIntoVec

  目标：提供一个在 FPC 3.3.1 下稳定的 “sequence/collect” 能力。

  设计要点：
  - 避免在泛型签名里出现 `array of specialize TResult<...>`（会触发 FPC 限制/链接问题）
  - 输入采用 (ptr, count) 形式：调用方可用 `@Items[0]` + `Length(Items)` 传入
  - 输出采用 IVec<T>（由调用方创建/持有），本函数仅负责填充

  语义：
  - 先 Clear(OutVec)
  - 遇到首个 Err：Clear(OutVec) 并返回 Err(E)
  - 全部 Ok：按顺序 Push Ok 值，并返回 Ok(Unit)
}

generic function ResultCollectPtrIntoVec<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  const OutVec: specialize IVec<T>): specialize TResult<TUnit, E>; inline;

generic function ResultSequencePtrIntoVec<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  const OutVec: specialize IVec<T>): specialize TResult<TUnit, E>; inline;

implementation

generic function ResultCollectPtrIntoVec<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  const OutVec: specialize IVec<T>): specialize TResult<TUnit, E>;
type
  PResult = ^specialize TResult<T, E>;
var
  I: SizeUInt;
  P: PResult;
begin
  if OutVec = nil then
    raise EArgumentNil.Create('OutVec is nil');

  OutVec.Clear;

  if Count = 0 then
    Exit(specialize TResult<TUnit, E>.Ok(Default(TUnit)));

  if ItemsPtr = nil then
    raise EArgumentNil.Create('ItemsPtr is nil');

  OutVec.EnsureCapacity(Count);

  P := PResult(ItemsPtr);
  I := 0;
  while I < Count do
  begin
    if P^.IsErr then
    begin
      OutVec.Clear;
      Exit(specialize TResult<TUnit, E>.Err(P^.GetErrUnchecked));
    end;

    OutVec.Push(P^.GetOkUnchecked);
    Inc(P);
    Inc(I);
  end;

  Result := specialize TResult<TUnit, E>.Ok(Default(TUnit));
end;

generic function ResultSequencePtrIntoVec<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  const OutVec: specialize IVec<T>): specialize TResult<TUnit, E>;
begin
  Result := specialize ResultCollectPtrIntoVec<T, E>(ItemsPtr, Count, OutVec);
end;

end.
