unit recorder_stub;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DateUtils;

type
  TRecordingState = (rsIdle, rsRecording, rsPaused, rsPlaying, rsPlayPaused);

  TRecordingFormat = (rfAsciiCast, rfJSON, rfBinary, rfCustom);

  TRecordedEventType = (
    retOutput, retInput, retResize, retMouse, retKeyboard, retCommand, retMarker, retMetadata
  );

  TRecordedEvent = record
    Timestamp: Double;  // seconds since session start
    EventType: TRecordedEventType;
    Data: string;       // payload
  end;

  TRecordingSession = record
    Version: Integer;
    Width: Integer;
    Height: Integer;
    Title: string;
    Command: string;
    Shell: string;
    TerminalType: string;
    Timestamp: TDateTime;   // start time
    Duration: Double;       // seconds
    Events: array of TRecordedEvent;
  end;

  TPlaybackOptions = record
    Speed: Double;       // 1.0 = realtime
    MaxDelay: Double;    // seconds cap per gap
    SkipIdle: Boolean;
    Loop: Boolean;
    ShowTimestamp: Boolean;
    ShowProgress: Boolean;
  end;

  TRecordEventCallback = procedure(const aEventType, aData: string; aTimestamp: Double) of object;
  TPlaybackEventCallback = procedure(const aEventType, aData: string; aTimestamp: Double) of object;

  TRecordingFormatArray = array of TRecordingFormat;

  ITerminalRecorder = interface(IInterface)
    ['{6C2C5C71-7C27-4E47-9B3E-3D9F6B2E6A77}']
    // lifecycle
    procedure StartRecording(const aTitle: string);
    procedure StopRecording;
    procedure PauseRecording;
    procedure ResumeRecording;

    // state
    function IsRecording: Boolean;
    function IsPlaying: Boolean;
    function GetRecordingState: TRecordingState;

    // record events
    procedure RecordOutput(const aData: string);
    procedure RecordMarker(const aTag, aData: string);
    procedure RecordResize(aWidth, aHeight: Integer);

    // session info
    function GetEventCount: Integer;
    function GetSessionDuration: Double;
    function GetPlaybackPosition: Double;
    function GetCurrentSession: TRecordingSession;

    // file ops
    function GetSupportedFormats: TRecordingFormatArray;
    procedure SaveRecording(const aFileName: string);
    function ImportRecording(const aFileName: string): Boolean;

    // playback
    procedure StartPlayback(const aFileName: string);
    procedure StopPlayback;
    function GetPlaybackOptions: TPlaybackOptions;

    // callbacks
    procedure SetRecordEventCallback(ACallback: TRecordEventCallback);
    procedure SetPlaybackEventCallback(ACallback: TPlaybackEventCallback);
  end;

function CreateSimpleRecorder: ITerminalRecorder;
function FormatTimestamp(const ASeconds: Double): string;
function FileSize(const FileName: string): Int64; // convenience for demo

implementation

type
  TSimpleTerminalRecorder = class(TInterfacedObject, ITerminalRecorder)
  private
    FState: TRecordingState;
    FStartDT: TDateTime;
    FStartTick: QWord;
    FPaused: Boolean;
    FPauseStart: QWord;
    FPausedAccum: QWord;
    FTitle: string;
    FWidth: Integer;
    FHeight: Integer;
    FEvents: array of TRecordedEvent;
    FOnRecord: TRecordEventCallback;
    FOnPlayback: TPlaybackEventCallback;
  private
    function ElapsedSeconds: Double;
    procedure AddEvent(AType: TRecordedEventType; const AData: string);
  public
    constructor Create;
    // lifecycle
    procedure StartRecording(const aTitle: string);
    procedure StopRecording;
    procedure PauseRecording;
    procedure ResumeRecording;

    // state
    function IsRecording: Boolean;
    function IsPlaying: Boolean;
    function GetRecordingState: TRecordingState;

    // record events
    procedure RecordOutput(const aData: string);
    procedure RecordMarker(const aTag, aData: string);
    procedure RecordResize(aWidth, aHeight: Integer);

    // session info
    function GetEventCount: Integer;
    function GetSessionDuration: Double;
    function GetPlaybackPosition: Double;
    function GetCurrentSession: TRecordingSession;

    // file ops
    function GetSupportedFormats: TRecordingFormatArray;
    procedure SaveRecording(const aFileName: string);
    function ImportRecording(const aFileName: string): Boolean;

    // playback
    procedure StartPlayback(const aFileName: string);
    procedure StopPlayback;
    function GetPlaybackOptions: TPlaybackOptions;

    // callbacks
    procedure SetRecordEventCallback(ACallback: TRecordEventCallback);
    procedure SetPlaybackEventCallback(ACallback: TPlaybackEventCallback);
  end;

function CreateSimpleRecorder: ITerminalRecorder;
begin
  Result := TSimpleTerminalRecorder.Create;
end;

function FormatTimestamp(const ASeconds: Double): string;
var
  S: Double;
begin
  if ASeconds < 0 then Exit('0.0s');
  S := ASeconds;
  if S < 60 then Exit(Format('%.1fs', [S]));
  Result := Format('%d:%05.2f', [Trunc(S/60), Frac(S/60)*60]);
end;

function FileSize(const FileName: string): Int64;
var
  FS: TFileStream;
begin
  Result := -1;
  if not SysUtils.FileExists(FileName) then Exit(-1);
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := FS.Size;
  finally
    FS.Free;
  end;
end;

{ TSimpleTerminalRecorder }

constructor TSimpleTerminalRecorder.Create;
begin
  FState := rsIdle;
  FWidth := 80; FHeight := 25;
  SetLength(FEvents, 0);
end;

function TSimpleTerminalRecorder.ElapsedSeconds: Double;
var
  nowTick: QWord;
begin
  if FState in [rsRecording, rsPaused] then
  begin
    nowTick := GetTickCount64;
    Result := (nowTick - FStartTick - FPausedAccum) / 1000.0;
  end
  else
    Result := 0.0;
end;

procedure TSimpleTerminalRecorder.AddEvent(AType: TRecordedEventType; const AData: string);
var
  E: TRecordedEvent;
  n: SizeInt;
begin
  E.Timestamp := ElapsedSeconds;
  E.EventType := AType;
  E.Data := AData;
  n := Length(FEvents);
  SetLength(FEvents, n+1);
  FEvents[n] := E;
  if Assigned(FOnRecord) then
    FOnRecord(IntToStr(Ord(AType)), AData, E.Timestamp);
end;

procedure TSimpleTerminalRecorder.StartRecording(const aTitle: string);
begin
  FTitle := aTitle;
  FStartDT := Now;
  FStartTick := GetTickCount64;
  FPausedAccum := 0;
  FPaused := False;
  SetLength(FEvents, 0);
  FState := rsRecording;
end;

procedure TSimpleTerminalRecorder.StopRecording;
begin
  if not (FState in [rsRecording, rsPaused]) then Exit;
  if FPaused then
  begin
    FPausedAccum := FPausedAccum + (GetTickCount64 - FPauseStart);
    FPaused := False;
  end;
  FState := rsIdle;
end;

procedure TSimpleTerminalRecorder.PauseRecording;
begin
  if FState = rsRecording then
  begin
    FPaused := True;
    FPauseStart := GetTickCount64;
    FState := rsPaused;
  end;
end;

procedure TSimpleTerminalRecorder.ResumeRecording;
begin
  if (FState = rsPaused) and FPaused then
  begin
    FPausedAccum := FPausedAccum + (GetTickCount64 - FPauseStart);
    FPaused := False;
    FState := rsRecording;
  end;
end;

function TSimpleTerminalRecorder.IsRecording: Boolean;
begin
  Result := FState in [rsRecording, rsPaused];
end;

function TSimpleTerminalRecorder.IsPlaying: Boolean;
begin
  Result := FState in [rsPlaying, rsPlayPaused];
end;

function TSimpleTerminalRecorder.GetRecordingState: TRecordingState;
begin
  Result := FState;
end;

procedure TSimpleTerminalRecorder.RecordOutput(const aData: string);
begin
  if FState in [rsRecording, rsPaused] then
    AddEvent(retOutput, aData);
end;

procedure TSimpleTerminalRecorder.RecordMarker(const aTag, aData: string);
begin
  if FState in [rsRecording, rsPaused] then
    AddEvent(retMarker, aTag + ':' + aData);
end;

procedure TSimpleTerminalRecorder.RecordResize(aWidth, aHeight: Integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
  if FState in [rsRecording, rsPaused] then
    AddEvent(retResize, Format('%dx%d', [aWidth, aHeight]));
end;

function TSimpleTerminalRecorder.GetEventCount: Integer;
begin
  Result := Length(FEvents);
end;

function TSimpleTerminalRecorder.GetSessionDuration: Double;
begin
  if FState in [rsRecording, rsPaused] then
    Result := ElapsedSeconds
  else
    Result := 0.0;
end;

function TSimpleTerminalRecorder.GetPlaybackPosition: Double;
begin
  // 简化：无真实回放，返回 0
  Result := 0.0;
end;

function TSimpleTerminalRecorder.GetCurrentSession: TRecordingSession;
var
  i: Integer;
begin
  Result.Version := 2;
  Result.Width := FWidth;
  Result.Height := FHeight;
  Result.Title := FTitle;
  Result.Command := '';
  Result.Shell := '';
  Result.TerminalType := '';
  Result.Timestamp := FStartDT;
  Result.Duration := GetSessionDuration;
  SetLength(Result.Events, Length(FEvents));
  for i := 0 to High(FEvents) do
    Result.Events[i] := FEvents[i];
end;

function TSimpleTerminalRecorder.GetSupportedFormats: TRecordingFormatArray;
begin
  SetLength(Result, 1);
  Result[0] := rfAsciiCast;
end;

procedure TSimpleTerminalRecorder.SaveRecording(const aFileName: string);
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    SL.Add('{"version": 2}');
    for i := 0 to High(FEvents) do
      SL.Add(Format('[%.3f,"o",%s]', [FEvents[i].Timestamp, QuotedStr(FEvents[i].Data)]));
    SL.SaveToFile(aFileName, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

function TSimpleTerminalRecorder.ImportRecording(const aFileName: string): Boolean;
begin
  Result := SysUtils.FileExists(aFileName);
end;

procedure TSimpleTerminalRecorder.StartPlayback(const aFileName: string);
begin
  // 简化：标记为 playing，立即置回 idle
  FState := rsPlaying;
  if Assigned(FOnPlayback) then
    FOnPlayback('start', aFileName, 0.0);
  // 模拟瞬时完成
  if Assigned(FOnPlayback) then
    FOnPlayback('end', aFileName, GetSessionDuration);
  FState := rsIdle;
end;

procedure TSimpleTerminalRecorder.StopPlayback;
begin
  if FState in [rsPlaying, rsPlayPaused] then
    FState := rsIdle;
end;

function TSimpleTerminalRecorder.GetPlaybackOptions: TPlaybackOptions;
begin
  Result.Speed := 1.0;
  Result.MaxDelay := 1.0;
  Result.SkipIdle := True;
  Result.Loop := False;
  Result.ShowTimestamp := False;
  Result.ShowProgress := True;
end;

procedure TSimpleTerminalRecorder.SetRecordEventCallback(ACallback: TRecordEventCallback);
begin
  FOnRecord := ACallback;
end;

procedure TSimpleTerminalRecorder.SetPlaybackEventCallback(ACallback: TPlaybackEventCallback);
begin
  FOnPlayback := ACallback;
end;

end.

