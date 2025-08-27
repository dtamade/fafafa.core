unit ui_controls_scrollcontainer;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_types,
  ui_node,
  ui_surface,
  ui_style;

// Simple scrollable container with clipping and vertical scroll
// Note: minimal implementation to validate pipeline; will evolve

type
  TScrollContainerNode = class(TInterfacedObject, IUiNode)
  private
    FRect: TUiRect;
    FContent: IUiNode;
    FScrollY: term_size_t;
    FScrollX: term_size_t;
    FContentW: term_size_t;
    FContentH: term_size_t;
  public
    constructor Create(const AChild: IUiNode);
    procedure SetScroll(AX, AY: term_size_t);
    procedure SetContentSize(AW, AH: term_size_t);
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

implementation

constructor TScrollContainerNode.Create(const AChild: IUiNode);
begin
  inherited Create;
  FContent := AChild;
  FScrollX := 0; FScrollY := 0;
  FContentW := 0; FContentH := 0; // 0 means auto = view size
end;

procedure TScrollContainerNode.SetScroll(AX, AY: term_size_t);
begin
  if AX < 0 then AX := 0;
  if AY < 0 then AY := 0;
  FScrollX := AX; FScrollY := AY;
end;

procedure TScrollContainerNode.SetContentSize(AW, AH: term_size_t);
begin
  FContentW := AW; FContentH := AH;
end;

procedure TScrollContainerNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TScrollContainerNode.Render;
var
  inner: TUiRect;
  viewW, viewH, visibleW, maxX, maxY, cw, ch: term_size_t;
  needVBar: Boolean;
  trackX, trackY, trackH, thumbH, thumbY: term_size_t;
  i: Integer;
begin
  // Clip to container rect and shift origin by -scroll
  inner := FRect;
  viewW := inner.W; viewH := inner.H;
  if (viewW <= 0) or (viewH <= 0) then Exit;
  // determine content size (auto fallback to view size)
  if FContentW = 0 then cw := viewW else cw := FContentW;
  if FContentH = 0 then ch := viewH else ch := FContentH;
  // do we need vertical scrollbar?
  needVBar := ch > viewH;
  if needVBar and (viewW > 1) then visibleW := viewW - 1 else visibleW := viewW;
  // clamp scroll to bounds (based on visible content area)
  if cw > visibleW then maxX := cw - visibleW else maxX := 0;
  if ch > viewH then maxY := ch - viewH else maxY := 0;
  if FScrollX > maxX then FScrollX := maxX;
  if FScrollY > maxY then FScrollY := maxY;
  // push viewport and origin (origin negative scroll to move content)
  UiPushView(inner.X, inner.Y, visibleW, viewH, -FScrollX, -FScrollY);
  if Assigned(FContent) then
  begin
    // provide content full rect (0,0,cw,ch); clipping is guaranteed by UiPushView
    var contentRect: TUiRect;
    contentRect.X := 0; contentRect.Y := 0;
    contentRect.W := cw; contentRect.H := ch;
    FContent.SetRect(contentRect);
    FContent.Render;
  end;
  UiPopView;

  // draw vertical scrollbar (1 column at right)
  if needVBar and (viewW > 1) then
  begin
    trackX := inner.X + visibleW; // rightmost column reserved for bar
    trackY := inner.Y;
    trackH := viewH;
    // track
    UiStyleApply(UiThemeGetScrollTrackStyle);
    for i := 0 to trackH - 1 do
      UiWriteAt(trackY + i, trackX, '│');
    // thumb
    if maxY > 0 then
    begin
      // thumb height proportional to view/total; min 1
      thumbH := (viewH * viewH) div ch;
      if thumbH < 1 then thumbH := 1;
      if thumbH > viewH then thumbH := viewH;
      thumbY := trackY + (FScrollY * (viewH - thumbH)) div maxY;
    end
    else
    begin
      thumbH := viewH; thumbY := trackY;
    end;
    UiStyleApply(UiThemeGetScrollThumbStyle);
    for i := 0 to thumbH - 1 do
      UiWriteAt(thumbY + i, trackX, '█');
    UiStyleReset;
  end;
end;

function TScrollContainerNode.HandleEvent(const E: term_event_t): boolean;
var
  viewW, viewH, maxX, maxY, cw, ch, delta: term_size_t;
begin
  Result := true;
  // compute bounds
  viewW := FRect.W; viewH := FRect.H;
  if FContentW = 0 then cw := viewW else cw := FContentW;
  if FContentH = 0 then ch := viewH else ch := FContentH;
  if cw > viewW then maxX := cw - viewW else maxX := 0;
  if ch > viewH then maxY := ch - viewH else maxY := 0;

  // mouse wheel
  if (E.kind = tek_mouse) and (E.mouse.state = tms_moved) then
  begin
    case E.mouse.button of
      tmb_wheel_up:
        if FScrollY > 0 then Dec(FScrollY);
      tmb_wheel_down:
        if FScrollY < maxY then Inc(FScrollY);
      tmb_wheel_left:
        if FScrollX > 0 then Dec(FScrollX);
      tmb_wheel_right:
        if FScrollX < maxX then Inc(FScrollX);
    end;
    Exit(true);
  end;

  // basic scroll with keyboard
  if E.kind = tek_key then
  begin
    case E.key.key of
      KEY_UP:   if FScrollY > 0 then Dec(FScrollY);
      KEY_DOWN: if FScrollY < maxY then Inc(FScrollY);
      KEY_LEFT: if FScrollX > 0 then Dec(FScrollX);
      KEY_RIGHT:if FScrollX < maxX then Inc(FScrollX);
      KEY_PAGE_UP:
        begin
          if viewH > 1 then delta := viewH - 1 else delta := 1;
          if FScrollY > delta then Dec(FScrollY, delta) else FScrollY := 0;
        end;
      KEY_PAGE_DOWN:
        begin
          if viewH > 1 then delta := viewH - 1 else delta := 1;
          if FScrollY + delta < maxY then Inc(FScrollY, delta) else FScrollY := maxY;
        end;
      KEY_HOME: FScrollY := 0;
      KEY_END:  FScrollY := maxY;
    else
      // not handled here, pass to child
      if Assigned(FContent) then Exit(FContent.HandleEvent(E)) else Exit(true);
    end;
    Exit(true);
  end;

  if Assigned(FContent) then
    Result := FContent.HandleEvent(E);
end;

end.

