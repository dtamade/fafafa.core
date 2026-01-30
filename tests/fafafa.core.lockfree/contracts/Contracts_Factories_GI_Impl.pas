unit Contracts_Factories_GI_Impl;


{$mode objfpc}{$H+}

{ GI（泛型接口）契约工厂实现（基于 TE 包装的桥接），仅用于 FPC 3.3.1+ 的契约实验 }

interface

uses
  SysUtils, Classes;

{$I Contracts_Factories_GI.inc}

{$IF FPC_FULLVERSION >= 030301}

function GetGIQueueFactory_Integer: IQueueGIFactory_Integer;
function GetGIStackFactory_Integer: IStackGIFactory_Integer;
function GetGIMapFactory_IntStr: IMapGIFactory_IntStr;

{$ENDIF}

implementation

{$IF FPC_FULLVERSION >= 030301}

{$I ../contracts/Contracts_Factories_TE.inc}
uses Contracts_Factories_TE_Clean;

type
  // 基于 TE 的桥接实现，避免重复逻辑
  TQueueGI_FromTE = class(TInterfacedObject, specialize IQueueGI<Integer>)
  private
    Q: IQueueInt;
  public
    constructor Create(const AQ: IQueueInt);
    function Enqueue(constref Item: Integer): Boolean;
    function TryDequeue(out Item: Integer): Boolean;
    function TryPeek(out Item: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
  end;

  TStackGI_FromTE = class(TInterfacedObject, specialize IStackGI<Integer>)
  private
    S: IStackInt;
  public
    constructor Create(const AS: IStackInt);
    function Push(constref Item: Integer): Boolean;
    function TryPop(out Item: Integer): Boolean;
    function TryPeek(out Item: Integer): Boolean;
    function IsEmpty: Boolean;
    function Size: SizeInt;
    function Capacity: SizeInt;
    function Bounded: Boolean;
  end;

  TMapGI_FromTE = class(TInterfacedObject, specialize IMapGI<Integer,string>)
  private
    M: IMapIntStr;
  public
    constructor Create(const AM: IMapIntStr);
    function Put(constref K: Integer; constref V: string; out Replaced: Boolean): Boolean;
    function TryGetValue(constref K: Integer; out V: string): Boolean;
    function Remove(constref K: Integer; out OldValue: string): Boolean;
    function ContainsKey(constref K: Integer): Boolean;
    procedure Clear;
    function Size: SizeInt;
  end;

{ TQueueGI_FromTE }
constructor TQueueGI_FromTE.Create(const AQ: IQueueInt); begin inherited Create; Q := AQ; end;
function TQueueGI_FromTE.Enqueue(constref Item: Integer): Boolean; begin Result := Q.Enqueue(Item); end;
function TQueueGI_FromTE.TryDequeue(out Item: Integer): Boolean; begin Result := Q.TryDequeue(Item); end;
function TQueueGI_FromTE.TryPeek(out Item: Integer): Boolean; begin Result := Q.TryPeek(Item); end;
function TQueueGI_FromTE.IsEmpty: Boolean; begin Result := Q.IsEmpty; end;
function TQueueGI_FromTE.Size: SizeInt; begin Result := Q.Size; end;
function TQueueGI_FromTE.Capacity: SizeInt; begin Result := Q.Capacity; end;
function TQueueGI_FromTE.Bounded: Boolean; begin Result := Q.Bounded; end;

{ TStackGI_FromTE }
constructor TStackGI_FromTE.Create(const AS: IStackInt); begin inherited Create; S := AS; end;
function TStackGI_FromTE.Push(constref Item: Integer): Boolean; begin Result := S.Push(Item); end;
function TStackGI_FromTE.TryPop(out Item: Integer): Boolean; begin Result := S.TryPop(Item); end;
function TStackGI_FromTE.TryPeek(out Item: Integer): Boolean; begin Result := S.TryPeek(Item); end;
function TStackGI_FromTE.IsEmpty: Boolean; begin Result := S.IsEmpty; end;
function TStackGI_FromTE.Size: SizeInt; begin Result := S.Size; end;
function TStackGI_FromTE.Capacity: SizeInt; begin Result := S.Capacity; end;
function TStackGI_FromTE.Bounded: Boolean; begin Result := S.Bounded; end;

{ TMapGI_FromTE }
constructor TMapGI_FromTE.Create(const AM: IMapIntStr); begin inherited Create; M := AM; end;
function TMapGI_FromTE.Put(constref K: Integer; constref V: string; out Replaced: Boolean): Boolean; begin Result := M.Put(K, V, Replaced); end;
function TMapGI_FromTE.TryGetValue(constref K: Integer; out V: string): Boolean; begin Result := M.TryGetValue(K, V); end;
function TMapGI_FromTE.Remove(constref K: Integer; out OldValue: string): Boolean; begin Result := M.Remove(K, OldValue); end;
function TMapGI_FromTE.ContainsKey(constref K: Integer): Boolean; begin Result := M.ContainsKey(K); end;
procedure TMapGI_FromTE.Clear; begin M.Clear; end;
function TMapGI_FromTE.Size: SizeInt; begin Result := M.Size; end;

type
  TQueueGIFactory_Integer = class(TInterfacedObject, IQueueGIFactory_Integer)
  public
    function MakeSPSC(const ACapacity: SizeInt): specialize IQueueGI<Integer>;
    function MakeMPSC: specialize IQueueGI<Integer>;
    function MakeMPMC(const ACapacity: SizeInt): specialize IQueueGI<Integer>;
  end;

  TStackGIFactory_Integer = class(TInterfacedObject, IStackGIFactory_Integer)
  public
    function MakeTreiber: specialize IStackGI<Integer>;
    function MakePreAlloc(const ACapacity: SizeInt): specialize IStackGI<Integer>;
  end;

  TMapGIFactory_IntStr = class(TInterfacedObject, IMapGIFactory_IntStr)
  public
    function MakeOA(const ACapacity: SizeInt): specialize IMapGI<Integer,string>;
    function MakeMM(const ABucketCount: SizeInt): specialize IMapGI<Integer,string>;
  end;

function TQueueGIFactory_Integer.MakeSPSC(const ACapacity: SizeInt): specialize IQueueGI<Integer>;
begin
  Result := TQueueGI_FromTE.Create(GetDefaultQueueFactory_Integer_TE.MakeSPSC(ACapacity));
end;

function TQueueGIFactory_Integer.MakeMPSC: specialize IQueueGI<Integer>;
begin
  Result := TQueueGI_FromTE.Create(GetDefaultQueueFactory_Integer_TE.MakeMPSC);
end;

function TQueueGIFactory_Integer.MakeMPMC(const ACapacity: SizeInt): specialize IQueueGI<Integer>;
begin
  Result := TQueueGI_FromTE.Create(GetDefaultQueueFactory_Integer_TE.MakeMPMC(ACapacity));
end;

function TStackGIFactory_Integer.MakeTreiber: specialize IStackGI<Integer>;
begin
  Result := TStackGI_FromTE.Create(GetDefaultStackFactory_Integer_TE.MakeTreiber);
end;

function TStackGIFactory_Integer.MakePreAlloc(const ACapacity: SizeInt): specialize IStackGI<Integer>;
begin
  Result := TStackGI_FromTE.Create(GetDefaultStackFactory_Integer_TE.MakePreAlloc(ACapacity));
end;

function TMapGIFactory_IntStr.MakeOA(const ACapacity: SizeInt): specialize IMapGI<Integer,string>;
begin
  Result := TMapGI_FromTE.Create(GetDefaultMapFactory_IntStr_TE.MakeOA(ACapacity));
end;

function TMapGIFactory_IntStr.MakeMM(const ABucketCount: SizeInt): specialize IMapGI<Integer,string>;
begin
  Result := TMapGI_FromTE.Create(GetDefaultMapFactory_IntStr_TE.MakeMM(ABucketCount));
end;

function GetGIQueueFactory_Integer: IQueueGIFactory_Integer;
begin
  Result := TQueueGIFactory_Integer.Create;
end;

function GetGIStackFactory_Integer: IStackGIFactory_Integer;
begin
  Result := TStackGIFactory_Integer.Create;
end;

function GetGIMapFactory_IntStr: IMapGIFactory_IntStr;
begin
  Result := TMapGIFactory_IntStr.Create;
end;

{$ENDIF}

end.

