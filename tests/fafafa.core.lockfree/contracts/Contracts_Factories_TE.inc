{ TE（类型擦除）版接口契约工厂声明（扩展：批量与能力查询） }

{$IFNDEF Contracts_Factories_TE_Included}
{$DEFINE Contracts_Factories_TE_Included}



type
  { 约定：最小方法集 + 可选批量/能力查询，若不支持返回安全默认值 }

  IQueueInt = interface
    ['{E6E01B5A-4204-4E48-B3C0-1F4D4838B1A7}']
    // 基本
    function Enqueue(AValue: Integer): Boolean;
    function TryDequeue(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;     // 不支持时返回 -1
    function Bounded: Boolean;
    // 批量（不支持则退化为循环）
    function EnqueueMany(const Values: array of Integer): Integer;
    function DequeueMany(var Values: array of Integer): Integer;
    // 清空（不支持则退化为消费至空）
    procedure Clear;
    // Stats（不支持则返回 False/0）
    function HasStats: Boolean;
  end;

  IStackInt = interface
    ['{E4A5C5B4-2879-4A31-B4D2-E6C0B6972D28}']
    // 基本
    function Push(AValue: Integer): Boolean;  // 不支持失败时返回 True（Treiber）
    function TryPop(out AValue: Integer): Boolean;
    function TryPeek(out AValue: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;     // 不支持时返回 -1
    function Bounded: Boolean;
    // 批量（不支持则退化为循环）
    function PushMany(const Values: array of Integer): Integer;
    function PopMany(var Values: array of Integer): Integer;
    // 清空（不支持则退化为消费至空）
    procedure Clear;
    // Stats（不支持则返回 False）
    function HasStats: Boolean;
  end;

  IMapIntStr = interface
    ['{A1FC6B10-0D60-45A5-A98A-96A7B2C3A9F5}']
    // 基本
    function Put(AKey: Integer; const AValue: string; out Replaced: Boolean): Boolean;
    function TryGetValue(AKey: Integer; out AValue: string): Boolean;
    function Remove(AKey: Integer; out OldValue: string): Boolean;
    function ContainsKey(AKey: Integer): Boolean;
    procedure Clear;
    function Size: SizeInt;
    // 能力查询（不支持返回 -1 或 False）
    function LoadFactorTimes1000: Integer; // 近似值*1000，-1 不支持
    function BucketCount: Integer;         // -1 不支持
    function MaxLoadFactorTimes1000: Integer; // -1 不支持
    function SetMaxLoadFactorTimes1000(Value: Integer): Boolean; // 不支持返回 False
  end;

  IQueueFactory_Integer = interface
    ['{7F46F8DD-8C5F-49B4-97C5-1E6C7B0D9C10}']
    function MakeSPSC(const ACapacity: SizeInt): IQueueInt;
    function MakeMPSC: IQueueInt;
    function MakeMPMC(const ACapacity: SizeInt): IQueueInt;
  end;

  IStackFactory_Integer = interface
    ['{0D937C1E-1C6A-4F1C-8DF0-BC376FDC7446}']
    function MakeTreiber: IStackInt;
    function MakePreAlloc(const ACapacity: SizeInt): IStackInt;
  end;

  IMapFactory_IntStr = interface
    ['{A2A8B2E5-3B2C-4E78-9F2A-1B2B28F8A0B7}']
    function MakeOA(const ACapacity: SizeInt): IMapIntStr;
    function MakeMM(const ABucketCount: SizeInt): IMapIntStr;
  end;

{$ENDIF}

