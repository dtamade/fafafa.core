unit ui_controls_tabs;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_types,
  ui_node,
  ui_surface,
  ui_style;

// Minimal Tabs control
// - Horizontal tab strip (1 line) with active/inactive styles
// - Left/Right to switch tabs
// - Renders active content in remaining area

type
  TTabsNode = class(TInterfacedObject, IUiNode)
  private
    FRect: TUiRect;
    FCaptions: array of UnicodeString;
    FContents: array of IUiNode;
    FActive: Integer;
    procedure ClampActive;
  public
    constructor Create;
    procedure AddTab(const Caption: UnicodeString; const Content: IUiNode);
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

implementation

constructor TTabsNode.Create;
begin
  inherited Create;
  SetLength(FCaptions, 0);
  SetLength(FContents, 0);
  FActive := 0;
end;

procedure TTabsNode.ClampActive;
var n: Integer;
begin
  n := Length(FContents);
  if n = 0 then FActive := 0 else
  begin
    if FActive < 0 then FActive := 0;
    if FActive > n-1 then FActive := n-1;
  end;
end;

procedure TTabsNode.AddTab(const Caption: UnicodeString; const Content: IUiNode);
var n: Integer;
begin
  n := Length(FCaptions);
  SetLength(FCaptions, n+1);
  SetLength(FContents, n+1);
  FCaptions[n] := Caption;
  FContents[n] := Content;
  ClampActive;
end;

procedure TTabsNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TTabsNode.Render;
var
  x, y, w, h: term_size_t;
  i: Integer;
  cap, pad: UnicodeString;
  contentRect: TUiRect;
begin
  x := FRect.X; y := FRect.Y; w := FRect.W; h := FRect.H;
  if (w <= 0) or (h <= 0) then Exit;

  // draw tab strip on first line
  UiStyleApply(UiThemeGetTabInactiveStyle);
  UiFillLine(y, ' ', w);

  // render captions sequentially
  pad := ' ';
  var cx := x;
  for i := 0 to High(FCaptions) do
  begin
    cap := '[' + FCaptions[i] + ']';
    if i = FActive then UiStyleApply(UiThemeGetTabActiveStyle)
                   else UiStyleApply(UiThemeGetTabInactiveStyle);
    if (cx - x) + Length(cap) > w then Break;
    UiWriteAt(y, cx, cap);
    Inc(cx, Length(cap));
    if (cx - x) < w then begin UiWriteAt(y, cx, pad); Inc(cx, 1); end;
  end;
  UiStyleReset;

  // body: remaining area
  if h > 1 then
  begin
    contentRect.X := x; contentRect.Y := y + 1; contentRect.W := w; contentRect.H := h - 1;
    if (FActive >= 0) and (FActive < Length(FContents)) and Assigned(FContents[FActive]) then
    begin
      FContents[FActive].SetRect(contentRect);
      FContents[FActive].Render;
    end;
  end;
end;

function TTabsNode.HandleEvent(const E: term_event_t): boolean;
var n: Integer;
begin
  Result := true;
  n := Length(FContents);
  if E.kind = tek_key then
  begin
    case E.key.key of
      KEY_LEFT:  if FActive > 0 then Dec(FActive) else FActive := 0;
      KEY_RIGHT: if FActive < n-1 then Inc(FActive);
    else
      // pass to active content
      if (FActive >= 0) and (FActive < n) and Assigned(FContents[FActive]) then
        Exit(FContents[FActive].HandleEvent(E))
      else
        Exit(false);
    end;
    Exit(true);
  end;
  if (FActive >= 0) and (FActive < n) and Assigned(FContents[FActive]) then
    Result := FContents[FActive].HandleEvent(E)
  else
    Result := false;
end;

end.

