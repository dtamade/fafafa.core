program example_winch_channel;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.term,
  fafafa.core.signal,
  fafafa.core.signal.channel;

procedure DrawSize;
var W,H: term_size_t;
begin
  if term_size(W,H) then
  begin
    term_clear;
    term_cursor_set(0, 0);
    term_writeln(Format('终端尺寸: %dx%d  (按 q 退出)', [W, H]));
  end
  else
  begin
    term_writeln('无法获取终端大小');
  end;
end;

var
  Running: Boolean;
  Ev: term_event_t;
  Ch: TSignalChannel;
  Sig: TSignal;
  C: ISignalCenter;
begin
  if not term_init then
  begin
    WriteLn('term_init 失败');
    Halt(1);
  end;

  // 建议：启动 SignalCenter 并设置 WINCH 去抖与队列策略
  C := SignalCenter;
  C.Start;
  C.ConfigureWinchDebounce(16);
  C.ConfigureQueue(256, qdpDropOldest);

  // 使用 Channel 风格订阅 WINCH；capacity=1 表示仅保留最新
  Ch := TSignalChannel.Create([sgWinch], 1);
  try
    DrawSize;
    Running := True;
    while Running do
    begin
      // 优先消费 WINCH（配对/背压语义）
      if Ch.RecvTimeout(Sig, 100) then
      begin
        if Sig = sgWinch then
          DrawSize;
      end;

      // 也允许处理键盘事件（q 退出）
      if term_event_poll(Ev, 0) then
      begin
        if Ev.kind = tek_key then
        begin
          case Ev.key.key of
            KEY_Q: Running := False;
          end;
        end;
      end;
    end;
  finally
    Ch.Free;
    term_done;
  end;
end.

