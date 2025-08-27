unit fafafa.core.sync.spinMutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.spinMutex.base,
  fafafa.core.sync.spin // 直接复用现有平台实现与工厂
  ;

// 门面工厂：与新规范一致使用 Make 前缀
function MakeSpinMutex: ISpinMutex;

implementation

function MakeSpinMutex: ISpinMutex;
begin
  // 直接复用现有自旋锁的工厂
  Result := ISpinMutex(fafafa.core.sync.spin.MakeSpinLock);
end;

end.

