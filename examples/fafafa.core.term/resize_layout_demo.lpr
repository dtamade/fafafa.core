program resize_layout_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term,
  ui_buffer_utils, fafafa.core.signal;

procedure OnWinch(const S: TSignal);
begin
  if S = sgWinch then
  begin
    WinchPending := True;
    WinchLastTs := GetTickCount64;
  end;
end;

procedure WinchAttach(out aToken: Int64; aQueueCapacity: Integer);
var C: ISignalCenter;
begin
  C := SignalCenter;
  C.Start;
  if aQueueCapacity > 0 then
    C.ConfigureQueue(aQueueCapacity, qdpDropOldest);
  aToken := C.Subscribe([sgWinch], @OnWinch);
end;

procedure WinchDetach(var aToken: Int64);
var C: ISignalCenter;
begin
  if aToken <> 0 then
  begin
    C := SignalCenter;
    C.Unsubscribe(aToken);
    aToken := 0;
  end;
end;

function WinchTickDebounced(var aPending: Boolean; var aLastTs: QWord; aDebounceMs: Cardinal; out aNewW, aNewH: Integer): Boolean;
var nowTs: QWord;
begin
  Result := False;
  aNewW := 0; aNewH := 0;
  if not aPending then Exit;
  nowTs := GetTickCount64;
  if (nowTs - aLastTs >= aDebounceMs) then
  begin
    aPending := False;
    // 读取最新尺寸；失败也返回 True 让上层尝试重绘/恢复
    if not term_size(aNewW, aNewH) then
    begin
      aNewW := 0; aNewH := 0;
    end;
    Result := True;
  end;
end;

procedure DrawGrid;
var W,H,x,y: term_size_t;
begin
  if not term_size(W,H) then
  begin
    term_writeln('无法获取终端大小');
    Exit;
  end;
  term_clear;
  for y := 0 to H-1 do
  begin
    term_cursor_set(0, y);
    for x := 0 to W-1 do
    begin
      if (x mod 10 = 0) or (y mod 5 = 0) then
        term_write('+')
      else
        term_write(' ');
    end;
  end;
  term_cursor_set(0, H);
  term_writeln(Format('Size: %dx%d  (按 r 重绘；按 q 退出)', [W,H]));
end;

var
  E: term_event_t; running: Boolean;
  // WINCH 处理（统一示例封装）
  WinchTok: Int64 = 0;
  WinchPending: Boolean = False;
  WinchLastTs: QWord = 0;


  NewW, NewH: Integer;
begin
  if not term_init then
  begin
    WriteLn('term_init 失败');
    Halt(1);
  end;

  // 订阅 WINCH，设置队列策略（抖动场景丢最旧）
  WinchAttach(WinchTok, 256);

  DrawGrid;
  running := True;
  while running do
  begin

    // 帧内：以 16ms 去抖合并 WINCH，并按需重绘
    if WinchTickDebounced(WinchPending, WinchLastTs, 16, NewW, NewH) then
    begin
      DrawGrid;
    end;

        // 注：tek_sizeChange 仍即时触发；WinchTickDebounced 用于帧内合并与补偿

    if term_event_poll(E, 500) then
    begin
      case E.kind of
        tek_sizeChange: DrawGrid;
        tek_key:
          begin
            case E.key.key of
              KEY_Q: running := False;
              KEY_R: DrawGrid;
            else
              ;
            end;
          end;
        else
          ;
      end;
    end;
  end;

  // 释放 WINCH 订阅并清理
  WinchDetach(WinchTok);
  term_done;
end.

