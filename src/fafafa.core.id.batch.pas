{
  fafafa.core.id.batch — Batch ID generation for high-throughput scenarios

  - Efficient batch generation for all ID types
  - Pre-allocates arrays for better memory locality
  - Guaranteed monotonic ordering within batches
  - Useful for database inserts, message queues, etc.
}

unit fafafa.core.id.batch;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id,
  fafafa.core.id.ulid,
  fafafa.core.id.ulid.policy,
  fafafa.core.id.ksuid,
  fafafa.core.id.ksuid.ms,
  fafafa.core.id.v7.context,
  fafafa.core.id.snowflake,
  fafafa.core.id.snowflake.lockfree;

type
  { Array types for batch results }
  TUlid128Array = array of TUlid128;
  TKsuid160Array = array of TKsuid160;
  TUuid128Array = array of TUuid128;
  TSnowflakeIDArray = array of TSnowflakeID;
  TIdStringArray = array of string;

{ UUID v7 Batch - Monotonic }
function UuidV7_BatchN(Count: SizeInt): TUuid128Array;
procedure UuidV7_FillN(var OutArr: array of TUuid128);

{ ULID Batch - Monotonic }
function Ulid_BatchN(Count: SizeInt): TUlid128Array;
function Ulid_BatchN_Policy(Count: SizeInt; Policy: TUlidOverflowPolicy): TUlid128Array;
procedure Ulid_FillN(var OutArr: array of TUlid128);

{ KSUID Batch }
function Ksuid_BatchN(Count: SizeInt): TKsuid160Array;
procedure Ksuid_FillN(var OutArr: array of TKsuid160);

{ KSUID-Ms Batch - Millisecond precision }
function KsuidMs_BatchN(Count: SizeInt): TKsuid160Array;
procedure KsuidMs_FillN(var OutArr: array of TKsuid160);

{ Snowflake Batch }
function Snowflake_BatchN(Count: SizeInt; WorkerId: Word = 0): TSnowflakeIDArray;
procedure Snowflake_FillN(var OutArr: array of TSnowflakeID; WorkerId: Word = 0);

{ String batch functions }
function UuidV7Str_BatchN(Count: SizeInt): TIdStringArray;
function UlidStr_BatchN(Count: SizeInt): TIdStringArray;
function KsuidStr_BatchN(Count: SizeInt): TIdStringArray;

implementation

{ UUID v7 Batch }

function UuidV7_BatchN(Count: SizeInt): TUuid128Array;
var
  I: SizeInt;
  Ctx: TContextV7;
begin
  SetLength(Result, Count);
  if Count = 0 then Exit;

  Ctx := TContextV7.Create;
  try
    for I := 0 to Count - 1 do
      Result[I] := Ctx.NextRaw;
  finally
    Ctx.Free;
  end;
end;

procedure UuidV7_FillN(var OutArr: array of TUuid128);
var
  I: SizeInt;
  Ctx: TContextV7;
begin
  if Length(OutArr) = 0 then Exit;

  Ctx := TContextV7.Create;
  try
    for I := Low(OutArr) to High(OutArr) do
      OutArr[I] := Ctx.NextRaw;
  finally
    Ctx.Free;
  end;
end;

{ ULID Batch }

function Ulid_BatchN(Count: SizeInt): TUlid128Array;
begin
  Result := Ulid_BatchN_Policy(Count, opWaitNextMs);
end;

function Ulid_BatchN_Policy(Count: SizeInt; Policy: TUlidOverflowPolicy): TUlid128Array;
var
  I: SizeInt;
  Gen: IUlidGenerator;
begin
  SetLength(Result, Count);
  if Count = 0 then Exit;

  Gen := CreateUlidGenerator(Policy);
  for I := 0 to Count - 1 do
    Result[I] := Gen.NextRaw;
end;

procedure Ulid_FillN(var OutArr: array of TUlid128);
var
  I: SizeInt;
  Gen: IUlidGenerator;
begin
  if Length(OutArr) = 0 then Exit;

  Gen := CreateUlidGenerator(opWaitNextMs);
  for I := Low(OutArr) to High(OutArr) do
    OutArr[I] := Gen.NextRaw;
end;

{ KSUID Batch }

function Ksuid_BatchN(Count: SizeInt): TKsuid160Array;
var
  I: SizeInt;
begin
  SetLength(Result, Count);
  if Count = 0 then Exit;

  for I := 0 to Count - 1 do
    Result[I] := KsuidNow_Raw;
end;

procedure Ksuid_FillN(var OutArr: array of TKsuid160);
var
  I: SizeInt;
begin
  if Length(OutArr) = 0 then Exit;

  for I := Low(OutArr) to High(OutArr) do
    OutArr[I] := KsuidNow_Raw;
end;

{ KSUID-Ms Batch }

function KsuidMs_BatchN(Count: SizeInt): TKsuid160Array;
var
  I: SizeInt;
  Gen: IKsuidMsGenerator;
  K: TKsuidMs160;
begin
  SetLength(Result, Count);
  if Count = 0 then Exit;

  Gen := CreateKsuidMsGenerator;
  for I := 0 to Count - 1 do
  begin
    K := Gen.NextRaw;
    Move(K[0], Result[I][0], 20);
  end;
end;

procedure KsuidMs_FillN(var OutArr: array of TKsuid160);
var
  I: SizeInt;
  Gen: IKsuidMsGenerator;
  K: TKsuidMs160;
begin
  if Length(OutArr) = 0 then Exit;

  Gen := CreateKsuidMsGenerator;
  for I := Low(OutArr) to High(OutArr) do
  begin
    K := Gen.NextRaw;
    Move(K[0], OutArr[I][0], 20);
  end;
end;

{ Snowflake Batch }

function Snowflake_BatchN(Count: SizeInt; WorkerId: Word): TSnowflakeIDArray;
var
  I: SizeInt;
  Gen: ISnowflake;
begin
  SetLength(Result, Count);
  if Count = 0 then Exit;

  Gen := CreateLockFreeSnowflake(WorkerId);
  for I := 0 to Count - 1 do
    Result[I] := Gen.NextID;
end;

procedure Snowflake_FillN(var OutArr: array of TSnowflakeID; WorkerId: Word);
var
  I: SizeInt;
  Gen: ISnowflake;
begin
  if Length(OutArr) = 0 then Exit;

  Gen := CreateLockFreeSnowflake(WorkerId);
  for I := Low(OutArr) to High(OutArr) do
    OutArr[I] := Gen.NextID;
end;

{ String batch functions }

function UuidV7Str_BatchN(Count: SizeInt): TIdStringArray;
var
  I: SizeInt;
  Uuids: TUuid128Array;
begin
  Uuids := UuidV7_BatchN(Count);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := UuidToString(Uuids[I]);
end;

function UlidStr_BatchN(Count: SizeInt): TIdStringArray;
var
  I: SizeInt;
  Ulids: TUlid128Array;
begin
  Ulids := Ulid_BatchN(Count);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := UlidToString(Ulids[I]);
end;

function KsuidStr_BatchN(Count: SizeInt): TIdStringArray;
var
  I: SizeInt;
  Ksuids: TKsuid160Array;
begin
  Ksuids := Ksuid_BatchN(Count);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := KsuidToString(Ksuids[I]);
end;

end.
