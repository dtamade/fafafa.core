unit Contracts_Factories_StrInt_TE;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.math,
  fafafa.core.lockfree,
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.hashmap.openAddressing;

type
  IMapStrInt = interface
    ['{2D6FDC5A-8D7F-4D68-9F2B-5F5C3B2D4F18}']
    function Put(const AKey: string; const AValue: Integer; out Replaced: Boolean): Boolean;
    function TryGetValue(const AKey: string; out AValue: Integer): Boolean;
    function Remove(const AKey: string; out OldValue: Integer): Boolean;
    function ContainsKey(const AKey: string): Boolean;
    procedure Clear;
    function Size: SizeInt;
    function LoadFactorTimes1000: Integer; // -1 if unsupported
    function BucketCount: Integer;         // -1 if unsupported
    function MaxLoadFactorTimes1000: Integer; // -1 if unsupported
    function SetMaxLoadFactorTimes1000(Value: Integer): Boolean; // False if unsupported
  end;

  IMapFactory_StrInt = interface
    ['{C59A3E74-7D5A-4A9E-8B28-BF4A9B512F6B}']
    function MakeOA(const ACapacity: SizeInt): IMapStrInt;
    function MakeMM(const ABucketCount: SizeInt): IMapStrInt;
  end;

function GetDefaultMapFactory_StrInt_TE: IMapFactory_StrInt;

implementation

type
  TMap_StrInt_OA = class(TInterfacedObject, IMapStrInt)
  private
    FM: specialize TLockFreeHashMap<string, Integer>;
  public
    constructor Create(ACapacity: SizeInt);
    destructor Destroy; override;
    function Put(const AKey: string; const AValue: Integer; out Replaced: Boolean): Boolean;
    function TryGetValue(const AKey: string; out AValue: Integer): Boolean;
    function Remove(const AKey: string; out OldValue: Integer): Boolean;
    function ContainsKey(const AKey: string): Boolean;
    procedure Clear;
    function Size: SizeInt;
    function LoadFactorTimes1000: Integer;
    function BucketCount: Integer;
    function MaxLoadFactorTimes1000: Integer;
    function SetMaxLoadFactorTimes1000(Value: Integer): Boolean;
  end;

  TMap_StrInt_MM = class(TInterfacedObject, IMapStrInt)
  private
    FM: specialize TMichaelHashMap<string, Integer>;
  public
    constructor Create(ABucketCount: SizeInt);
    destructor Destroy; override;
    function Put(const AKey: string; const AValue: Integer; out Replaced: Boolean): Boolean;
    function TryGetValue(const AKey: string; out AValue: Integer): Boolean;
    function Remove(const AKey: string; out OldValue: Integer): Boolean;
    function ContainsKey(const AKey: string): Boolean;
    procedure Clear;
    function Size: SizeInt;
    function LoadFactorTimes1000: Integer;
    function BucketCount: Integer;
    function MaxLoadFactorTimes1000: Integer;
    function SetMaxLoadFactorTimes1000(Value: Integer): Boolean;
  end;

  TMapFactory_StrInt_TE = class(TInterfacedObject, IMapFactory_StrInt)
  public
    function MakeOA(const ACapacity: SizeInt): IMapStrInt;
    function MakeMM(const ABucketCount: SizeInt): IMapStrInt;
  end;

{ TMap_StrInt_OA }
function StrHash(const S: string): Cardinal;
const
  FNV_offset_basis = Cardinal($811C9DC5);
  FNV_prime = Cardinal(16777619);
var
  i: SizeInt;
  p: PAnsiChar;
begin
  Result := FNV_offset_basis;
  if Length(S) = 0 then Exit;
  p := PAnsiChar(S);
  for i := 1 to Length(S) do
  begin
    Result := Result xor Ord(p^);
    Result := Result * FNV_prime;
    Inc(p);
  end;
end;

function StrEqual(const L, R: string): Boolean;
begin
  Exit(L = R);
end;

constructor TMap_StrInt_OA.Create(ACapacity: SizeInt);
begin
  inherited Create;
  FM := specialize TLockFreeHashMap<string, Integer>.Create(ACapacity, @StrHash, @StrEqual);
end;

destructor TMap_StrInt_OA.Destroy;
begin
  FM.Free;
  inherited Destroy;
end;

function TMap_StrInt_OA.Put(const AKey: string; const AValue: Integer; out Replaced: Boolean): Boolean;
begin
  Replaced := FM.ContainsKey(AKey);
  Result := FM.Put(AKey, AValue);
end;

function TMap_StrInt_OA.TryGetValue(const AKey: string; out AValue: Integer): Boolean;
begin
  Result := FM.Get(AKey, AValue);
end;

function TMap_StrInt_OA.Remove(const AKey: string; out OldValue: Integer): Boolean;
begin
  if FM.Get(AKey, OldValue) then Exit(FM.Remove(AKey)) else Exit(False);
end;

function TMap_StrInt_OA.ContainsKey(const AKey: string): Boolean;
begin
  Result := FM.ContainsKey(AKey);
end;

procedure TMap_StrInt_OA.Clear;
begin
  FM.Clear;
end;

function TMap_StrInt_OA.Size: SizeInt;
begin
  Result := FM.GetSize;
end;

function TMap_StrInt_OA.LoadFactorTimes1000: Integer;
begin
  Result := -1;
end;

function TMap_StrInt_OA.BucketCount: Integer;
begin
  Result := -1;
end;

function TMap_StrInt_OA.MaxLoadFactorTimes1000: Integer;
begin
  Result := -1;
end;

function TMap_StrInt_OA.SetMaxLoadFactorTimes1000(Value: Integer): Boolean;
begin
  Result := False;
end;

{ TMap_StrInt_MM }
constructor TMap_StrInt_MM.Create(ABucketCount: SizeInt);
begin
  inherited Create;
  FM := CreateStrIntMMHashMap(ABucketCount);
end;

destructor TMap_StrInt_MM.Destroy;
begin
  FM.Free;
  inherited Destroy;
end;

function TMap_StrInt_MM.Put(const AKey: string; const AValue: Integer; out Replaced: Boolean): Boolean;
var tmp: Integer;
begin
  if FM.find(AKey, tmp) then
  begin
    Replaced := True;
    Result := FM.update(AKey, AValue);
  end
  else
  begin
    Replaced := False;
    Result := FM.insert(AKey, AValue);
  end;
end;

function TMap_StrInt_MM.TryGetValue(const AKey: string; out AValue: Integer): Boolean;
begin
  Result := FM.find(AKey, AValue);
end;

function TMap_StrInt_MM.Remove(const AKey: string; out OldValue: Integer): Boolean;
begin
  if FM.find(AKey, OldValue) then Exit(FM.erase(AKey)) else Exit(False);
end;

function TMap_StrInt_MM.ContainsKey(const AKey: string): Boolean;
var dummy: Integer;
begin
  Result := FM.find(AKey, dummy);
end;

procedure TMap_StrInt_MM.Clear;
begin
  FM.clear;
end;

function TMap_StrInt_MM.Size: SizeInt;
begin
  Result := FM.size;
end;

function TMap_StrInt_MM.LoadFactorTimes1000: Integer;
begin
  Result := Round(FM.load_factor * 1000);
end;

function TMap_StrInt_MM.BucketCount: Integer;
begin
  Result := FM.bucket_count;
end;

function TMap_StrInt_MM.MaxLoadFactorTimes1000: Integer;
begin
  Result := Round(FM.max_load_factor * 1000);
end;

function TMap_StrInt_MM.SetMaxLoadFactorTimes1000(Value: Integer): Boolean;
begin
  FM.max_load_factor(Value / 1000.0);
  Result := True;
end;

{ TMapFactory_StrInt_TE }
function TMapFactory_StrInt_TE.MakeOA(const ACapacity: SizeInt): IMapStrInt;
begin
  // 现已为 OA 提供可插拔 Hash/Equal，字符串键使用值语义 hash/equal
  Result := TMap_StrInt_OA.Create(ACapacity);
end;

function TMapFactory_StrInt_TE.MakeMM(const ABucketCount: SizeInt): IMapStrInt;
begin
  Result := TMap_StrInt_MM.Create(ABucketCount);
end;

function GetDefaultMapFactory_StrInt_TE: IMapFactory_StrInt;
begin
  Result := TMapFactory_StrInt_TE.Create;
end;

end.

