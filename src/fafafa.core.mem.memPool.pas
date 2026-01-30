{
  fafafa.core.mem.memPool - Fixed-size Memory Pool (Facade Alias)

  This unit provides TMemPool as an alias for TFixedPool for facade compatibility.
  For new code, prefer using fafafa.core.mem.pool.fixed directly.
}
unit fafafa.core.mem.memPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.mem.pool.fixed;

type
  // 门面兼容别名 - 新代码建议直接使用 TFixedPool
  TMemPool = TFixedPool;
  TMemPoolConfig = TFixedPoolConfig;

  // 异常类型别名
  EMemPoolError = EMemFixedPoolError;
  EMemPoolInvalidPointer = EMemFixedPoolInvalidPointer;
  EMemPoolDoubleFree = EMemFixedPoolDoubleFree;

implementation

end.
