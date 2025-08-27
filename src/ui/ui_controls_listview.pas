unit ui_controls_listview;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_types,
  ui_node,
  ui_surface,
  ui_style;

// Virtualized ListView (1 row per item)
// - Renders only visible rows based on FTop and view height
// - Keyboard: Up/Down/PageUp/PageDown/Home/End moves selection and adjusts FTop
// - Colors: selected row uses inverted-like style; will be themed later

type
  TListViewFormatItem = function(Index: Integer; const Item: UnicodeString): UnicodeString;
  TListViewStyleForRow = function(Index: Integer; Selected: Boolean; var Style: TUiStyle): boolean;

  TListViewNode = class(TInterfacedObject, IUiNode)
  private
    FRect: TUiRect;
    FItems: array of UnicodeString;
    FSelection: Integer;
    FTop: term_size_t;
    FOnFormatItem: TListViewFormatItem;
    FOnStyleForRow: TListViewStyleForRow;
  public
    constructor Create;
    procedure Clear;
    procedure AddItem(const S: UnicodeString);
    procedure SetItems(const AItems: array of UnicodeString);
    function Count: Integer;
    function SelectionIndex: Integer;
    function SelectedItem(out S: UnicodeString): boolean;
    procedure SetSelectionIndex(AIndex: Integer);
    procedure SetRect(const R: TUiRect);
    procedure SetFormatItem(AFn: TListViewFormatItem);
    procedure SetStyleForRow(AFn: TListViewStyleForRow);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

implementation

constructor TListViewNode.Create;
begin
  inherited Create;
  FSelection := 0;
  FTop := 0;
  SetLength(FItems, 0);
  FOnFormatItem := nil;
  FOnStyleForRow := nil;
end;

procedure TListViewNode.Clear;
begin
  SetLength(FItems, 0);
  FSelection := 0;
  FTop := 0;
end;

procedure TListViewNode.AddItem(const S: UnicodeString);
var n: Integer;
begin
  n := Length(FItems);
  SetLength(FItems, n+1);
  FItems[n] := S;
end;

procedure TListViewNode.SetItems(const AItems: array of UnicodeString);
var
  i, n: Integer;
begin
  n := Length(AItems);
  SetLength(FItems, n);
  for i := 0 to n-1 do
    FItems[i] := AItems[i];
  if FSelection >= n then FSelection := n-1;
  if FSelection < 0 then FSelection := 0;
  if FTop > FSelection then FTop := FSelection;
end;

function TListViewNode.Count: Integer;
begin
  Result := Length(FItems);
end;

function TListViewNode.SelectionIndex: Integer;
begin
  Result := FSelection;
end;

function TListViewNode.SelectedItem(out S: UnicodeString): boolean;
begin
  if (FSelection >= 0) and (FSelection < Length(FItems)) then
  begin
    S := FItems[FSelection];
    Exit(true);
  end;
  Result := false;
end;

procedure TListViewNode.SetSelectionIndex(AIndex: Integer);
begin
  if AIndex < 0 then AIndex := 0;
  if AIndex >= Length(FItems) then AIndex := Length(FItems)-1;
  if FSelection <> AIndex then
  begin
    FSelection := AIndex;
    // Adjust top to keep selection visible
    var viewH := FRect.H; if viewH < 1 then viewH := 1;
    if FSelection < FTop then FTop := FSelection
    else if FSelection >= FTop + viewH then FTop := FSelection - (viewH - 1);
  end;
end;

procedure TListViewNode.SetFormatItem(AFn: TListViewFormatItem);
begin
  FOnFormatItem := AFn;
end;

procedure TListViewNode.SetStyleForRow(AFn: TListViewStyleForRow);
begin
  FOnStyleForRow := AFn;
end;

procedure TListViewNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TListViewNode.Render;
var
  viewW, viewH: term_size_t;
  row, idx, n: Integer;
  s, line: UnicodeString;
  y: term_size_t;
  style: TUiStyle;
  hasCustom: boolean;
begin
  viewW := FRect.W; viewH := FRect.H;
  if (viewW <= 0) or (viewH <= 0) then Exit;
  n := Length(FItems);
  if FSelection >= n then FSelection := n-1;
  if FSelection < 0 then FSelection := 0;
  if (FTop + viewH - 1 < FSelection) then FTop := FSelection - (viewH - 1);
  if FTop > FSelection then FTop := FSelection;
  if FTop < 0 then FTop := 0;
  if (FTop + viewH) > n then
  begin
    if n > viewH then FTop := n - viewH else FTop := 0;
  end;

  for row := 0 to viewH - 1 do
  begin
    idx := FTop + row;
    y := FRect.Y + row;
    if idx < n then
    begin
      if Assigned(FOnFormatItem) then s := FOnFormatItem(idx, FItems[idx]) else s := FItems[idx];
    end
    else s := '';
    // pad/truncate
    if Length(s) < viewW then
      line := s + StringOfChar(' ', viewW - Length(s))
    else
      line := Copy(s, 1, viewW);

    hasCustom := False;
    if Assigned(FOnStyleForRow) then
      hasCustom := FOnStyleForRow(idx, idx = FSelection, style);

    if hasCustom then
      UiStyleApply(style)
    else if idx = FSelection then
      UiStyleApply(UiThemeGetListRowSelectedStyle)
    else
      UiStyleApply(UiThemeGetListRowNormalStyle);

    UiWriteAt(y, FRect.X, line);
    UiStyleReset;
  end;
end;

function TListViewNode.HandleEvent(const E: term_event_t): boolean;
var
  n: Integer;
  viewH, delta: term_size_t;
begin
  Result := true;
  n := Length(FItems);
  if E.kind = tek_key then
  begin
    case E.key.key of
      KEY_UP:   if FSelection > 0 then Dec(FSelection);
      KEY_DOWN: if FSelection < n-1 then Inc(FSelection);
      KEY_PAGE_UP:
        begin
          viewH := FRect.H; if viewH < 1 then viewH := 1;
          if FSelection > viewH then Dec(FSelection, viewH) else FSelection := 0;
        end;
      KEY_PAGE_DOWN:
        begin
          viewH := FRect.H; if viewH < 1 then viewH := 1;
          if FSelection + viewH < n then Inc(FSelection, viewH) else FSelection := n-1;
        end;
      KEY_HOME: FSelection := 0;
      KEY_END:  if n>0 then FSelection := n-1;
    else
      Exit(false);
    end;

    // keep selection in view
    viewH := FRect.H; if viewH < 1 then viewH := 1;
    if FSelection < FTop then FTop := FSelection
    else if FSelection >= FTop + viewH then FTop := FSelection - (viewH - 1);
    if FTop < 0 then FTop := 0;
    if (FTop + viewH) > n then
    begin
      if n > viewH then FTop := n - viewH else FTop := 0;
    end;
    Exit(true);
  end;
  Result := false;
end;

end.

