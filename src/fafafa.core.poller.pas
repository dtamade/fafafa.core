unit fafafa.core.poller;
{
  Minimal event poller abstraction with a select-based default implementation.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
{$IFDEF WINDOWS}
  , WinSock2
{$ELSE}
  , BaseUnix, Sockets
{$ENDIF}
  ;

type
  TPollEvents = set of (evRead, evWrite, evError);

  IPollResult = interface
    ['{7C7E2E9B-7C1A-4A98-A7E8-6E45B7E1E4F9}']
    function FD: PtrUInt;
    function Events: TPollEvents;
  end;

  IEventPoller = interface
    ['{0D2E5A77-0E4C-4A67-9C6A-0C3E8B5B9F3F}']
    procedure Add(aFD: PtrUInt; aEvents: TPollEvents);
    procedure ModFD(aFD: PtrUInt; aEvents: TPollEvents);
    procedure Del(aFD: PtrUInt);
    function Poll(aTimeoutMs: Integer): TList; overload; // returns list of IPollResult
  end;

  { TSelectPoller }
  TSelectPoller = class(TInterfacedObject, IEventPoller)
  private
    type TReg = record FD: PtrUInt; Ev: TPollEvents; end;
    var FRegs: array of TReg;
  private
    function IndexOfFD(aFD: PtrUInt): Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(aFD: PtrUInt; aEvents: TPollEvents);
    procedure ModFD(aFD: PtrUInt; aEvents: TPollEvents);
    procedure Del(aFD: PtrUInt);
    function Poll(aTimeoutMs: Integer): TList; overload;
  end;

implementation

type
  TPollResultObj = class(TInterfacedObject, IPollResult)
  private
    FFD: PtrUInt;
    FEvents: TPollEvents;
  public
    constructor Create(aFD: PtrUInt; aEv: TPollEvents);
    function FD: PtrUInt;
    function Events: TPollEvents;
  end;

{ TPollResultObj }
constructor TPollResultObj.Create(aFD: PtrUInt; aEv: TPollEvents);
begin
  inherited Create;
  FFD := aFD; FEvents := aEv;
end;
function TPollResultObj.FD: PtrUInt; begin Result := FFD; end;
function TPollResultObj.Events: TPollEvents; begin Result := FEvents; end;

{ TSelectPoller }
constructor TSelectPoller.Create;
begin
  inherited Create;
  SetLength(FRegs, 0);
end;

destructor TSelectPoller.Destroy;
begin
  SetLength(FRegs, 0);
  inherited Destroy;
end;

function TSelectPoller.IndexOfFD(aFD: PtrUInt): Integer;
var i: Integer;
begin
  for i := 0 to High(FRegs) do if FRegs[i].FD = aFD then Exit(i);
  Result := -1;
end;

procedure TSelectPoller.Add(aFD: PtrUInt; aEvents: TPollEvents);
var i, n: Integer;
begin
  i := IndexOfFD(aFD);
  if i >= 0 then begin FRegs[i].Ev := aEvents; Exit; end;
  n := Length(FRegs); SetLength(FRegs, n+1); FRegs[n].FD := aFD; FRegs[n].Ev := aEvents;
end;

procedure TSelectPoller.ModFD(aFD: PtrUInt; aEvents: TPollEvents);
var i: Integer;
begin
  i := IndexOfFD(aFD);
  if i >= 0 then FRegs[i].Ev := aEvents;
end;

procedure TSelectPoller.Del(aFD: PtrUInt);
var i, n: Integer;
begin
  i := IndexOfFD(aFD);
  if i >= 0 then begin
    n := Length(FRegs);
    if i < n-1 then FRegs[i] := FRegs[n-1];
    SetLength(FRegs, n-1);
  end;
end;

function TSelectPoller.Poll(aTimeoutMs: Integer): TList;
var
  rf, wf, ef: fd_set;
  tv: timeval;
  i, ready: Integer;
{$IFNDEF WINDOWS}
  maxfd: cint;
{$ENDIF}
  ev: TPollEvents;
begin
  Result := TList.Create;

  // init fd_sets
  {$IFDEF WINDOWS}
  FD_ZERO(rf); FD_ZERO(wf); FD_ZERO(ef);
  {$ELSE}
  fpFD_ZERO(rf); fpFD_ZERO(wf); fpFD_ZERO(ef);
  {$ENDIF}

  // add interests
{$IFNDEF WINDOWS}
  maxfd := 0;
{$ENDIF}
  for i := 0 to High(FRegs) do begin
    if evRead in FRegs[i].Ev then begin
      {$IFDEF WINDOWS} FD_SET(FRegs[i].FD, rf); {$ELSE} fpFD_SET(FRegs[i].FD, rf); {$ENDIF}
    end;
    if evWrite in FRegs[i].Ev then begin
      {$IFDEF WINDOWS} FD_SET(FRegs[i].FD, wf); {$ELSE} fpFD_SET(FRegs[i].FD, wf); {$ENDIF}
    end;
    {$IFDEF WINDOWS} FD_SET(FRegs[i].FD, ef); {$ELSE} fpFD_SET(FRegs[i].FD, ef); {$ENDIF}
    {$IFNDEF WINDOWS}
    if cint(FRegs[i].FD) > maxfd then maxfd := cint(FRegs[i].FD);
    {$ENDIF}
  end;

  // timeout
  tv.tv_sec := aTimeoutMs div 1000;
  tv.tv_usec := (aTimeoutMs mod 1000) * 1000;

  // select
  {$IFDEF WINDOWS}
  ready := select(0, @rf, @wf, @ef, @tv);
  {$ELSE}
  ready := fpSelect(maxfd+1, @rf, @wf, @ef, @tv);
  {$ENDIF}
  if ready <= 0 then Exit; // timeout or error -> empty

  // collect results
  for i := 0 to High(FRegs) do begin
    ev := [];
    if ({$IFDEF WINDOWS}FD_ISSET{$ELSE}fpFD_ISSET{$ENDIF}(FRegs[i].FD, rf)) then Include(ev, evRead);
    if ({$IFDEF WINDOWS}FD_ISSET{$ELSE}fpFD_ISSET{$ENDIF}(FRegs[i].FD, wf)) then Include(ev, evWrite);
    if ({$IFDEF WINDOWS}FD_ISSET{$ELSE}fpFD_ISSET{$ENDIF}(FRegs[i].FD, ef)) then Include(ev, evError);
    if ev <> [] then Result.Add(TPollResultObj.Create(FRegs[i].FD, ev));
  end;
end;

end.
