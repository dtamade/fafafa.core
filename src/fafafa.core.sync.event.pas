unit fafafa.core.sync.event;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.event.base
  {$IFDEF WINDOWS}, fafafa.core.sync.event.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.event.unix{$ENDIF};

type
  IEvent = fafafa.core.sync.event.base.IEvent;

  {$IFDEF WINDOWS}
  TEvent = fafafa.core.sync.event.windows.TEvent;
  {$ENDIF}

  {$IFDEF UNIX}
  TEvent = fafafa.core.sync.event.unix.TEvent;
  {$ENDIF}

// 创建平台特定的事件对象
function MakeEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent;

// 兼容性别名
function CreateEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent;

implementation

function MakeEvent(AManualReset: Boolean; AInitialState: Boolean): IEvent;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.event.unix.TEvent.Create(AManualReset, AInitialState);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.event.windows.TEvent.Create(AManualReset, AInitialState);
  {$ENDIF}
end;

function CreateEvent(AManualReset: Boolean; AInitialState: Boolean): IEvent;
begin
  Result := MakeEvent(AManualReset, AInitialState);
end;

end.

