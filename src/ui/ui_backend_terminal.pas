unit ui_backend_terminal;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term, ui_backend;

function CreateTerminalBackend: IUiBackend;

implementation

uses
  sysutils;

type
  TTerminalBackend = class(TInterfacedObject, IUiBackend)
  public
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

procedure TTerminalBackend.BeginFrame;
begin
  // no-op for now (terminal backend flushes per operation)
end;

procedure TTerminalBackend.EndFrame;
begin
  // no-op for now (paired with BeginFrame)
end;

function TTerminalBackend.Size(out W, H: term_size_t): Boolean;
begin
  // Default init for analyzers; values will be set by term_size
  W := 0; H := 0;
  Result := term_size(W, H);
end;

procedure TTerminalBackend.Clear;
begin
  try
    term_clear;
  except
    // ignore when terminal not available
  end;
end;

procedure TTerminalBackend.CursorLine(ALine: term_size_t);
begin
  term_cursor_line(ALine + 1); // ui: 0-based -> term: 1-based
end;

procedure TTerminalBackend.CursorCol(ACol: term_size_t);
begin
  term_cursor_col(ACol + 1);
end;

function TTerminalBackend.CursorVisibleSet(Visible: Boolean): Boolean;
begin
  // Avoid calling term API when not attached to a terminal (e.g., piped output)
  try
    if not IsTerminal then Exit(True);
    Result := term_cursor_visible_set(Visible);
  except
    // Swallow any terminal init/IO exceptions to keep UI path robust
    Result := True;
  end;
end;

procedure TTerminalBackend.Write(const S: UnicodeString);
begin
  // Use term API so attributes/cursor controls take effect
  try
    term_write(S);
  except
    // ignore when terminal not available
  end;
end;

procedure TTerminalBackend.Writeln(const S: UnicodeString);
begin
  try
    term_writeln(S);
  except
    // ignore when terminal not available
  end;
end;

procedure TTerminalBackend.AttrReset;
begin
  term_attr_reset;
end;

procedure TTerminalBackend.SetFg24(R, G, B: Integer);
begin
  term_attr_foreground_set(term_color_24bit_rgb(R, G, B));
end;

procedure TTerminalBackend.SetBg24(R, G, B: Integer);
begin
  term_attr_background_set(term_color_24bit_rgb(R, G, B));
end;

function CreateTerminalBackend: IUiBackend;
begin
  Result := TTerminalBackend.Create;
end;

end.

