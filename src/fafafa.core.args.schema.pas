unit fafafa.core.args.schema;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

type
  // forward declare interfaces to allow array aliases
  IArgsFlagSpec = interface;
  IArgsPositionalSpec = interface;

  TStringArray = array of string;
  TFlagSpecArray = array of IArgsFlagSpec;
  TPositionalSpecArray = array of IArgsPositionalSpec;

  // Flag specification
  IArgsFlagSpec = interface
    ['{C9E0B32C-7F0F-4A9D-9E11-0F3A2B4C5D6E}']
    function Name: string;
    function Aliases: TStringArray;
    function Description: string;
    function Required: boolean;
    function DefaultValue: string;
    function ValueType: string; // e.g., string/int/bool
    function Persistent: boolean;
    procedure SetName(const S: string);
    procedure AddAlias(const S: string);
    procedure SetDescription(const S: string);
    procedure SetRequired(V: boolean);
    procedure SetDefaultValue(const S: string);
    procedure SetValueType(const S: string);
    procedure SetPersistent(V: boolean);
  end;

  // Positional specification
  IArgsPositionalSpec = interface
    ['{AE6E1E74-5C5F-4D1F-BF5E-9F0F2A9C7B3A}']
    function Name: string;
    function Description: string;
    function Required: boolean;
    function Variadic: boolean;
    procedure SetName(const S: string);
    procedure SetDescription(const S: string);
    procedure SetRequired(V: boolean);
    procedure SetVariadic(V: boolean);
  end;

  // Command spec aggregates flags and positionals
  IArgsCommandSpec = interface
    ['{B4C0C0A2-9A56-4A94-9C7B-8E0C5C8D9C21}']
    function Description: string;
    procedure SetDescription(const S: string);
    // FPC-friendly accessors
    function FlagCount: Integer;
    function FlagAt(Index: Integer): IArgsFlagSpec;
    function PositionalCount: Integer;
    function PositionalAt(Index: Integer): IArgsPositionalSpec;
    procedure AddFlag(const F: IArgsFlagSpec);
    procedure AddPositional(const P: IArgsPositionalSpec);
  end;

function NewCommandSpec: IArgsCommandSpec;
function NewFlagSpec(const AName, ADesc: string; ARequired: boolean; const AType: string; const ADefault: string = ''): IArgsFlagSpec;
function NewPositionalSpec(const AName, ADesc: string; ARequired, AVariadic: boolean): IArgsPositionalSpec;

implementation

type
  TArgsFlagSpec = class(TInterfacedObject, IArgsFlagSpec)
  private
    FName: string;
    FAliases: TStringArray;
    FDesc: string;
    FRequired: boolean;
    FDefault: string;
    FType: string;
    FPersistent: boolean;
  public
    function Name: string; inline;
    function Aliases: TStringArray; inline;
    function Description: string; inline;
    function Required: boolean; inline;
    function DefaultValue: string; inline;
    function ValueType: string; inline;
    function Persistent: boolean; inline;
    procedure SetName(const S: string); inline;
    procedure AddAlias(const S: string);
    procedure SetDescription(const S: string); inline;
    procedure SetRequired(V: boolean); inline;
    procedure SetDefaultValue(const S: string); inline;
    procedure SetValueType(const S: string); inline;
    procedure SetPersistent(V: boolean); inline;
  end;

  TArgsPositionalSpec = class(TInterfacedObject, IArgsPositionalSpec)
  private
    FName: string;
    FDesc: string;
    FRequired: boolean;
    FVariadic: boolean;
  public
    function Name: string; inline;
    function Description: string; inline;
    function Required: boolean; inline;
    function Variadic: boolean; inline;
    procedure SetName(const S: string); inline;
    procedure SetDescription(const S: string); inline;
    procedure SetRequired(V: boolean); inline;
    procedure SetVariadic(V: boolean); inline;
  end;

  TArgsCommandSpec = class(TInterfacedObject, IArgsCommandSpec)
  private
    FDesc: string;
    FFlags: TFlagSpecArray;
    FPositionals: TPositionalSpecArray;
  public
    function Description: string; inline;
    procedure SetDescription(const S: string); inline;
    function FlagCount: Integer; inline;
    function FlagAt(Index: Integer): IArgsFlagSpec;
    function PositionalCount: Integer; inline;
    function PositionalAt(Index: Integer): IArgsPositionalSpec;
    procedure AddFlag(const F: IArgsFlagSpec);
    procedure AddPositional(const P: IArgsPositionalSpec);
  end;

function NewCommandSpec: IArgsCommandSpec;
begin
  Result := TArgsCommandSpec.Create;
end;

function NewFlagSpec(const AName, ADesc: string; ARequired: boolean; const AType: string; const ADefault: string = ''): IArgsFlagSpec;
var F: TArgsFlagSpec;
begin
  F := TArgsFlagSpec.Create;
  F.FName := AName;
  F.FDesc := ADesc;
  F.FRequired := ARequired;
  F.FType := AType;
  F.FDefault := ADefault;
  Result := F;
end;

function NewPositionalSpec(const AName, ADesc: string; ARequired, AVariadic: boolean): IArgsPositionalSpec;
var P: TArgsPositionalSpec;
begin
  P := TArgsPositionalSpec.Create;
  P.FName := AName;
  P.FDesc := ADesc;
  P.FRequired := ARequired;
  P.FVariadic := AVariadic;
  Result := P;
end;

{ TArgsFlagSpec }
function TArgsFlagSpec.Name: string; begin Result := FName; end;
function TArgsFlagSpec.Aliases: TStringArray; begin Result := FAliases; end;
function TArgsFlagSpec.Description: string; begin Result := FDesc; end;
function TArgsFlagSpec.Required: boolean; begin Result := FRequired; end;
function TArgsFlagSpec.DefaultValue: string; begin Result := FDefault; end;
function TArgsFlagSpec.ValueType: string; begin Result := FType; end;
function TArgsFlagSpec.Persistent: boolean; begin Result := FPersistent; end;
procedure TArgsFlagSpec.SetName(const S: string); begin FName := S; end;
procedure TArgsFlagSpec.AddAlias(const S: string);
begin
  SetLength(FAliases, Length(FAliases)+1);
  FAliases[High(FAliases)] := S;
end;
procedure TArgsFlagSpec.SetDescription(const S: string); begin FDesc := S; end;
procedure TArgsFlagSpec.SetRequired(V: boolean); begin FRequired := V; end;
procedure TArgsFlagSpec.SetDefaultValue(const S: string); begin FDefault := S; end;
procedure TArgsFlagSpec.SetValueType(const S: string); begin FType := S; end;
procedure TArgsFlagSpec.SetPersistent(V: boolean); begin FPersistent := V; end;

{ TArgsPositionalSpec }
function TArgsPositionalSpec.Name: string; begin Result := FName; end;
function TArgsPositionalSpec.Description: string; begin Result := FDesc; end;
function TArgsPositionalSpec.Required: boolean; begin Result := FRequired; end;
function TArgsPositionalSpec.Variadic: boolean; begin Result := FVariadic; end;
procedure TArgsPositionalSpec.SetName(const S: string); begin FName := S; end;
procedure TArgsPositionalSpec.SetDescription(const S: string); begin FDesc := S; end;
procedure TArgsPositionalSpec.SetRequired(V: boolean); begin FRequired := V; end;
procedure TArgsPositionalSpec.SetVariadic(V: boolean); begin FVariadic := V; end;

{ TArgsCommandSpec }
function TArgsCommandSpec.Description: string; begin Result := FDesc; end;
procedure TArgsCommandSpec.SetDescription(const S: string); begin FDesc := S; end;
function TArgsCommandSpec.FlagCount: Integer; begin Result := Length(FFlags); end;
function TArgsCommandSpec.FlagAt(Index: Integer): IArgsFlagSpec;
begin
  if (Index>=0) and (Index<Length(FFlags)) then Result := FFlags[Index] else Result := nil;
end;
function TArgsCommandSpec.PositionalCount: Integer; begin Result := Length(FPositionals); end;
function TArgsCommandSpec.PositionalAt(Index: Integer): IArgsPositionalSpec;
begin
  if (Index>=0) and (Index<Length(FPositionals)) then Result := FPositionals[Index] else Result := nil;
end;
procedure TArgsCommandSpec.AddFlag(const F: IArgsFlagSpec);
begin
  SetLength(FFlags, Length(FFlags)+1);
  FFlags[High(FFlags)] := F;
end;
procedure TArgsCommandSpec.AddPositional(const P: IArgsPositionalSpec);
begin
  SetLength(FPositionals, Length(FPositionals)+1);
  FPositionals[High(FPositionals)] := P;
end;

end.

