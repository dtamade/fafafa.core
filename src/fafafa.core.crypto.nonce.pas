{
  fafafa.core.crypto.nonce - 简易 Nonce 管理器（计数器/去重）

  注意：本实现为示例性质，未做并发保护。如需跨线程使用，请在外层加锁或封装线程安全版本。
}
unit fafafa.core.crypto.nonce;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils;

type
  TBytes = array of Byte;

  INonceManager = interface
    ['{F0D61C75-1F9F-4E39-A5A4-9C364F8C8E90}']
    // 计数器策略：返回 12 字节 GCM Nonce（InstanceID || Counter，大端），并自增内部计数器
    function NextGCMNonce12: TBytes;
    // 随机策略：生成 12 字节随机 Nonce，并在内部历史中去重（发生极低概率碰撞时重试）
    function GenerateUniqueRandomNonce12: TBytes;
    // 将 Nonce 标记到历史中；若已存在返回 True，否则返回 False 并加入
    function SeenAndAdd(const ANonce: TBytes): Boolean;

    // 基本属性
    function GetInstanceID: UInt32;
    procedure SetInstanceID(AValue: UInt32);
    function GetCounter: UInt64;
    procedure SetCounter(AValue: UInt64);
    function GetHistorySize: Integer;
    procedure SetHistorySize(AValue: Integer);
    procedure ClearHistory;

    property InstanceID: UInt32 read GetInstanceID write SetInstanceID;
    property Counter: UInt64 read GetCounter write SetCounter;
    property HistorySize: Integer read GetHistorySize write SetHistorySize;
  end;

// 工厂函数（供门面转发调用）
function CreateNonceManager_Impl(AInstanceID: UInt32 = 0; ACounterStart: UInt64 = 0; AHistorySize: Integer = 1024): INonceManager;
// 线程安全版本工厂（内部使用临界区保护）
function CreateNonceManagerThreadSafe_Impl(AInstanceID: UInt32 = 0; ACounterStart: UInt64 = 0; AHistorySize: Integer = 1024): INonceManager;

implementation

uses
  fafafa.core.crypto,          // BytesToHex, GenerateNonce12, ComposeGCMNonce12
  SyncObjs;                    // TCriticalSection

type
  TNonceManager = class(TInterfacedObject, INonceManager)
  private
    FInstanceID: UInt32;
    FCounter: UInt64;
    FHistory: TStringList;   // 简易去重：线性查找 + FIFO 截断
    FMaxHistory: Integer;
  private
    function HexOf(const B: TBytes): string;
    procedure AddToHistory(const Hex: string);
  public
    constructor Create(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer);
    destructor Destroy; override;

    // INonceManager
    function NextGCMNonce12: TBytes;
    function GenerateUniqueRandomNonce12: TBytes;
    function SeenAndAdd(const ANonce: TBytes): Boolean;

    function GetInstanceID: UInt32;
    procedure SetInstanceID(AValue: UInt32);
    function GetCounter: UInt64;
    procedure SetCounter(AValue: UInt64);
    function GetHistorySize: Integer;
    procedure SetHistorySize(AValue: Integer);
    procedure ClearHistory;
  end;


  TNonceManagerTS = class(TInterfacedObject, INonceManager)
  private
    FInner: TNonceManager;
    FLock: TCriticalSection;
  private
    function HexOf(const B: TBytes): string;
  public
    constructor Create(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer);
    destructor Destroy; override;

    // INonceManager
    function NextGCMNonce12: TBytes;
    function GenerateUniqueRandomNonce12: TBytes;
    function SeenAndAdd(const ANonce: TBytes): Boolean;

    function GetInstanceID: UInt32;
    procedure SetInstanceID(AValue: UInt32);
    function GetCounter: UInt64;
    procedure SetCounter(AValue: UInt64);
    function GetHistorySize: Integer;
    procedure SetHistorySize(AValue: Integer);
    procedure ClearHistory;
  end;

{ TNonceManager }

constructor TNonceManager.Create(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer);
begin
  inherited Create;
  FInstanceID := AInstanceID;
  FCounter := ACounterStart;
  FHistory := TStringList.Create;
  FHistory.Sorted := False;     // 简化：线性去重
  FHistory.Duplicates := dupIgnore;
  if AHistorySize <= 0 then
    FMaxHistory := 1024
  else
    FMaxHistory := AHistorySize;
end;

destructor TNonceManager.Destroy;
begin
  FHistory.Free;
  inherited Destroy;
end;

function TNonceManager.HexOf(const B: TBytes): string;
begin
  Result := fafafa.core.crypto.BytesToHex(B);
end;

procedure TNonceManager.AddToHistory(const Hex: string);
begin
  // FIFO：超过限制则删最早加入的（index 0）
  if FHistory.Count >= FMaxHistory then
    FHistory.Delete(0);
  FHistory.Add(Hex);
end;

function TNonceManager.NextGCMNonce12: TBytes;
begin
  Result := fafafa.core.crypto.ComposeGCMNonce12(FInstanceID, FCounter);
  Inc(FCounter);
  // 计数策略通常无需历史去重，因为计数器单调递增；若需要可自行调用 SeenAndAdd(Result)
end;

function TNonceManager.GenerateUniqueRandomNonce12: TBytes;
var
  LHex: string;
  LTry: Integer;
begin
  for LTry := 0 to 3 do
  begin
    Result := fafafa.core.crypto.GenerateNonce12;
    LHex := HexOf(Result);
    if FHistory.IndexOf(LHex) < 0 then
    begin
      AddToHistory(LHex);
      Exit;
    end;
  end;
  raise EInvalidOperation.Create('Failed to generate unique random nonce after retries');
end;

function TNonceManager.SeenAndAdd(const ANonce: TBytes): Boolean;
var
  LHex: string;
  LIdx: Integer;
begin
  LHex := HexOf(ANonce);
  LIdx := FHistory.IndexOf(LHex);
  Result := LIdx >= 0;
  if not Result then
    AddToHistory(LHex);
end;

function TNonceManager.GetInstanceID: UInt32;
begin
  Result := FInstanceID;
end;

procedure TNonceManager.SetInstanceID(AValue: UInt32);
begin
  FInstanceID := AValue;
end;

function TNonceManager.GetCounter: UInt64;
begin
  Result := FCounter;
end;

procedure TNonceManager.SetCounter(AValue: UInt64);
begin

  FCounter := AValue;
end;

{ TNonceManagerTS }

constructor TNonceManagerTS.Create(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer);
begin
  inherited Create;
  FInner := TNonceManager.Create(AInstanceID, ACounterStart, AHistorySize);
  FLock := TCriticalSection.Create;
end;

destructor TNonceManagerTS.Destroy;
begin
  FLock.Acquire;
  try
    FreeAndNil(FInner);
  finally
    FLock.Release;
  end;
  FLock.Free;
  inherited Destroy;
end;

function TNonceManagerTS.HexOf(const B: TBytes): string;
begin
  Result := fafafa.core.crypto.BytesToHex(B);
end;

function TNonceManagerTS.NextGCMNonce12: TBytes;
begin
  FLock.Acquire;
  try
    Result := FInner.NextGCMNonce12;
  finally
    FLock.Release;
  end;
end;

function TNonceManagerTS.GenerateUniqueRandomNonce12: TBytes;
begin
  FLock.Acquire;
  try
    Result := FInner.GenerateUniqueRandomNonce12;
  finally
    FLock.Release;
  end;
end;

function TNonceManagerTS.SeenAndAdd(const ANonce: TBytes): Boolean;
begin
  FLock.Acquire;
  try
    Result := FInner.SeenAndAdd(ANonce);
  finally
    FLock.Release;
  end;
end;

function TNonceManagerTS.GetInstanceID: UInt32;
begin
  FLock.Acquire;
  try
    Result := FInner.GetInstanceID;
  finally
    FLock.Release;
  end;
end;

procedure TNonceManagerTS.SetInstanceID(AValue: UInt32);
begin
  FLock.Acquire;
  try
    FInner.SetInstanceID(AValue);
  finally
    FLock.Release;
  end;
end;

function TNonceManagerTS.GetCounter: UInt64;
begin
  FLock.Acquire;
  try
    Result := FInner.GetCounter;
  finally
    FLock.Release;
  end;
end;

procedure TNonceManagerTS.SetCounter(AValue: UInt64);
begin
  FLock.Acquire;
  try
    FInner.SetCounter(AValue);
  finally
    FLock.Release;
  end;
end;

function TNonceManagerTS.GetHistorySize: Integer;
begin
  FLock.Acquire;
  try
    Result := FInner.GetHistorySize;
  finally
    FLock.Release;
  end;
end;

procedure TNonceManagerTS.SetHistorySize(AValue: Integer);
begin
  FLock.Acquire;
  try
    FInner.SetHistorySize(AValue);
  finally
    FLock.Release;
  end;
end;

procedure TNonceManagerTS.ClearHistory;
begin
  FLock.Acquire;
  try
    FInner.ClearHistory;
  finally
    FLock.Release;
  end;
end;

function CreateNonceManagerThreadSafe_Impl(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer): INonceManager;
begin
  Result := TNonceManagerTS.Create(AInstanceID, ACounterStart, AHistorySize);
end;

function TNonceManager.GetHistorySize: Integer;
begin
  Result := FMaxHistory;
end;

procedure TNonceManager.SetHistorySize(AValue: Integer);
begin
  if AValue <= 0 then
    FMaxHistory := 1024
  else
    FMaxHistory := AValue;
  // 可选择截断现有历史
  while (FHistory.Count > FMaxHistory) do
    FHistory.Delete(0);
end;

procedure TNonceManager.ClearHistory;
begin
  FHistory.Clear;
end;

function CreateNonceManager_Impl(AInstanceID: UInt32; ACounterStart: UInt64; AHistorySize: Integer): INonceManager;
begin
  Result := TNonceManager.Create(AInstanceID, ACounterStart, AHistorySize);
end;

end.

