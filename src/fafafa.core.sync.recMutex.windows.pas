unit fafafa.core.sync.recMutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.recMutex.base;

type
  TRecMutex = class(TInterfacedObject, IRecMutex)
  private
    FCS: TRTLCriticalSection;
  public
    constructor Create; overload;
    constructor Create(ASpinCount: DWORD); overload;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
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
end;

destructor TRecMutex.Destroy;
begin
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

procedure TRecMutex.Acquire;
begin
  EnterCriticalSection(FCS);
end;

procedure TRecMutex.Release;
begin
  LeaveCriticalSection(FCS);
end;

function TRecMutex.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FCS);
end;

function TRecMutex.GetHandle: Pointer;
begin
  Result := @FCS;
end;

end.

