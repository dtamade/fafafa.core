unit fafafa.core.sync.recMutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.recMutex.base;

type
  TRecMutex = class(TInterfacedObject, IRecMutex)
  private
    FCS: TRTLCriticalSection;
    FLastError: TWaitError;
  public
    constructor Create; overload;
    constructor Create(ASpinCount: DWORD); overload;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;
    function GetHandle: Pointer;
  end;

implementation

constructor TRecMutex.Create;
begin
  Create(4000);
end;

constructor TRecMutex.Create(ASpinCount: DWORD);
begin
  inherited Create;
  if not InitializeCriticalSectionAndSpinCount(FCS, ASpinCount) then
  begin
    InitializeCriticalSection(FCS);
  end;
  FLastError := weNone;
end;

destructor TRecMutex.Destroy;
begin
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

procedure TRecMutex.Acquire;
begin
  EnterCriticalSection(FCS);
  FLastError := weNone;
end;

procedure TRecMutex.Release;
begin
  LeaveCriticalSection(FCS);
  FLastError := weNone;
end;

function TRecMutex.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FCS);
  if Result then FLastError := weNone;
end;

function TRecMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var start: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  start := GetTickCount64;
  while GetTickCount64 - start < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
end;

function TRecMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TRecMutex.GetHandle: Pointer;
begin
  Result := @FCS;
end;

end.

