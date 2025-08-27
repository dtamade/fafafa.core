unit fafafa.core.sync.spinMutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base; // 复用已有自旋锁接口与实现

// 说明：
// ISpinMutex 等价于现有的 ISpinLock（均继承自 ILock），为命名与模块结构一致而提供的别名接口。
// 后续如需与 SpinLock 行为分化，可在此单元调整而不影响调用方。

type
  ISpinMutex = fafafa.core.sync.spin.base.ISpinLock;

implementation

end.

