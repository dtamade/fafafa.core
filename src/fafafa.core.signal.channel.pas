unit fafafa.core.signal.channel;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.signal, fafafa.core.thread.channel;

// 轻量 Channel 风格包装：将信号投递到有界/无界通道，便于 Go 风格使用
// 默认容量=0（配对），可指定容量构造有界缓冲

type
  TSignalChannel = class
  private
    FChan: IChannel; // 复用线程通道（指针值承载信号枚举）
    FToken: Int64;
    FCenter: ISignalCenter;
    class function PtrOfSig(const S: TSignal): Pointer; static; inline;
    class function SigOfPtr(const P: Pointer): TSignal; static; inline;
  public
    constructor Create(const Sigs: TSignalSet; aCapacity: Integer = 0);
    destructor Destroy; override;
    // 接收：阻塞直到取到信号
    function Recv(out Sig: TSignal): Boolean;
    function RecvTimeout(out Sig: TSignal; TimeoutMs: Cardinal): Boolean;
    // 关闭
    procedure Close;
  end;

implementation

class function TSignalChannel.PtrOfSig(const S: TSignal): Pointer;
begin
  Result := Pointer(PtrUInt(Ord(S)));
end;

class function TSignalChannel.SigOfPtr(const P: Pointer): TSignal;
begin
  Result := TSignal(PtrUInt(P));
end;

constructor TSignalChannel.Create(const Sigs: TSignalSet; aCapacity: Integer);
begin
  inherited Create;
  FChan := TChannel.Create(aCapacity);
  FCenter := SignalCenter;
  FCenter.Start;
  FToken := FCenter.Subscribe(Sigs,
    procedure (const Sig: TSignal)
    begin
      // 尽可能非阻塞：SendTimeout 0ms；若无缓冲且无等待者，放弃该事件（上层可选择更大缓冲或单独处理）
      if not FChan.SendTimeout(PtrOfSig(Sig), 0) then
      begin
        // 丢弃；可考虑计数或日志，但库默认不写 stdout
      end;
    end
  );
end;

destructor TSignalChannel.Destroy;
begin
  try
    if Assigned(FCenter) and (FToken <> 0) then FCenter.Unsubscribe(FToken);
  finally
    FChan := nil;
    inherited Destroy;
  end;
end;

function TSignalChannel.Recv(out Sig: TSignal): Boolean;
var P: Pointer;
begin
  Result := FChan.Recv(P);
  if Result then Sig := SigOfPtr(P);
end;

function TSignalChannel.RecvTimeout(out Sig: TSignal; TimeoutMs: Cardinal): Boolean;
var P: Pointer;
begin
  Result := FChan.RecvTimeout(P, TimeoutMs);
  if Result then Sig := SigOfPtr(P);
end;

procedure TSignalChannel.Close;
begin
  if Assigned(FCenter) and (FToken <> 0) then
  begin
    FCenter.Unsubscribe(FToken);
    FToken := 0;
  end;
  if Assigned(FChan) then FChan.Close;
end;

end.

