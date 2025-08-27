unit ui_backend;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term;

// Backend abstraction for rendering environments.
// Keep minimal for now; can be extended later.
type
  IUiBackend = interface
    ['{5B934E0A-1C4B-4B6A-A19B-8D3D2C4C6C71}']
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
  end;

  // Optional V2: capabilities and direct ops for modern backends (memory/rpc)
  TUiBackendCap = (CapTrueColor, CapBatchWrite, CapClear, CapCursor);
  TUiBackendCaps = set of TUiBackendCap;

  // Low-level attribute payload (backend-facing)
  TUiAttrStyle = (UiBold, UiUnderline, UiReverse);
  TUiAttrStyles = set of TUiAttrStyle;
  TUiColor24 = record R, G, B: Integer; end;
  TUiAttr = record
    HasFg, HasBg: Boolean;
    Fg, Bg: TUiColor24;
    Styles: TUiAttrStyles;
  end;

  IUiBackendV2 = interface(IUiBackend)
    ['{E3A6F2E9-7E8D-4D2B-9E9A-2F1A9DC6A9B7}']
    function GetCapabilities: TUiBackendCaps;
    procedure WriteAt(Line, Col: term_size_t; const S: UnicodeString);
    procedure FillRect(X, Y, W, H: term_size_t; Ch: UnicodeChar);
    procedure SetAttr(const Attr: TUiAttr);
  end;

// Registry (very small): current backend getter/setter.
function UiBackendGetCurrent: IUiBackend;
procedure UiBackendSetCurrent(const ABackend: IUiBackend);

implementation

uses
  ui_backend_terminal; // provide default backend

var
  GCurrentBackend: IUiBackend = nil;

function UiBackendGetCurrent: IUiBackend;
begin
  if GCurrentBackend = nil then
    GCurrentBackend := ui_backend_terminal.CreateTerminalBackend;
  Result := GCurrentBackend;
end;

procedure UiBackendSetCurrent(const ABackend: IUiBackend);
begin
  GCurrentBackend := ABackend;
end;

end.

