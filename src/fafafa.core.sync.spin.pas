unit fafafa.core.sync.spin;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.spin.base;

type
  // 导出主要类型
  ISpin = fafafa.core.sync.spin.base.ISpin;
  ISpinLock = ISpin;  // 兼容性别名

// 统一工厂函数
function MakeSpin: ISpin;

// 兼容性函数
function MakeSpinLock: ISpinLock; inline;

implementation

uses
  {$IFDEF WINDOWS}
  fafafa.core.sync.spin.windows
  {$ELSE}
  fafafa.core.sync.spin.unix
  {$ENDIF};

function MakeSpin: ISpin;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.spin.windows.MakeSpin;
  {$ELSE}
  Result := fafafa.core.sync.spin.unix.MakeSpin;
  {$ENDIF}
end;

function MakeSpinLock: ISpinLock;
begin
  Result := MakeSpin;
end;
end.
