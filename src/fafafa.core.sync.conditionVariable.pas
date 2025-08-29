unit fafafa.core.sync.conditionVariable;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.conditionVariable.base
  {$IFDEF WINDOWS}, fafafa.core.sync.conditionVariable.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.conditionVariable.unix{$ENDIF};

type
  IConditionVariable = fafafa.core.sync.conditionVariable.base.IConditionVariable;

  {$IFDEF WINDOWS}
  TConditionVariable = fafafa.core.sync.conditionVariable.windows.TConditionVariable;
  {$ENDIF}

  {$IFDEF UNIX}
  TConditionVariable = fafafa.core.sync.conditionVariable.unix.TConditionVariable;
  {$ENDIF}

// 创建平台特定的条件变量实例
function MakeConditionVariable: IConditionVariable;

implementation

function MakeConditionVariable: IConditionVariable;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.conditionVariable.unix.TConditionVariable.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.conditionVariable.windows.TConditionVariable.Create;
  {$ENDIF}
end;

end.

