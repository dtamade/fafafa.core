unit fafafa.core.sync.condvar;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.condvar.base
  {$IFDEF WINDOWS}, fafafa.core.sync.condvar.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.condvar.unix{$ENDIF};

type
  TCondVarWaitResult = fafafa.core.sync.condvar.base.TCondVarWaitResult;
  ICondVar = fafafa.core.sync.condvar.base.ICondVar;

  {$IFDEF WINDOWS}
  TCondVar = fafafa.core.sync.condvar.windows.TCondVar;
  {$ENDIF}

  {$IFDEF UNIX}
  TCondVar = fafafa.core.sync.condvar.unix.TCondVar;
  {$ENDIF}

// 创建平台特定的条件变量实�?
function MakeCondVar: ICondVar;

implementation

function MakeCondVar: ICondVar;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.condvar.windows.TCondVar.Create;
  {$ENDIF}
  {$IFDEF UNIX}
  Result := fafafa.core.sync.condvar.unix.TCondVar.Create;
  {$ENDIF}
end;

end.

