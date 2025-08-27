unit ui_backend_nvim;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_backend;

// Skeleton Neovim RPC backend implementing IUiBackendV2.
// No real transport yet; batches ops and no-ops on EndFrame.
// Size defaults to a cached value (80x24) unless provided at creation.

function CreateNvimBackend(const AInitW, AInitH: term_size_t): IUiBackend;

implementation

uses
  SysUtils;

type
  TNvimOpKind = (
    opClear, opWriteAt, opFillRect, opCursorLine, opCursorCol, opCursorVisible,
    opAttrReset, opSetFg24, opSetBg24
  );

  TNvimOp = record
    Kind: TNvimOpKind;
    I1, I2, I3, I4: Integer; // generic ints
    S: UnicodeString;        // payload
  end;

  TNvimBackend = class(TInterfacedObject, IUiBackend, IUiBackendV2)
  private
    FInFrame: Boolean;
    FWidth, FHeight: term_size_t;
    FCaps: TUiBackendCaps;
    FCursorVisible: Boolean;
    FCurLine, FCurCol: term_size_t; // track when using Write/Writeln
    FOps: array of TNvimOp; // batched ops
  private
    procedure PushOp(const op: TNvimOp);
  public
    constructor Create(const AInitW, AInitH: term_size_t);
    // IUiBackend
    procedure BeginFrame;
    procedure EndFrame;
    function Size(out W, H: term_size_t): Boolean;
    procedure Clear;

    procedure CursorLine(ALine: term_size_t);
    procedure CursorCol(ACol: term_size_t);
    function CursorVisibleSet(Visible: Boolean): Boolean;

    procedure Write(const S: UnicodeString);
    procedure Writeln(const S: UnicodeString);

    procedure AttrReset;
    procedure SetFg24(R, G, B: Integer);
    procedure SetBg24(R, G, B: Integer);

    // IUiBackendV2
    function GetCapabilities: TUiBackendCaps;
    procedure WriteAt(Line, Col: term_size_t; const S: UnicodeString);
    procedure FillRect(X, Y, W, H: term_size_t; Ch: UnicodeChar);
  end;

{ TNvimBackend }

constructor TNvimBackend.Create(const AInitW, AInitH: term_size_t);
begin
  inherited Create;
  FWidth := AInitW; if FWidth <= 0 then FWidth := 80;
  FHeight := AInitH; if FHeight <= 0 then FHeight := 24;
  FCaps := [CapBatchWrite, CapClear, CapCursor];
  FCursorVisible := True;
  FCurLine := 0; FCurCol := 0;
end;

procedure TNvimBackend.PushOp(const op: TNvimOp);
var n: SizeInt;
begin
  n := Length(FOps);
  SetLength(FOps, n+1);
  FOps[n] := op;
end;

procedure TNvimBackend.BeginFrame;
begin
  FInFrame := True;
  SetLength(FOps, 0);
end;

procedure TNvimBackend.EndFrame;
begin
  // In the skeleton, we simply drop the batched ops.
  SetLength(FOps, 0);
  FInFrame := False;
end;

function TNvimBackend.Size(out W, H: term_size_t): Boolean;
begin
  W := FWidth; H := FHeight;
  Result := (W > 0) and (H > 0);
end;

procedure TNvimBackend.Clear;
var op: TNvimOp;
begin
  op.Kind := opClear; op.I1 := 0; op.I2 := 0; op.I3 := 0; op.I4 := 0; op.S := '';
  PushOp(op);
end;

procedure TNvimBackend.CursorLine(ALine: term_size_t);
var op: TNvimOp;
begin
  FCurLine := ALine;
  op.Kind := opCursorLine; op.I1 := ALine; op.S := '';
  PushOp(op);
end;

procedure TNvimBackend.CursorCol(ACol: term_size_t);
var op: TNvimOp;
begin
  FCurCol := ACol;
  op.Kind := opCursorCol; op.I1 := ACol; op.S := '';
  PushOp(op);
end;

function TNvimBackend.CursorVisibleSet(Visible: Boolean): Boolean;
var op: TNvimOp;
begin
  FCursorVisible := Visible;
  op.Kind := opCursorVisible; op.I1 := Ord(Visible); op.S := '';
  PushOp(op);
  Result := True;
end;

procedure TNvimBackend.Write(const S: UnicodeString);
var op: TNvimOp;
begin
  // Write at current cursor position (tracked in CursorLine/Col)
  op.Kind := opWriteAt; op.I1 := FCurLine; op.I2 := FCurCol; op.S := S;
  PushOp(op);
  // advance cursor: naive single-line advance
  Inc(FCurCol, Length(S));
end;

procedure TNvimBackend.Writeln(const S: UnicodeString);
begin
  Write(S);
  Inc(FCurLine);
  FCurCol := 0;
end;

procedure TNvimBackend.AttrReset;
var op: TNvimOp;
begin
  op.Kind := opAttrReset; op.S := '';
  PushOp(op);
end;

procedure TNvimBackend.SetFg24(R, G, B: Integer);
var op: TNvimOp;
begin
  op.Kind := opSetFg24; op.I1 := R; op.I2 := G; op.I3 := B; op.S := '';
  PushOp(op);
end;

procedure TNvimBackend.SetBg24(R, G, B: Integer);
var op: TNvimOp;
begin
  op.Kind := opSetBg24; op.I1 := R; op.I2 := G; op.I3 := B; op.S := '';
  PushOp(op);
end;

function TNvimBackend.GetCapabilities: TUiBackendCaps;
begin
  Result := FCaps;
end;

procedure TNvimBackend.WriteAt(Line, Col: term_size_t; const S: UnicodeString);
var op: TNvimOp;
begin
  op.Kind := opWriteAt; op.I1 := Line; op.I2 := Col; op.S := S;
  PushOp(op);
end;

procedure TNvimBackend.FillRect(X, Y, W, H: term_size_t; Ch: UnicodeChar);
var op: TNvimOp;
begin
  op.Kind := opFillRect; op.I1 := X; op.I2 := Y; op.I3 := W; op.I4 := H; op.S := UnicodeString(Ch);
  PushOp(op);
end;

function CreateNvimBackend(const AInitW, AInitH: term_size_t): IUiBackend;
begin
  Result := TNvimBackend.Create(AInitW, AInitH);
end;

end.

