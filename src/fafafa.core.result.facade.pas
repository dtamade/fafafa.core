unit fafafa.core.result.facade;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.result;

{ 该单元提供 Result 的“门面/前奏”API：
  - 提供更短的函数名（Ok/Err/Ensure/Zip/Context...）
  - 内部全部转调 fafafa.core.result 的实现

  说明：此单元不重定义 TResult/TErrorCtx 等类型；类型仍由 fafafa.core.result 提供。
}

// TryCollect

generic function TryCollect<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  var OutValues: specialize TValueArray<T>; out FirstErr: E): Boolean;

implementation

generic function TryCollect<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  var OutValues: specialize TValueArray<T>; out FirstErr: E): Boolean;
begin
  Result := specialize TryCollectPtrIntoArray<T, E>(ItemsPtr, Count, OutValues, FirstErr);
end;

end.
