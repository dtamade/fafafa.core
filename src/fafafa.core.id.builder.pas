{
  fafafa.core.id.builder — Unified Builder API for ID generation

  - Fluent API for configuring and generating IDs
  - Consistent interface across UUID, ULID, KSUID, Snowflake
  - Type-safe configuration options
  - Inspired by Rust builder patterns
}

unit fafafa.core.id.builder;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id,
  fafafa.core.id.v5,
  fafafa.core.id.v6,
  fafafa.core.id.v7.context,
  fafafa.core.id.ulid,
  fafafa.core.id.ulid.policy,
  fafafa.core.id.ksuid,
  fafafa.core.id.ksuid.ms,
  fafafa.core.id.snowflake,
  fafafa.core.id.snowflake.lockfree;

type
  { UUID version enumeration }
  TUuidVersion = (uvV4, uvV5, uvV6, uvV7);

  { Forward declarations }
  TUuidBuilder = class;
  TUlidBuilder = class;
  TKsuidBuilder = class;
  TSnowflakeBuilder = class;

  { TUuidBuilder - Fluent UUID builder }
  TUuidBuilder = class
  private
    FVersion: TUuidVersion;
    FMonotonic: Boolean;
    FNamespace: TUuidNamespace;
    FName: string;
    FCustomNamespace: TUuid128;
    FUseCustomNamespace: Boolean;
  public
    constructor Create;

    function Version(V: TUuidVersion): TUuidBuilder;
    function V4: TUuidBuilder;
    function V5: TUuidBuilder;
    function V6: TUuidBuilder;
    function V7: TUuidBuilder;
    function Monotonic(Enabled: Boolean = True): TUuidBuilder;
    function Namespace(NS: TUuidNamespace): TUuidBuilder;
    function CustomNamespace(const NS: TUuid128): TUuidBuilder;
    function Name(const AName: string): TUuidBuilder;

    function Build: TUuid128;
    function BuildStr: string;
  end;

  { TUlidBuilder - Fluent ULID builder }
  TUlidBuilder = class
  private
    FMonotonic: Boolean;
    FOverflowPolicy: TUlidOverflowPolicy;
    FGenerator: IUlidGenerator;
  public
    constructor Create;

    function Monotonic(Enabled: Boolean = True): TUlidBuilder;
    function OverflowPolicy(Policy: TUlidOverflowPolicy): TUlidBuilder;
    function WaitOnOverflow: TUlidBuilder;
    function WrapOnOverflow: TUlidBuilder;
    function ErrorOnOverflow: TUlidBuilder;

    function Build: TUlid128;
    function BuildStr: string;
  end;

  { TKsuidBuilder - Fluent KSUID builder }
  TKsuidBuilder = class
  private
    FHighPrecision: Boolean;
    FMonotonic: Boolean;
  public
    constructor Create;

    function HighPrecision(Enabled: Boolean = True): TKsuidBuilder;
    function Monotonic(Enabled: Boolean = True): TKsuidBuilder;
    function Standard: TKsuidBuilder;
    function Millisecond: TKsuidBuilder;

    function Build: TKsuid160;
    function BuildStr: string;
  end;

  { TSnowflakeBuilder - Fluent Snowflake builder }
  TSnowflakeBuilder = class
  private
    FWorkerId: Word;
    FEpochMs: Int64;
    FLockFree: Boolean;
    FClockPolicy: TClockRollbackPolicy;
  public
    constructor Create;

    function WorkerId(Id: Word): TSnowflakeBuilder;
    function Epoch(Ms: Int64): TSnowflakeBuilder;
    function TwitterEpoch: TSnowflakeBuilder;
    function DiscordEpoch: TSnowflakeBuilder;
    function LockFree(Enabled: Boolean = True): TSnowflakeBuilder;
    function ClockPolicy(Policy: TClockRollbackPolicy): TSnowflakeBuilder;

    function Build: TSnowflakeID;
    function BuildGenerator: ISnowflake;
  end;

  { TIdBuilder - Entry point for all ID builders }
  TIdBuilder = class
  public
    class function UUID: TUuidBuilder; static;
    class function ULID: TUlidBuilder; static;
    class function KSUID: TKsuidBuilder; static;
    class function Snowflake: TSnowflakeBuilder; static;
  end;

implementation

{ TIdBuilder }

class function TIdBuilder.UUID: TUuidBuilder;
begin
  Result := TUuidBuilder.Create;
end;

class function TIdBuilder.ULID: TUlidBuilder;
begin
  Result := TUlidBuilder.Create;
end;

class function TIdBuilder.KSUID: TKsuidBuilder;
begin
  Result := TKsuidBuilder.Create;
end;

class function TIdBuilder.Snowflake: TSnowflakeBuilder;
begin
  Result := TSnowflakeBuilder.Create;
end;

{ TUuidBuilder }

constructor TUuidBuilder.Create;
begin
  inherited Create;
  FVersion := uvV4;
  FMonotonic := False;
  FNamespace := nsDNS;
  FName := '';
  FUseCustomNamespace := False;
end;

function TUuidBuilder.Version(V: TUuidVersion): TUuidBuilder;
begin
  FVersion := V;
  Result := Self;
end;

function TUuidBuilder.V4: TUuidBuilder;
begin
  FVersion := uvV4;
  Result := Self;
end;

function TUuidBuilder.V5: TUuidBuilder;
begin
  FVersion := uvV5;
  Result := Self;
end;

function TUuidBuilder.V6: TUuidBuilder;
begin
  FVersion := uvV6;
  Result := Self;
end;

function TUuidBuilder.V7: TUuidBuilder;
begin
  FVersion := uvV7;
  Result := Self;
end;

function TUuidBuilder.Monotonic(Enabled: Boolean): TUuidBuilder;
begin
  FMonotonic := Enabled;
  Result := Self;
end;

function TUuidBuilder.Namespace(NS: TUuidNamespace): TUuidBuilder;
begin
  FNamespace := NS;
  FUseCustomNamespace := False;
  Result := Self;
end;

function TUuidBuilder.CustomNamespace(const NS: TUuid128): TUuidBuilder;
begin
  FCustomNamespace := NS;
  FUseCustomNamespace := True;
  Result := Self;
end;

function TUuidBuilder.Name(const AName: string): TUuidBuilder;
begin
  FName := AName;
  Result := Self;
end;

function TUuidBuilder.Build: TUuid128;
begin
  try
    case FVersion of
      uvV4:
        Result := UuidV4_Raw;
      uvV5:
        begin
          if FName = '' then
            raise Exception.Create('UUID v5 requires a name');
          if FUseCustomNamespace then
            Result := fafafa.core.id.v5.UuidV5(FCustomNamespace, FName)
          else
            Result := fafafa.core.id.v5.UuidV5(FNamespace, FName);
        end;
      uvV6:
        Result := fafafa.core.id.v6.UuidV6;
      uvV7:
        begin
          if FMonotonic then
            Result := UuidV7_MonotonicRaw
          else
            Result := UuidV7_Raw;
        end;
    end;
  finally
    Free;  // Auto-free builder after use
  end;
end;

function TUuidBuilder.BuildStr: string;
begin
  Result := UuidToString(Build);
end;

{ TUlidBuilder }

constructor TUlidBuilder.Create;
begin
  inherited Create;
  FMonotonic := True;
  FOverflowPolicy := opWaitNextMs;
  FGenerator := nil;
end;

function TUlidBuilder.Monotonic(Enabled: Boolean): TUlidBuilder;
begin
  FMonotonic := Enabled;
  Result := Self;
end;

function TUlidBuilder.OverflowPolicy(Policy: TUlidOverflowPolicy): TUlidBuilder;
begin
  FOverflowPolicy := Policy;
  Result := Self;
end;

function TUlidBuilder.WaitOnOverflow: TUlidBuilder;
begin
  FOverflowPolicy := opWaitNextMs;
  Result := Self;
end;

function TUlidBuilder.WrapOnOverflow: TUlidBuilder;
begin
  FOverflowPolicy := opWrapToZero;
  Result := Self;
end;

function TUlidBuilder.ErrorOnOverflow: TUlidBuilder;
begin
  FOverflowPolicy := opRaiseError;
  Result := Self;
end;

function TUlidBuilder.Build: TUlid128;
begin
  try
    if FMonotonic then
    begin
      FGenerator := CreateUlidGenerator(FOverflowPolicy);
      Result := FGenerator.NextRaw;
    end
    else
      Result := UlidNow_Raw;
  finally
    Free;
  end;
end;

function TUlidBuilder.BuildStr: string;
begin
  Result := UlidToString(Build);
end;

{ TKsuidBuilder }

constructor TKsuidBuilder.Create;
begin
  inherited Create;
  FHighPrecision := False;
  FMonotonic := False;
end;

function TKsuidBuilder.HighPrecision(Enabled: Boolean): TKsuidBuilder;
begin
  FHighPrecision := Enabled;
  Result := Self;
end;

function TKsuidBuilder.Monotonic(Enabled: Boolean): TKsuidBuilder;
begin
  FMonotonic := Enabled;
  Result := Self;
end;

function TKsuidBuilder.Standard: TKsuidBuilder;
begin
  FHighPrecision := False;
  Result := Self;
end;

function TKsuidBuilder.Millisecond: TKsuidBuilder;
begin
  FHighPrecision := True;
  Result := Self;
end;

function TKsuidBuilder.Build: TKsuid160;
var
  MsK: TKsuidMs160;
begin
  try
    if FHighPrecision then
    begin
      MsK := KsuidMsNow;
      Move(MsK[0], Result[0], 20);
    end
    else
    begin
      // Standard KSUID doesn't have monotonic variant; use raw generation
      // For monotonic behavior with KSUID, use HighPrecision mode (KsuidMs)
      Result := KsuidNow_Raw;
    end;
  finally
    Free;
  end;
end;

function TKsuidBuilder.BuildStr: string;
begin
  Result := KsuidToString(Build);
end;

{ TSnowflakeBuilder }

constructor TSnowflakeBuilder.Create;
begin
  inherited Create;
  FWorkerId := 0;
  FEpochMs := 1288834974657;  // Twitter epoch
  FLockFree := True;
  FClockPolicy := crpSpinWait;
end;

function TSnowflakeBuilder.WorkerId(Id: Word): TSnowflakeBuilder;
begin
  FWorkerId := Id and $3FF;  // 10 bits max
  Result := Self;
end;

function TSnowflakeBuilder.Epoch(Ms: Int64): TSnowflakeBuilder;
begin
  FEpochMs := Ms;
  Result := Self;
end;

function TSnowflakeBuilder.TwitterEpoch: TSnowflakeBuilder;
begin
  FEpochMs := 1288834974657;  // Nov 04, 2010
  Result := Self;
end;

function TSnowflakeBuilder.DiscordEpoch: TSnowflakeBuilder;
begin
  FEpochMs := 1420070400000;  // Jan 01, 2015
  Result := Self;
end;

function TSnowflakeBuilder.LockFree(Enabled: Boolean): TSnowflakeBuilder;
begin
  FLockFree := Enabled;
  Result := Self;
end;

function TSnowflakeBuilder.ClockPolicy(Policy: TClockRollbackPolicy): TSnowflakeBuilder;
begin
  FClockPolicy := Policy;
  Result := Self;
end;

function TSnowflakeBuilder.Build: TSnowflakeID;
var
  Gen: ISnowflake;
begin
  Gen := BuildGenerator;
  Result := Gen.NextID;
end;

function TSnowflakeBuilder.BuildGenerator: ISnowflake;
begin
  try
    if FLockFree then
    begin
      Result := CreateLockFreeSnowflake(FWorkerId, FEpochMs);
      (Result as TLockFreeSnowflake).ClockPolicy := FClockPolicy;
    end
    else
      Result := CreateSnowflake(FWorkerId, FEpochMs);
  finally
    Free;
  end;
end;

end.
