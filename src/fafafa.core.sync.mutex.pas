unit fafafa.core.sync.mutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.mutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.mutex.unix{$ENDIF};

type

  IMutex = fafafa.core.sync.mutex.base.IMutex;

  {$IFDEF WINDOWS}
  TMutex = fafafa.core.sync.mutex.windows.TMutex;
  {$ENDIF}

  {$IFDEF UNIX}
  TMutex = fafafa.core.sync.mutex.unix.TMutex;
  {$ENDIF}

// 创建平台特定的互斥锁实例
function MakeMutex: IMutex; overload;



implementation

function MakeMutex: IMutex;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.mutex.unix.TMutex.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.mutex.windows.TMutex.Create;
  {$ENDIF}
end;

{$IFDEF WINDOWS}
function MakeMutex(ASpinCount: DWORD): IMutex;
begin
  Result := fafafa.core.sync.mutex.windows.TMutex.Create(ASpinCount);
end;
{$ENDIF}

end.

