unit fafafa.core.mem.pool.arena;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.allocator.rtlAllocator,
  fafafa.core.mem.pool;

type
  IArenaPool = interface(IPool)
    ['{08B64862-2FCD-4AA1-8787-21A9F38E8F5B}']
    function BlockSize: SizeUInt; // 固定大小分配
    function Mark: SizeUInt;
    procedure ReleaseMark(AMark: SizeUInt);
  end;

implementation

end.
