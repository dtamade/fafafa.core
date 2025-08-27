program example_fs_watch;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes
  {$IFDEF WINDOWS}, Windows{$ENDIF},
  fafafa.core.fs.watch;

type
  TObserver = class(TInterfacedObject, IFsWatchObserver)
  public
    procedure OnEvent(const E: TFsWatchEvent);
    procedure OnError(const Code: Integer; const Message: string);
  end;

procedure TObserver.OnEvent(const E: TFsWatchEvent);
begin
  WriteLn(Format('[%d] %s %s%s', [E.Timestamp, GetEnumName(TypeInfo(TFsWatchEventKind), Ord(E.Kind)), E.Path,
    IfThen(E.OldPath<>'', ' (from '+E.OldPath+')', '')]));
end;

procedure TObserver.OnError(const Code: Integer; const Message: string);
begin
  WriteLn(Format('ERROR(%d): %s', [Code, Message]));
end;

function ParamOrDefault(I: Integer; const Def: string): string;
begin
  if ParamCount >= I then Result := ParamStr(I) else Result := Def;
end;

var
  Root: string;
  Opts: TFsWatchOptions;
  W: IFsWatcher;
  Obs: IFsWatchObserver;
begin
  Root := ParamOrDefault(1, GetCurrentDir);
  WriteLn('Watch root: ', Root);
  Opts := DefaultFsWatchOptions;
  if ParamStr(2) = 'nonrec' then Opts.Recursive := False;
  W := CreateFsWatcher;
  Obs := TObserver.Create;
  if Assigned(W) then
  begin
    if W.Start(Root, Opts, Obs) = 0 then
    begin
      WriteLn('Watching... Press Ctrl+C to stop.');
      {$IFDEF WINDOWS}
      while True do Sleep(1000);
      {$ELSE}
      ReadLn;
      {$ENDIF}
      W.Stop;
    end
    else
      WriteLn('Watcher start failed (not implemented or unsupported).');
  end
  else
    WriteLn('Watcher factory returned nil.');
end.

