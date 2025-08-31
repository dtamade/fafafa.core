{$MACRO ON}
{$IFDEF CPUX86_64}
  // x86_64: aligned 32/64-bit reads/writes are atomic; use direct ops for fast path
  {$define atomic_load(x):=(x)}
  {$define atomic_store(x,y):=(x:=y)}
  {$define atomic_exchange(x,y):=InterlockedExchange(x,y)}
  {$define atomic_fetch_add(x,y):=InterlockedExchangeAdd(x,y)}
{$ELSEIF DEFINED(CPUX86)}
  // x86: aligned 32-bit reads/writes are atomic; use direct ops for fast path
  {$define atomic_load(x):=(x)}
  {$define atomic_store(x,y):=(x:=y)}
  {$define atomic_exchange(x,y):=InterlockedExchange(x,y)}
  {$define atomic_fetch_add(x,y):=InterlockedExchangeAdd(x,y)}
{$ENDIF}

