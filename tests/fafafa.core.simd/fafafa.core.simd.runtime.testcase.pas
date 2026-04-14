unit fafafa.core.simd.runtime.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.runtime;

type
  TTestCase_RuntimeAPI = class(TTestCase)
  private
    class procedure AssertBackendArrayEquals(const aMessage: string;
      const aExpected, aActual: TSimdBackendArray); static;
  published
    procedure Test_RuntimeCurrentBackend_View_Matches_LegacyFacade;
    procedure Test_RuntimeDispatchableView_Matches_LegacyFacadeAliases;
    procedure Test_RuntimeControlPlane_SwitchAndReset_Match_LegacyFacade;
    procedure Test_FacadeCpuCapability_View_Uses_Canonical_Cpuinfo_Semantics;
    procedure Test_RuntimeSnapshot_Canonical_Name_Aliases_Legacy_Subunit_Name;
    procedure Test_FacadeRuntimeSnapshot_View_Matches_Runtime_Subunit;
    procedure Test_FacadeRuntimeControlPlane_Wrappers_Interoperate_With_Legacy_Aliases;
    procedure Test_RuntimeSnapshot_View_Matches_Runtime_And_Legacy_Helpers;
    procedure Test_RuntimeSnapshot_Switch_Tracks_ControlPlane_And_Dispatch;
  end;

implementation

class procedure TTestCase_RuntimeAPI.AssertBackendArrayEquals(const aMessage: string;
  const aExpected, aActual: TSimdBackendArray);
var
  LIndex: Integer;
begin
  AssertEquals(aMessage + ' length', Length(aExpected), Length(aActual));
  for LIndex := 0 to High(aExpected) do
    AssertEquals(aMessage + ' item[' + IntToStr(LIndex) + ']',
      Ord(aExpected[LIndex]), Ord(aActual[LIndex]));
end;

procedure TTestCase_RuntimeAPI.Test_RuntimeCurrentBackend_View_Matches_LegacyFacade;
var
  LDispatch: PSimdDispatchTable;
  LLegacyInfo: TSimdBackendInfo;
  LRuntimeInfo: TSimdBackendInfo;
begin
  LDispatch := GetDispatchTable;
  AssertTrue('GetDispatchTable should be assigned', LDispatch <> nil);

  AssertEquals('runtime current backend should match legacy facade helper',
    Ord(fafafa.core.simd.GetCurrentBackend),
    Ord(fafafa.core.simd.runtime.GetCurrentBackend));
  AssertEquals('runtime current backend should match dispatch snapshot backend',
    Ord(LDispatch^.Backend),
    Ord(fafafa.core.simd.runtime.GetCurrentBackend));

  LLegacyInfo := fafafa.core.simd.GetCurrentBackendInfo;
  LRuntimeInfo := fafafa.core.simd.runtime.GetCurrentBackendInfo;

  AssertEquals('runtime backend info backend should match legacy helper',
    Ord(LLegacyInfo.Backend), Ord(LRuntimeInfo.Backend));
  AssertEquals('runtime backend info name should match legacy helper',
    LLegacyInfo.Name, LRuntimeInfo.Name);
  AssertEquals('runtime backend info description should match legacy helper',
    LLegacyInfo.Description, LRuntimeInfo.Description);
  AssertEquals('runtime backend info availability should match legacy helper',
    LLegacyInfo.Available, LRuntimeInfo.Available);
  AssertEquals('runtime backend info priority should match legacy helper',
    LLegacyInfo.Priority, LRuntimeInfo.Priority);
  AssertTrue('runtime backend info capabilities should match legacy helper',
    LLegacyInfo.Capabilities = LRuntimeInfo.Capabilities);
end;

procedure TTestCase_RuntimeAPI.Test_RuntimeDispatchableView_Matches_LegacyFacadeAliases;
var
  LRuntimeDispatchable: TSimdBackendArray;
  LLegacyDispatchable: TSimdBackendArray;
  LLegacyAvailable: TSimdBackendArray;
  LIndex: Integer;
begin
  LRuntimeDispatchable := fafafa.core.simd.runtime.GetDispatchableBackendList;
  LLegacyDispatchable := fafafa.core.simd.GetDispatchableBackendList;
  LLegacyAvailable := fafafa.core.simd.GetAvailableBackendList;

  AssertBackendArrayEquals('runtime dispatchable backends should match legacy dispatchable helper',
    LLegacyDispatchable, LRuntimeDispatchable);
  AssertBackendArrayEquals('runtime dispatchable backends should match legacy available alias',
    LLegacyAvailable, LRuntimeDispatchable);
  AssertEquals('runtime best dispatchable backend should match legacy helper',
    Ord(fafafa.core.simd.GetBestDispatchableBackend),
    Ord(fafafa.core.simd.runtime.GetBestDispatchableBackend));

  for LIndex := 0 to High(LRuntimeDispatchable) do
  begin
    AssertTrue('dispatchable backend should remain CPU-supported',
      IsBackendSupportedOnCPU(LRuntimeDispatchable[LIndex]));
    AssertTrue('dispatchable backend should remain registered in binary',
      fafafa.core.simd.runtime.IsBackendRegisteredInBinary(LRuntimeDispatchable[LIndex]));
  end;
end;

procedure TTestCase_RuntimeAPI.Test_RuntimeControlPlane_SwitchAndReset_Match_LegacyFacade;
var
  LOriginalBackend: TSimdBackend;
  LOriginalBestDispatchable: TSimdBackend;
  LRestoredBackend: TSimdBackend;
begin
  LOriginalBackend := fafafa.core.simd.runtime.GetCurrentBackend;
  LOriginalBestDispatchable := fafafa.core.simd.GetBestDispatchableBackend;
  try
    AssertTrue('TrySetCurrentBackend(sbScalar) should succeed',
      fafafa.core.simd.runtime.TrySetCurrentBackend(sbScalar));
    AssertEquals('runtime current backend should switch to Scalar',
      Ord(sbScalar), Ord(fafafa.core.simd.runtime.GetCurrentBackend));
    AssertEquals('legacy current backend should track runtime switch',
      Ord(sbScalar), Ord(fafafa.core.simd.GetCurrentBackend));
    AssertEquals('dispatch snapshot should track runtime switch',
      Ord(sbScalar), Ord(GetDispatchTable^.Backend));

    fafafa.core.simd.runtime.ResetCurrentBackendSelection;
    AssertEquals('runtime reset should restore automatic best backend',
      Ord(fafafa.core.simd.GetBestDispatchableBackend),
      Ord(fafafa.core.simd.runtime.GetCurrentBackend));
    AssertEquals('legacy current backend should track runtime reset',
      Ord(fafafa.core.simd.runtime.GetCurrentBackend),
      Ord(fafafa.core.simd.GetCurrentBackend));
    AssertEquals('dispatch snapshot should track runtime reset',
      Ord(fafafa.core.simd.runtime.GetCurrentBackend),
      Ord(GetDispatchTable^.Backend));
  finally
    if LOriginalBackend = LOriginalBestDispatchable then
      fafafa.core.simd.runtime.ResetCurrentBackendSelection
    else
      AssertTrue('runtime should restore original forced backend',
        fafafa.core.simd.runtime.TrySetCurrentBackend(LOriginalBackend));

    LRestoredBackend := fafafa.core.simd.runtime.GetCurrentBackend;
    AssertEquals('runtime should restore original backend after test',
      Ord(LOriginalBackend), Ord(LRestoredBackend));
  end;
end;

procedure TTestCase_RuntimeAPI.Test_FacadeCpuCapability_View_Uses_Canonical_Cpuinfo_Semantics;
var
  LFacadeCanonicalCPUInfo: TCPUInfo;
  LFacadeCPUInfo: TCPUInfo;
  LCanonicalCPUInfo: TCPUInfo;
  LFacadeSupported: TSimdBackendArray;
  LCanonicalSupported: TSimdBackendArray;
begin
  LFacadeCanonicalCPUInfo := fafafa.core.simd.GetCPUInfo;
  LFacadeCPUInfo := fafafa.core.simd.GetCPUInformation;
  LCanonicalCPUInfo := fafafa.core.simd.cpuinfo.GetCPUInfo;

  AssertEquals('facade canonical GetCPUInfo should match legacy GetCPUInformation arch',
    Ord(LFacadeCPUInfo.Arch), Ord(LFacadeCanonicalCPUInfo.Arch));
  AssertEquals('facade canonical GetCPUInfo should match legacy GetCPUInformation vendor',
    LFacadeCPUInfo.Vendor, LFacadeCanonicalCPUInfo.Vendor);
  AssertEquals('facade canonical GetCPUInfo should match legacy GetCPUInformation model',
    LFacadeCPUInfo.Model, LFacadeCanonicalCPUInfo.Model);

  AssertEquals('facade CPU info arch should match canonical cpuinfo getter',
    Ord(LCanonicalCPUInfo.Arch), Ord(LFacadeCanonicalCPUInfo.Arch));
  AssertEquals('facade CPU info vendor should match canonical cpuinfo getter',
    LCanonicalCPUInfo.Vendor, LFacadeCanonicalCPUInfo.Vendor);
  AssertEquals('facade CPU info model should match canonical cpuinfo getter',
    LCanonicalCPUInfo.Model, LFacadeCanonicalCPUInfo.Model);
  AssertEquals('facade CPU logical core count should match canonical cpuinfo getter',
    LCanonicalCPUInfo.LogicalCores, LFacadeCanonicalCPUInfo.LogicalCores);
  AssertEquals('facade CPU physical core count should match canonical cpuinfo getter',
    LCanonicalCPUInfo.PhysicalCores, LFacadeCanonicalCPUInfo.PhysicalCores);
  AssertEquals('facade CPU OSXSAVE flag should match canonical cpuinfo getter',
    LCanonicalCPUInfo.OSXSAVE, LFacadeCanonicalCPUInfo.OSXSAVE);
  AssertEquals('facade CPU XCR0 should match canonical cpuinfo getter',
    LCanonicalCPUInfo.XCR0, LFacadeCanonicalCPUInfo.XCR0);
  AssertTrue('facade CPU raw generic features should match canonical cpuinfo getter',
    LCanonicalCPUInfo.GenericRaw = LFacadeCanonicalCPUInfo.GenericRaw);
  AssertTrue('facade CPU usable generic features should match canonical cpuinfo getter',
    LCanonicalCPUInfo.GenericUsable = LFacadeCanonicalCPUInfo.GenericUsable);

  LFacadeSupported := fafafa.core.simd.GetSupportedBackendList;
  LCanonicalSupported := fafafa.core.simd.cpuinfo.GetSupportedBackendList;
  AssertBackendArrayEquals('facade supported backend list should stay on canonical cpuinfo semantics',
    LCanonicalSupported, LFacadeSupported);
  AssertEquals('facade best supported backend should match canonical cpuinfo getter',
    Ord(fafafa.core.simd.cpuinfo.GetBestSupportedBackend),
    Ord(fafafa.core.simd.GetBestSupportedBackend));
end;

procedure TTestCase_RuntimeAPI.Test_RuntimeSnapshot_Canonical_Name_Aliases_Legacy_Subunit_Name;
var
  LCanonicalSnapshot: TSimdRuntimeSnapshot;
  LLegacySnapshot: TSimdRuntimeSnapshot;
begin
  LCanonicalSnapshot := fafafa.core.simd.runtime.GetCurrentRuntimeSnapshot;
  LLegacySnapshot := fafafa.core.simd.runtime.GetCurrentSimdRuntimeSnapshot;

  AssertEquals('runtime snapshot canonical getter should match legacy alias current backend',
    Ord(LLegacySnapshot.CurrentBackend), Ord(LCanonicalSnapshot.CurrentBackend));
  AssertEquals('runtime snapshot canonical getter should match legacy alias backend info backend',
    Ord(LLegacySnapshot.CurrentBackendInfo.Backend), Ord(LCanonicalSnapshot.CurrentBackendInfo.Backend));
  AssertEquals('runtime snapshot canonical getter should match legacy alias backend info name',
    LLegacySnapshot.CurrentBackendInfo.Name, LCanonicalSnapshot.CurrentBackendInfo.Name);
  AssertEquals('runtime snapshot canonical getter should match legacy alias backend info description',
    LLegacySnapshot.CurrentBackendInfo.Description, LCanonicalSnapshot.CurrentBackendInfo.Description);
  AssertEquals('runtime snapshot canonical getter should match legacy alias backend info availability',
    LLegacySnapshot.CurrentBackendInfo.Available, LCanonicalSnapshot.CurrentBackendInfo.Available);
  AssertEquals('runtime snapshot canonical getter should match legacy alias backend info priority',
    LLegacySnapshot.CurrentBackendInfo.Priority, LCanonicalSnapshot.CurrentBackendInfo.Priority);
  AssertTrue('runtime snapshot canonical getter should match legacy alias backend info capabilities',
    LLegacySnapshot.CurrentBackendInfo.Capabilities = LCanonicalSnapshot.CurrentBackendInfo.Capabilities);
  AssertBackendArrayEquals('runtime snapshot canonical getter should match legacy alias registered backends',
    LLegacySnapshot.RegisteredBackends, LCanonicalSnapshot.RegisteredBackends);
  AssertBackendArrayEquals('runtime snapshot canonical getter should match legacy alias dispatchable backends',
    LLegacySnapshot.DispatchableBackends, LCanonicalSnapshot.DispatchableBackends);
  AssertEquals('runtime snapshot canonical getter should match legacy alias best dispatchable backend',
    Ord(LLegacySnapshot.BestDispatchableBackend), Ord(LCanonicalSnapshot.BestDispatchableBackend));
end;

procedure TTestCase_RuntimeAPI.Test_FacadeRuntimeSnapshot_View_Matches_Runtime_Subunit;
var
  LFacadeSnapshot: TSimdRuntimeSnapshot;
  LRuntimeSnapshot: TSimdRuntimeSnapshot;
begin
  LFacadeSnapshot := fafafa.core.simd.GetCurrentRuntimeSnapshot;
  LRuntimeSnapshot := fafafa.core.simd.runtime.GetCurrentRuntimeSnapshot;

  AssertEquals('facade runtime snapshot current backend should match runtime subunit snapshot',
    Ord(LRuntimeSnapshot.CurrentBackend), Ord(LFacadeSnapshot.CurrentBackend));
  AssertEquals('facade runtime snapshot backend info backend should match runtime subunit snapshot',
    Ord(LRuntimeSnapshot.CurrentBackendInfo.Backend), Ord(LFacadeSnapshot.CurrentBackendInfo.Backend));
  AssertEquals('facade runtime snapshot backend info name should match runtime subunit snapshot',
    LRuntimeSnapshot.CurrentBackendInfo.Name, LFacadeSnapshot.CurrentBackendInfo.Name);
  AssertEquals('facade runtime snapshot backend info description should match runtime subunit snapshot',
    LRuntimeSnapshot.CurrentBackendInfo.Description, LFacadeSnapshot.CurrentBackendInfo.Description);
  AssertEquals('facade runtime snapshot backend info availability should match runtime subunit snapshot',
    LRuntimeSnapshot.CurrentBackendInfo.Available, LFacadeSnapshot.CurrentBackendInfo.Available);
  AssertEquals('facade runtime snapshot backend info priority should match runtime subunit snapshot',
    LRuntimeSnapshot.CurrentBackendInfo.Priority, LFacadeSnapshot.CurrentBackendInfo.Priority);
  AssertTrue('facade runtime snapshot backend info capabilities should match runtime subunit snapshot',
    LRuntimeSnapshot.CurrentBackendInfo.Capabilities = LFacadeSnapshot.CurrentBackendInfo.Capabilities);
  AssertBackendArrayEquals('facade runtime snapshot registered backends should match runtime subunit snapshot',
    LRuntimeSnapshot.RegisteredBackends, LFacadeSnapshot.RegisteredBackends);
  AssertBackendArrayEquals('facade runtime snapshot dispatchable backends should match runtime subunit snapshot',
    LRuntimeSnapshot.DispatchableBackends, LFacadeSnapshot.DispatchableBackends);
  AssertEquals('facade runtime snapshot best dispatchable backend should match runtime subunit snapshot',
    Ord(LRuntimeSnapshot.BestDispatchableBackend), Ord(LFacadeSnapshot.BestDispatchableBackend));
end;

procedure TTestCase_RuntimeAPI.Test_FacadeRuntimeControlPlane_Wrappers_Interoperate_With_Legacy_Aliases;
var
  LOriginalBackend: TSimdBackend;
  LOriginalBestDispatchable: TSimdBackend;
begin
  LOriginalBackend := fafafa.core.simd.GetCurrentBackend;
  LOriginalBestDispatchable := fafafa.core.simd.GetBestDispatchableBackend;
  try
    AssertTrue('facade TrySetCurrentBackend(sbScalar) should succeed',
      fafafa.core.simd.TrySetCurrentBackend(sbScalar));
    AssertEquals('runtime subunit getter should track facade TrySetCurrentBackend',
      Ord(sbScalar), Ord(fafafa.core.simd.runtime.GetCurrentBackend));
    AssertEquals('facade runtime snapshot should track facade TrySetCurrentBackend',
      Ord(sbScalar), Ord(fafafa.core.simd.GetCurrentRuntimeSnapshot.CurrentBackend));

    fafafa.core.simd.ResetBackendSelection;
    AssertEquals('legacy ResetBackendSelection should restore best dispatchable backend after facade TrySetCurrentBackend',
      Ord(fafafa.core.simd.GetBestDispatchableBackend), Ord(fafafa.core.simd.GetCurrentBackend));

    fafafa.core.simd.ForceBackend(sbScalar);
    AssertEquals('facade GetCurrentBackend should track legacy ForceBackend',
      Ord(sbScalar), Ord(fafafa.core.simd.GetCurrentBackend));
    AssertEquals('facade runtime snapshot should track legacy ForceBackend',
      Ord(sbScalar), Ord(fafafa.core.simd.GetCurrentRuntimeSnapshot.CurrentBackend));

    fafafa.core.simd.ResetCurrentBackendSelection;
    AssertEquals('facade ResetCurrentBackendSelection should restore best dispatchable backend after legacy ForceBackend',
      Ord(fafafa.core.simd.GetBestDispatchableBackend), Ord(fafafa.core.simd.GetCurrentBackend));
  finally
    if LOriginalBackend = LOriginalBestDispatchable then
      fafafa.core.simd.ResetCurrentBackendSelection
    else
      AssertTrue('facade wrappers should restore original forced backend',
        fafafa.core.simd.TrySetCurrentBackend(LOriginalBackend));
  end;
end;

procedure TTestCase_RuntimeAPI.Test_RuntimeSnapshot_View_Matches_Runtime_And_Legacy_Helpers;
var
  LSnapshot: TSimdRuntimeSnapshot;
  LDispatch: PSimdDispatchTable;
begin
  LSnapshot := fafafa.core.simd.runtime.GetCurrentRuntimeSnapshot;
  LDispatch := GetDispatchTable;

  AssertTrue('GetDispatchTable should be assigned', LDispatch <> nil);
  AssertEquals('runtime snapshot current backend should match runtime getter',
    Ord(fafafa.core.simd.runtime.GetCurrentBackend), Ord(LSnapshot.CurrentBackend));
  AssertEquals('runtime snapshot current backend should match legacy facade getter',
    Ord(fafafa.core.simd.GetCurrentBackend), Ord(LSnapshot.CurrentBackend));
  AssertEquals('runtime snapshot current backend should match dispatch snapshot backend',
    Ord(LDispatch^.Backend), Ord(LSnapshot.CurrentBackend));

  AssertEquals('runtime snapshot backend info backend should match snapshot backend',
    Ord(LSnapshot.CurrentBackend), Ord(LSnapshot.CurrentBackendInfo.Backend));
  AssertEquals('runtime snapshot backend info name should match runtime getter',
    fafafa.core.simd.runtime.GetCurrentBackendInfo.Name, LSnapshot.CurrentBackendInfo.Name);
  AssertEquals('runtime snapshot backend info description should match runtime getter',
    fafafa.core.simd.runtime.GetCurrentBackendInfo.Description, LSnapshot.CurrentBackendInfo.Description);
  AssertEquals('runtime snapshot backend info availability should match runtime getter',
    fafafa.core.simd.runtime.GetCurrentBackendInfo.Available, LSnapshot.CurrentBackendInfo.Available);
  AssertEquals('runtime snapshot backend info priority should match runtime getter',
    fafafa.core.simd.runtime.GetCurrentBackendInfo.Priority, LSnapshot.CurrentBackendInfo.Priority);
  AssertTrue('runtime snapshot backend info capabilities should match runtime getter',
    LSnapshot.CurrentBackendInfo.Capabilities = fafafa.core.simd.runtime.GetCurrentBackendInfo.Capabilities);

  AssertBackendArrayEquals('runtime snapshot registered backends should match runtime getter',
    fafafa.core.simd.runtime.GetRegisteredBackendList, LSnapshot.RegisteredBackends);
  AssertBackendArrayEquals('runtime snapshot dispatchable backends should match runtime getter',
    fafafa.core.simd.runtime.GetDispatchableBackendList, LSnapshot.DispatchableBackends);
  AssertEquals('runtime snapshot best dispatchable backend should match runtime getter',
    Ord(fafafa.core.simd.runtime.GetBestDispatchableBackend),
    Ord(LSnapshot.BestDispatchableBackend));
end;

procedure TTestCase_RuntimeAPI.Test_RuntimeSnapshot_Switch_Tracks_ControlPlane_And_Dispatch;
var
  LSnapshot: TSimdRuntimeSnapshot;
  LOriginalBackend: TSimdBackend;
begin
  LOriginalBackend := fafafa.core.simd.runtime.GetCurrentBackend;
  try
    AssertTrue('TrySetCurrentBackend(sbScalar) should succeed in runtime snapshot test',
      fafafa.core.simd.runtime.TrySetCurrentBackend(sbScalar));

    LSnapshot := fafafa.core.simd.runtime.GetCurrentRuntimeSnapshot;
    AssertEquals('runtime snapshot current backend should switch to Scalar',
      Ord(sbScalar), Ord(LSnapshot.CurrentBackend));
    AssertEquals('runtime snapshot backend info backend should switch to Scalar',
      Ord(sbScalar), Ord(LSnapshot.CurrentBackendInfo.Backend));
    AssertEquals('runtime snapshot should match dispatch snapshot backend after switch',
      Ord(GetDispatchTable^.Backend), Ord(LSnapshot.CurrentBackend));
    AssertEquals('runtime snapshot should match runtime getter after switch',
      Ord(fafafa.core.simd.runtime.GetCurrentBackend), Ord(LSnapshot.CurrentBackend));

    fafafa.core.simd.runtime.ResetCurrentBackendSelection;
    LSnapshot := fafafa.core.simd.runtime.GetCurrentRuntimeSnapshot;
    AssertEquals('runtime snapshot reset should restore automatic current backend',
      Ord(fafafa.core.simd.runtime.GetBestDispatchableBackend), Ord(LSnapshot.CurrentBackend));
    AssertEquals('runtime snapshot should match dispatch snapshot backend after reset',
      Ord(GetDispatchTable^.Backend), Ord(LSnapshot.CurrentBackend));
    AssertEquals('runtime snapshot backend info backend should match reset backend',
      Ord(LSnapshot.CurrentBackend), Ord(LSnapshot.CurrentBackendInfo.Backend));
  finally
    if fafafa.core.simd.runtime.GetCurrentBackend <> LOriginalBackend then
      AssertTrue('runtime snapshot test should restore original backend',
        fafafa.core.simd.runtime.TrySetCurrentBackend(LOriginalBackend));
  end;
end;

initialization
  RegisterTest(TTestCase_RuntimeAPI);

end.
