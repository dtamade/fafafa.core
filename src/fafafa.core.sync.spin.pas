unit fafafa.core.sync.spin;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base
  {$IFDEF WINDOWS}, fafafa.core.sync.spin.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.spin.unix{$ENDIF};

type

  ISpinLock = fafafa.core.sync.spin.base.ISpinLock;

  {$IFDEF WINDOWS}
  TSpinLock = fafafa.core.sync.spin.windows.TSpinLock;
  {$ENDIF}

  {$IFDEF UNIX}
  TSpinLock = fafafa.core.sync.spin.unix.TSpinLock;
  {$ENDIF}

// 创建平台特定的自旋锁实例
function MakeSpinLock: ISpinLock;

implementation

function MakeSpinLock: ISpinLock;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.spin.unix.TSpinLock.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.spin.windows.TSpinLock.Create;
  {$ENDIF}
end;

end.