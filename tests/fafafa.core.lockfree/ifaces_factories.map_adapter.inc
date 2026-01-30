// Map adapter tests for OA with case-insensitive comparer

{$ifdef FPC}
  {$modeswitch advancedrecords}
{$endif}

uses
  fafafa.core.lockfree.map,
  fafafa.core.lockfree.hashmap.openAddressing;

function CaseInsensitiveHash(const S: string): Cardinal;
begin
  Result := SimpleHash(UpperCase(S), Length(S));
end;

function CaseInsensitiveEqual(const L, R: string): Boolean;
begin
  Result := SameText(L, R);
end;

procedure Test_Map_OA_CaseInsensitive_PutGetRemove;
var
  M: specialize ILockFreeMap<string, Integer>;
  OA: specialize TLockFreeMapOA<string, Integer>;
  V: Integer;
begin
  OA := specialize TLockFreeMapOA<string, Integer>.Create(128);
  try
    M := OA as specialize ILockFreeMap<string, Integer>;
    CheckTrue(M.Put('Key', 1));
    CheckTrue(M.Get('KEY', V));
    CheckEquals(1, V);

    CheckTrue(M.Put('key', 2));
    CheckTrue(M.Get('KEY', V));
    CheckEquals(2, V);

    CheckTrue(M.Remove('KeY'));
    CheckFalse(M.ContainsKey('key'));
  finally
    OA.Free;
  end;
end;

