unit fafafa.core.thread.cancel;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.sync;

type
  ICancellationToken = interface
    ['{0D0A6B2E-6E1D-4F5C-AF2E-DF8F8F1B9E1A}']
    function IsCancellationRequested: Boolean;
  end;

  ICancellationTokenSource = interface
    ['{8A0B0F2C-2E5D-4A7B-9AF0-2D9B79B6E2F2}']
    function Token: ICancellationToken;
    procedure Cancel;
  end;

function CreateCancellationTokenSource: ICancellationTokenSource;

implementation

type
  TCancellationToken = class(TInterfacedObject, ICancellationToken)
  private
    FCancelled: Boolean;
    FEvent: IEvent;
    FLock: ILock;
  public
    constructor Create;
    function IsCancellationRequested: Boolean;
    procedure CancelInternal; inline;
  end;

  TCancellationTokenSource = class(TInterfacedObject, ICancellationTokenSource)
  private
    FToken: TCancellationToken;
  public
    constructor Create;
    destructor Destroy; override;
    function Token: ICancellationToken;
    procedure Cancel;
  end;

function CreateCancellationTokenSource: ICancellationTokenSource;
begin
  Result := TCancellationTokenSource.Create;
end;

{ TCancellationToken }

constructor TCancellationToken.Create;
begin
  inherited Create;
  FCancelled := False;
  FEvent := TEvent.Create(True, False);
  FLock := TMutex.Create;
end;

function TCancellationToken.IsCancellationRequested: Boolean;
begin
  FLock.Acquire;
  try
    Result := FCancelled;
  finally
    FLock.Release;
  end;
end;

procedure TCancellationToken.CancelInternal;
begin
  FLock.Acquire;
  try
    if not FCancelled then
    begin
      FCancelled := True;
      FEvent.SetEvent;
    end;
  finally
    FLock.Release;
  end;
end;

{ TCancellationTokenSource }

constructor TCancellationTokenSource.Create;
begin
  inherited Create;
  FToken := TCancellationToken.Create;
end;

destructor TCancellationTokenSource.Destroy;
begin
  FToken := nil;
  inherited Destroy;
end;

function TCancellationTokenSource.Token: ICancellationToken;
begin
  Result := FToken;
end;

procedure TCancellationTokenSource.Cancel;
begin
  if Assigned(FToken) then
    FToken.CancelInternal;
end;

end.

