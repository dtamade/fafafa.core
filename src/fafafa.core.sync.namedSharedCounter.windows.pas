unit fafafa.core.sync.namedSharedCounter.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Windows,
  fafafa.core.sync.base, fafafa.core.sync.namedSharedCounter.base;

type
  TNamedSharedCounter = class(TSynchronizable, INamedSharedCounter)
  private
    FMapping: THandle;
    FShared: PInt64;
    FOriginalName: string;
    FIsCreator: Boolean;
    FConfig: TNamedSharedCounterConfig;
    FLastError: TWaitError;

    function CreateMapName(const AName: string): string;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedSharedCounterConfig); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // INamedSharedCounter
    function Increment: Int64;
    function Decrement: Int64;
    function Add(AValue: Int64): Int64;
    function Sub(AValue: Int64): Int64;
    function CompareExchange(AExpected, ANew: Int64): Int64;
    function Exchange(ANew: Int64): Int64;
    function GetValue: Int64;
    procedure SetValue(AValue: Int64);
    function GetName: string;
  end;

function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
function MakeNamedSharedCounter(const AName: string;
  const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;

implementation

const
  PREFIX_MAP = 'Global\fafafa_cnt_';

function MakeNamedSharedCounter(const AName: string): INamedSharedCounter;
begin
  Result := TNamedSharedCounter.Create(AName);
end;

function MakeNamedSharedCounter(const AName: string;
  const AConfig: TNamedSharedCounterConfig): INamedSharedCounter;
begin
  Result := TNamedSharedCounter.Create(AName, AConfig);
end;

{ TNamedSharedCounter }

constructor TNamedSharedCounter.Create(const AName: string);
begin
  Create(AName, DefaultNamedSharedCounterConfig);
end;

constructor TNamedSharedCounter.Create(const AName: string;
  const AConfig: TNamedSharedCounterConfig);
var
  MapName: string;
begin
  inherited Create;
  FOriginalName := AName;
  FConfig := AConfig;
  FMapping := 0;
  FShared := nil;
  FIsCreator := False;
  FLastError := weNone;

  MapName := CreateMapName(AName);

  // 创建或打开共享内存（64字节以保证缓存行对齐）
  FMapping := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE,
    0, 64, PWideChar(UnicodeString(MapName)));
  if FMapping = 0 then
    raise ELockError.CreateFmt('Failed to create mapping for named shared counter: %s', [AName]);

  FIsCreator := GetLastError <> ERROR_ALREADY_EXISTS;

  FShared := MapViewOfFile(FMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if FShared = nil then
  begin
    CloseHandle(FMapping);
    raise ELockError.CreateFmt('Failed to map view for named shared counter: %s', [AName]);
  end;

  // 初始化（如果是创建者）
  if FIsCreator then
    InterlockedExchange64(FShared^, FConfig.InitialValue);
end;

destructor TNamedSharedCounter.Destroy;
begin
  if FShared <> nil then
    UnmapViewOfFile(FShared);
  if FMapping <> 0 then
    CloseHandle(FMapping);
  inherited Destroy;
end;

function TNamedSharedCounter.CreateMapName(const AName: string): string;
var
  SafeName: string;
  I: Integer;
begin
  SafeName := AName;
  for I := 1 to Length(SafeName) do
    if not (SafeName[I] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      SafeName[I] := '_';

  if FConfig.UseGlobalNamespace then
    Result := PREFIX_MAP + SafeName
  else
    Result := 'Local\fafafa_cnt_' + SafeName;
end;

function TNamedSharedCounter.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedSharedCounter.Increment: Int64;
begin
  Result := Add(1);
end;

function TNamedSharedCounter.Decrement: Int64;
begin
  Result := Sub(1);
end;

function TNamedSharedCounter.Add(AValue: Int64): Int64;
var
  OldVal, NewVal: Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;

  repeat
    OldVal := InterlockedCompareExchange64(FShared^, 0, 0);
    NewVal := OldVal + AValue;
  until InterlockedCompareExchange64(FShared^, NewVal, OldVal) = OldVal;

  FLastError := weNone;
  Result := NewVal;
end;

function TNamedSharedCounter.Sub(AValue: Int64): Int64;
begin
  Result := Add(-AValue);
end;

function TNamedSharedCounter.CompareExchange(AExpected, ANew: Int64): Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;

  FLastError := weNone;
  Result := InterlockedCompareExchange64(FShared^, ANew, AExpected);
end;

function TNamedSharedCounter.Exchange(ANew: Int64): Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit(0);
  end;

  FLastError := weNone;
  Result := InterlockedExchange64(FShared^, ANew);
end;

function TNamedSharedCounter.GetValue: Int64;
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Result := 0;
  end
  else
  begin
    FLastError := weNone;
    Result := InterlockedCompareExchange64(FShared^, 0, 0);
  end;
end;

procedure TNamedSharedCounter.SetValue(AValue: Int64);
begin
  if FShared = nil then
  begin
    FLastError := weInvalidState;
    Exit;
  end;

  FLastError := weNone;
  InterlockedExchange64(FShared^, AValue);
end;

function TNamedSharedCounter.GetName: string;
begin
  Result := FOriginalName;
end;

end.
