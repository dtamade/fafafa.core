class procedure TFixedPoolTL.ThreadCleanup;
var idx: Integer; tp: TFixedPool;
begin
  tp := ThreadPool;
  if tp = nil then Exit;
  DrainInboxOfIndex(GetRegistryIndexForPool(tp), tp);
  SiphonCrossQueueFor(tp);
  idx := GetRegistryIndexForPool(tp);
  if idx >= 0 then
  begin
    EnterCriticalSection(TFixedPoolTL.RegistryLock);
    try
      DoneCriticalsection(TFixedPoolTL.Registry[idx].InboxLock);
      if idx <> High(TFixedPoolTL.Registry) then
        TFixedPoolTL.Registry[idx] := TFixedPoolTL.Registry[High(TFixedPoolTL.Registry)];
      SetLength(TFixedPoolTL.Registry, Length(TFixedPoolTL.Registry)-1);
    finally
      LeaveCriticalSection(TFixedPoolTL.RegistryLock);
    end;
  end;
  FreeAndNil(ThreadPool);
  ThreadIndexValid := False;
  ThreadIndex := -1;
end;

