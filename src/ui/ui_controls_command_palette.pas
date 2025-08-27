unit ui_controls_command_palette;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_types,
  ui_node,
  ui_surface,
  ui_style,
  ui_controls_textinput,
  ui_controls_listview;

// Command Palette (skeleton)
// - Toggle with Ctrl+K
// - Centered overlay panel with TextInput + ListView
// - Simple contains-text filtering (case-insensitive)

type
  TCommandPaletteNode = class(TInterfacedObject, IUiNode)
  private
    FRect: TUiRect;
    FActive: boolean;
    FInput: TTextInputNode;
    FList: TListViewNode;
    FAllItems: array of UnicodeString;
    FLastQuery: UnicodeString;
    procedure RebuildFiltered;
  public
    constructor Create;
    procedure Show; inline;
    procedure Hide; inline;
    procedure Toggle; inline;
    procedure SetItems(const AItems: array of UnicodeString);
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

implementation

uses SysUtils; // for LowerCase

constructor TCommandPaletteNode.Create;
begin
  inherited Create;
  FActive := false;
  FInput := TTextInputNode.Create('Type to search (Esc to close)');
  FList := TListViewNode.Create;
  SetLength(FAllItems, 0);
  FLastQuery := '';
end;

procedure TCommandPaletteNode.Show; begin FActive := true; end;
procedure TCommandPaletteNode.Hide; begin FActive := false; end;
procedure TCommandPaletteNode.Toggle; begin FActive := not FActive; end;

procedure TCommandPaletteNode.SetItems(const AItems: array of UnicodeString);
var i,n: Integer;
begin
  n := Length(AItems);
  SetLength(FAllItems, n);
  for i := 0 to n-1 do FAllItems[i] := AItems[i];
  RebuildFiltered;
end;

procedure TCommandPaletteNode.RebuildFiltered;
var
  i: Integer; q, s: UnicodeString;
begin
  if not Assigned(FList) then Exit;
  FList.Clear;
  q := Trim(LowerCase(FInput.Text));
  if q = '' then
  begin
    for i := 0 to High(FAllItems) do FList.AddItem(FAllItems[i]);
  end
  else
  begin
    for i := 0 to High(FAllItems) do
    begin
      s := LowerCase(FAllItems[i]);
      if Pos(q, s) > 0 then FList.AddItem(FAllItems[i]);
    end;
  end;
end;

procedure TCommandPaletteNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TCommandPaletteNode.Render;
var
  w,h: term_size_t;
  pw,ph: term_size_t;
  px,py: term_size_t;
  panel: TUiRect;
begin
  if not FActive then Exit;
  w := FRect.W; h := FRect.H;
  if (w <= 0) or (h <= 0) then Exit;

  // Panel size: min( max(40, w*3/5), w-4 ) x min( max(10, h/2), h-4 )
  pw := w * 3 div 5; if pw < 40 then pw := 40; if pw > w-4 then pw := w-4;
  ph := h div 2; if ph < 10 then ph := 10; if ph > h-4 then ph := h-4;
  px := FRect.X + (w - pw) div 2; py := FRect.Y + (h - ph) div 3; // slight top bias

  // Backdrop dim (simple)
  UiSetBg24(0,0,0); UiSetFg24(0,0,0);
  UiFillRect(FRect.X, FRect.Y, FRect.W, FRect.H, ' ');

  // Panel background
  UiStyleApply(UiThemeGetTabInactiveStyle);
  UiFillRect(px, py, pw, ph, ' ');

  // Layout: input 1 line at top, list fills rest
  FInput.SetRect(TUiRect.Create(px+1, py+1, pw-2, 1));
  FInput.Render;

  FList.SetRect(TUiRect.Create(px+1, py+3, pw-2, ph-4));
  FList.Render;

  UiStyleReset;
end;

function TCommandPaletteNode.HandleEvent(const E: term_event_t): boolean;
begin
  Result := true;
  if (E.kind = tek_key) then
  begin
    // Toggle: Ctrl+K or Ctrl+P (common in dev tools)
    if (E.key.ctrl = 1) and ((E.key.key = KEY_K) or (E.key.key = KEY_P)) then
    begin
      Toggle;
      Exit(true);
    end;
    if not FActive then Exit(false);
    // Close on Esc
    if E.key.key = KEY_ESC then begin Hide; Exit(true); end;
  end
  else if not FActive then
    Exit(false);

  // Active: route to children
  if FInput.HandleEvent(E) then
  begin
    // When input changed, rebuild list (Render 时也可做，但这里更及时)
    RebuildFiltered;
    Exit(true);
  end;
  if FList.HandleEvent(E) then Exit(true);

  Result := false;
end;

end.

