unit ui_backend_memory;

{$mode objfpc}{$H+}

interface

{ Memory UI Backend (for tests and headless rendering)
  - Coordinates are 0-based (Line/Col; Y/X). WriteAt(Line, Col, ...)
  - Buffer is UnicodeString per line; width/height fixed at creation time
  - In frame/backbuffer mode (recommended) higher-level ui_surface composes diffs;
    this backend simply accumulates writes into FBuf
  - Intended usage in tests:
      B := CreateMemoryBackend(W,H);
      UiBackendSetCurrent(B);
      termui_frame_begin; ... draw ...; termui_frame_end;
      Buf := MemoryBackend_GetBuffer(B);
}

uses
  fafafa.core.term, ui_backend;

type
  TUnicodeStringArray = array of UnicodeString;

  // Optional interface to expose memory buffer for tests
  IMemoryBackend = interface(IUiBackend)
    ['{9E2EFD33-90B6-4B7A-8D48-6B56F00DDF55}']
    function GetBuffer: TUnicodeStringArray;
  end;

function CreateMemoryBackend(AWidth, AHeight: term_size_t): IUiBackend;

// Simple helpers to peek buffer without exposing internal class
function MemoryBackend_GetBuffer(const Backend: IUiBackend): TUnicodeStringArray;

implementation

uses
  sysutils;


function RepeatCharU(Ch: UnicodeChar; Count: SizeInt): UnicodeString; inline;
var
  i: SizeInt;
  S: UnicodeString;
begin
  if Count <= 0 then
  begin
    S := '';
  end
  else
  begin
    SetLength(S, Count);
    for i := 1 to Count do S[i] := Ch;
  end;
  Result := S;
end;

type
  TMemoryBackend = class(TInterfacedObject, IUiBackend, IMemoryBackend, IUiBackendV2)
  private
    FBuf: array of UnicodeString;
    FW, FH: term_size_t;
    FCursorVisible: Boolean;
    FCursorLine, FCursorCol: term_size_t;
    FAttr: TUiAttr;
  public
    constructor Create(AW, AH: term_size_t);
    procedure BeginFrame;
    procedure EndFrame;
    function Size(out W, H: term_size_t): Boolean;
    procedure Clear;

    procedure CursorLine(ALine: term_size_t);
    procedure CursorCol(ACol: term_size_t);
    function CursorVisibleSet(Visible: Boolean): Boolean;

    procedure Write(const S: UnicodeString);
    procedure Writeln(const S: UnicodeString);

    procedure AttrReset; // no-op
    procedure SetFg24(R, G, B: Integer); // no-op
    procedure SetBg24(R, G, B: Integer); // no-op

    // internal helpers
    procedure EnsureCursorInRange;

    // IMemoryBackend
    function GetBuffer: TUnicodeStringArray;

    // IUiBackendV2
    function GetCapabilities: TUiBackendCaps;
    // 0-based coordinates: Line=Y, Col=X
    procedure WriteAt(Line, Col: term_size_t; const S: UnicodeString);
    // FillRect uses 0-based X,Y and W,H sizes; out-of-range is clamped by Write
    procedure FillRect(X, Y, W, H: term_size_t; Ch: UnicodeChar);
    procedure SetAttr(const Attr: TUiAttr);
  end;

constructor TMemoryBackend.Create(AW, AH: term_size_t);
var
  i: SizeInt;
begin
  FW := AW; FH := AH;
  SetLength(FBuf, FH);
  for i := 0 to FH-1 do FBuf[i] := RepeatCharU(' ', FW);
  FCursorVisible := True;
  FCursorLine := 0; FCursorCol := 0;
end;

procedure TMemoryBackend.BeginFrame;
begin
end;

procedure TMemoryBackend.EndFrame;
begin
end;

function TMemoryBackend.Size(out W, H: term_size_t): Boolean;
begin
  W := FW; H := FH; Result := True;
end;

procedure TMemoryBackend.Clear;
var
  i: SizeInt;
begin
  for i := 0 to FH-1 do FBuf[i] := RepeatCharU(' ', FW);
  FCursorLine := 0; FCursorCol := 0;
end;

procedure TMemoryBackend.CursorLine(ALine: term_size_t);
begin
  FCursorLine := ALine;
  EnsureCursorInRange;
end;

procedure TMemoryBackend.CursorCol(ACol: term_size_t);
begin
  FCursorCol := ACol;
  EnsureCursorInRange;
end;

function TMemoryBackend.CursorVisibleSet(Visible: Boolean): Boolean;
begin
  FCursorVisible := Visible; Result := True;
end;

procedure TMemoryBackend.Write(const S: UnicodeString);
var line: UnicodeString; i, pos1, maxLen, segLen: Integer;
begin
  EnsureCursorInRange;
  line := FBuf[FCursorLine];
  if FCursorCol >= FW then Exit;
  pos1 := FCursorCol + 1; // 1-based
  maxLen := FW - FCursorCol;
  segLen := Length(S); if segLen > maxLen then segLen := maxLen;
  for i := 1 to segLen do line[pos1 + i - 1] := S[i];
  FBuf[FCursorLine] := line;
  Inc(FCursorCol, segLen);
end;

procedure TMemoryBackend.Writeln(const S: UnicodeString);
begin
  Write(S);
  Inc(FCursorLine);
  FCursorCol := 0;
  EnsureCursorInRange;
end;

procedure TMemoryBackend.AttrReset;
begin
  FillChar(FAttr, SizeOf(FAttr), 0);
end;

procedure TMemoryBackend.SetFg24(R, G, B: Integer);
begin
  FAttr.HasFg := True; FAttr.Fg.R := R; FAttr.Fg.G := G; FAttr.Fg.B := B;
end;

procedure TMemoryBackend.SetBg24(R, G, B: Integer);
begin
  FAttr.HasBg := True; FAttr.Bg.R := R; FAttr.Bg.G := G; FAttr.Bg.B := B;
end;

procedure TMemoryBackend.EnsureCursorInRange;
begin
  // clamp to buffer bounds (0-based)
  if FCursorLine >= FH then FCursorLine := FH-1;
  if FCursorCol >= FW then FCursorCol := FW-1;
end;

function TMemoryBackend.GetBuffer: TUnicodeStringArray;
var
  i: SizeInt;
  B: TUnicodeStringArray;
begin
  SetLength(B, Length(FBuf));
  for i := 0 to High(FBuf) do B[i] := FBuf[i];
  Result := B;
end;

function TMemoryBackend.GetCapabilities: TUiBackendCaps;
begin
  Result := [CapTrueColor, CapBatchWrite, CapClear, CapCursor];
end;

procedure TMemoryBackend.WriteAt(Line, Col: term_size_t; const S: UnicodeString);
begin
  FCursorLine := Line; FCursorCol := Col;
  Write(S);
end;

procedure TMemoryBackend.FillRect(X, Y, W, H: term_size_t; Ch: UnicodeChar);
var yy: term_size_t;
begin
  // naive row-wise fill; relies on Write() to clamp ranges into buffer
  for yy := 0 to H-1 do
  begin
    FCursorLine := Y + yy; FCursorCol := X;
    Write(RepeatCharU(Ch, W));
  end;
end;

procedure TMemoryBackend.SetAttr(const Attr: TUiAttr);
begin
  FAttr := Attr;
end;

function CreateMemoryBackend(AWidth, AHeight: term_size_t): IUiBackend;
begin
  Result := TMemoryBackend.Create(AWidth, AHeight);
end;

function MemoryBackend_GetBuffer(const Backend: IUiBackend): TUnicodeStringArray;
var mb: IMemoryBackend;
begin
  if Supports(Backend, IMemoryBackend, mb) then
    Result := mb.GetBuffer
  else
    SetLength(Result, 0);
end;

end.

