unit ui_node;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_types,
  ui_style;

type
  // Procedural types
  TPanelRenderProc = procedure(const Rect: TUiRect);

  IUiNode = interface
    ['{B6A0AE87-962A-4F9F-9D4D-6B2F0D8B5E1B}']
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean; // true=keep running
  end;

  TStackRootNode = class(TInterfacedObject, IUiNode)
  private
    FChildren: array of IUiNode;
    FRect: TUiRect;
  public
    procedure Add(const N: IUiNode);
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

  // Simple banner at the top
  TBannerNode = class(TInterfacedObject, IUiNode)
  private
    FText: UnicodeString;
    FRect: TUiRect;
  public
    constructor Create(const AText: UnicodeString);
    procedure SetText(const AText: UnicodeString);
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

  // Simple status bar (bottom by default)
  TStatusBarNode = class(TInterfacedObject, IUiNode)
  private
    FText: UnicodeString;
    FRect: TUiRect;
    FAlignBottom: boolean;
  public
    constructor Create(const AText: UnicodeString; ABottom: boolean = true);
    procedure SetText(const AText: UnicodeString);
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

  // Panel: fill its rect with a background color and char
  TPanelNode = class(TInterfacedObject, IUiNode)
  private
    FRect: TUiRect;
    FBgR, FBgG, FBgB: Integer;
    FCh: UnicodeChar;
    FOnRender: TPanelRenderProc;
  public
    constructor Create; overload; // default dark bg
    constructor Create(AR,AG,AB: Integer; ACh: UnicodeChar = ' '); overload;
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
    // Theming helpers
    procedure SetBgColor(AR, AG, AB: Integer);
    // Optional overlay render callback (called after panel background is drawn and attrs reset)
    property OnRender: TPanelRenderProc read FOnRender write FOnRender;
  end;

  // VBox with fixed and flex items, with padding/gap
  TVBoxNode = class(TInterfacedObject, IUiNode)
  private
    type
      TVBoxItem = record
        Node: IUiNode;
        Fixed: boolean;
        Size: term_size_t; // fixed height when Fixed=true
        Weight: integer;   // flex weight when Fixed=false
      end;
    var
      FItems: array of TVBoxItem;
      FRect: TUiRect;
      FPadding: TUiPadding;
      FGap: term_size_t;
      FDebugDecorate: boolean;
  public
    constructor Create;
    procedure SetPadding(ATop, ARight, ABottom, ALeft: term_size_t);
    procedure SetGap(AGap: term_size_t);
    procedure AddFixed(const N: IUiNode; AHeight: term_size_t);
    procedure AddFlex(const N: IUiNode; AWeight: integer = 1);
    procedure SetDebugDecorate(AEnable: boolean);
    property DebugDecorate: boolean read FDebugDecorate write FDebugDecorate;
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

  // HBox with fixed and flex items, with padding/gap
  THBoxNode = class(TInterfacedObject, IUiNode)
  private
    type
      THBoxItem = record
        Node: IUiNode;
        Fixed: boolean;
        Size: term_size_t; // fixed width when Fixed=true
        Weight: integer;   // flex weight when Fixed=false
      end;
    var
      FItems: array of THBoxItem;
      FRect: TUiRect;
      FPadding: TUiPadding;
      FGap: term_size_t;
      FDebugDecorate: boolean;
  public
    constructor Create;
    procedure SetPadding(ATop, ARight, ABottom, ALeft: term_size_t);
    procedure SetGap(AGap: term_size_t);
    procedure AddFixed(const N: IUiNode; AWidth: term_size_t);
    procedure AddFlex(const N: IUiNode; AWeight: integer = 1);
    procedure SetDebugDecorate(AEnable: boolean);
    property DebugDecorate: boolean read FDebugDecorate write FDebugDecorate;
    // IUiNode
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
  end;

implementation

uses
  ui_surface;

{ TStackRootNode }

procedure TStackRootNode.Add(const N: IUiNode);
begin
  SetLength(FChildren, Length(FChildren)+1);
  FChildren[High(FChildren)] := N;
end;

procedure TStackRootNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TStackRootNode.Render;
var
  i: Integer;
  w,h: term_size_t;
  rect: TUiRect;
begin
  // Default init for analyzers; will be overwritten by term_size or fallback
  w := 0; h := 0;
  // Fallback to 80x24 when terminal size is unavailable (safety only)
  if not term_size(w,h) then begin w := 80; h := 24; end;
  // Clear the whole screen each frame to avoid residual shell text
  UiClear;
  rect.X := 0; rect.Y := 0; rect.W := w; rect.H := h;
  for i := 0 to High(FChildren) do
  begin
    FChildren[i].SetRect(rect);
    FChildren[i].Render;
  end;
end;

function TStackRootNode.HandleEvent(const E: term_event_t): boolean;
var
  i: Integer;
begin
  // Global quit will be handled by UiAppRunNode, but also allow child to request exit
  Result := true;
  for i := 0 to High(FChildren) do
    if not FChildren[i].HandleEvent(E) then Exit(false);
end;

{ TBannerNode }

constructor TBannerNode.Create(const AText: UnicodeString);
begin
  inherited Create;
  FText := AText;
end;

procedure TBannerNode.SetText(const AText: UnicodeString);
begin
  FText := AText;
end;

procedure TBannerNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TBannerNode.Render;
var
  y: term_size_t;
begin
  // Draw at top of assigned rect
  y := FRect.Y;
  UiSetBg24(40,40,40); UiSetFg24(255,255,255);
  UiFillRect(FRect.X, y, FRect.W, 1, ' ');
  // UiWriteAt(Line(Y), Col(X), Text) — 注意参数顺序
  UiWriteAt(y, FRect.X, FText);
  UiAttrReset;
end;

function TBannerNode.HandleEvent(const E: term_event_t): boolean;
begin
  Result := true;
end;

{ TStatusBarNode }

constructor TStatusBarNode.Create(const AText: UnicodeString; ABottom: boolean);
begin
  inherited Create;
  FText := AText;
  FAlignBottom := ABottom;
end;

procedure TStatusBarNode.SetText(const AText: UnicodeString);
begin
  FText := AText;
end;

procedure TStatusBarNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TStatusBarNode.Render;
var
  line: term_size_t;
begin
  // If height is zero, nothing to draw
  if FRect.H = 0 then Exit;
  if FAlignBottom then
  begin
    if (FRect.H > 0) then line := FRect.Y + FRect.H - 1 else line := FRect.Y;
  end
  else
    line := FRect.Y;
  // Use theme style for status bar
  UiStyleApply(UiThemeGetStatusBarStyle);
  UiFillRect(FRect.X, line, FRect.W, 1, ' ');
  // UiWriteAt(Line(Y), Col(X), Text) — 注意参数顺序
  UiWriteAt(line, FRect.X, FText);
  UiStyleReset;
end;

function TStatusBarNode.HandleEvent(const E: term_event_t): boolean;
begin
  Result := true;
end;

{ TPanelNode }

constructor TPanelNode.Create;
begin
  inherited Create;
  FBgR := 20; FBgG := 20; FBgB := 20;
  FCh := ' ';
end;

constructor TPanelNode.Create(AR,AG,AB: Integer; ACh: UnicodeChar);
begin
  inherited Create;
  FBgR := AR; FBgG := AG; FBgB := AB;
  FCh := ACh;
end;

procedure TPanelNode.SetBgColor(AR, AG, AB: Integer);
begin
  FBgR := AR; FBgG := AG; FBgB := AB;
end;

procedure TPanelNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TPanelNode.Render;
begin
  // 设置面板背景色
  UiSetBg24(FBgR,FBgG,FBgB);
  // 使用可配置填充字符 FCh（默认空格）绘制面板区域
  UiFillRect(FRect.X, FRect.Y, FRect.W, FRect.H, FCh);
  // 重置属性
  UiAttrReset;
  // 调用可选覆盖渲染回调（用于在面板上输出调试文本等）
  if Assigned(FOnRender) then FOnRender(FRect);
end;

function TPanelNode.HandleEvent(const E: term_event_t): boolean;
begin
  Result := true;
end;

{ TVBoxNode }

constructor TVBoxNode.Create;
begin
  inherited Create;
  FPadding.Top := 0; FPadding.Right := 0; FPadding.Bottom := 0; FPadding.Left := 0;
  FGap := 0;
end;

procedure TVBoxNode.SetPadding(ATop, ARight, ABottom, ALeft: term_size_t);
begin
  FPadding.Top := ATop; FPadding.Right := ARight; FPadding.Bottom := ABottom; FPadding.Left := ALeft;
end;

procedure TVBoxNode.SetGap(AGap: term_size_t);
begin
  FGap := AGap;
end;

procedure TVBoxNode.AddFixed(const N: IUiNode; AHeight: term_size_t);
var item: TVBoxItem;
begin
  item.Node := N; item.Fixed := true; item.Size := AHeight; item.Weight := 0;
  SetLength(FItems, Length(FItems)+1);
  FItems[High(FItems)] := item;
end;

procedure TVBoxNode.AddFlex(const N: IUiNode; AWeight: integer);
var item: TVBoxItem;
begin
  if AWeight <= 0 then AWeight := 1;
  item.Node := N; item.Fixed := false; item.Size := 0; item.Weight := AWeight;
  SetLength(FItems, Length(FItems)+1);
  FItems[High(FItems)] := item;
end;


procedure TVBoxNode.SetDebugDecorate(AEnable: boolean);
begin
  FDebugDecorate := AEnable;
end;

procedure TVBoxNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TVBoxNode.Render;
var
  totalFixed: term_size_t;
  totalWeight: integer;
  i: Integer;
  y, allocH, remaining: term_size_t;
  rect: TUiRect;
  inner: TUiRect;
  gaps: term_size_t;
  maxAvailH: term_size_t;
begin
  // inner rect after padding
  inner.X := FRect.X + FPadding.Left;
  inner.Y := FRect.Y + FPadding.Top;
  if FRect.W > (FPadding.Left + FPadding.Right) then inner.W := FRect.W - (FPadding.Left + FPadding.Right)
  else inner.W := 0;
  if FRect.H > (FPadding.Top + FPadding.Bottom) then inner.H := FRect.H - (FPadding.Top + FPadding.Bottom)
  else inner.H := 0;

  // totals
  totalFixed := 0; totalWeight := 0;
  for i := 0 to High(FItems) do
    if FItems[i].Fixed then Inc(totalFixed, FItems[i].Size) else Inc(totalWeight, FItems[i].Weight);

  // total gaps between visible children
  if Length(FItems) > 1 then gaps := (Length(FItems)-1) * FGap else gaps := 0;
  if totalFixed + gaps > inner.H then begin
    // clamp: shrink fixed to fit, drop gaps first
    if gaps >= inner.H then gaps := inner.H else gaps := gaps;
    if totalFixed > inner.H - gaps then totalFixed := inner.H - gaps;
  end;
  // gap 策略与余数策略：
  // - 先扣除间隙（gaps），再按权重用整数除法分配高度
  // - 整除产生的“余数”和 clamp 后的剩余高度由最后一项一次性吃掉
  //   可以避免逐项四舍五入引入的累计误差与行抖动
  remaining := inner.H - totalFixed - gaps;
  if remaining < 0 then remaining := 0;

  // layout
  y := inner.Y;
  for i := 0 to High(FItems) do
  begin
    if FItems[i].Fixed then allocH := FItems[i].Size
    else if totalWeight > 0 then allocH := (remaining * FItems[i].Weight) div totalWeight
    else allocH := 0;
    // Clamp each item to remaining vertical space
    maxAvailH := (inner.Y + inner.H) - y;
    if (inner.Y + inner.H <= y) then maxAvailH := 0;
    if allocH > maxAvailH then allocH := maxAvailH;
    // 最后一项吃剩余空间：保证不为负，兼容小终端尺寸（仅布局约束，不改变现有行为）
    if i = High(FItems) then
    begin
      if (inner.Y + inner.H > y) then allocH := (inner.Y + inner.H) - y else allocH := 0;
    end;



    rect.X := inner.X; rect.Y := y; rect.W := inner.W; rect.H := allocH;
    if (allocH > 0) and Assigned(FItems[i].Node) then
    begin
      FItems[i].Node.SetRect(rect);
      FItems[i].Node.Render;
    end;
      if FDebugDecorate then
      begin
        UiSetFg24(120,120,120);
        if rect.H > 0 then
        begin
          UiFillRect(rect.X, rect.Y, rect.W, 1, '-');
          UiFillRect(rect.X, rect.Y + rect.H - 1, rect.W, 1, '-');
        end;
        UiAttrReset;
      end;

    Inc(y, allocH);
    if i <> High(FItems) then Inc(y, FGap);
  end;
end;

function TVBoxNode.HandleEvent(const E: term_event_t): boolean;
var i: Integer;
begin
  Result := true;
  for i := 0 to High(FItems) do
    if Assigned(FItems[i].Node) then
      if not FItems[i].Node.HandleEvent(E) then Exit(false);
end;

{ THBoxNode }

constructor THBoxNode.Create;
begin
  inherited Create;
  FPadding.Top := 0; FPadding.Right := 0; FPadding.Bottom := 0; FPadding.Left := 0;
  FGap := 0;
end;

procedure THBoxNode.SetPadding(ATop, ARight, ABottom, ALeft: term_size_t);
begin
  FPadding.Top := ATop; FPadding.Right := ARight; FPadding.Bottom := ABottom; FPadding.Left := ALeft;
end;

procedure THBoxNode.SetGap(AGap: term_size_t);
begin
  FGap := AGap;
end;

procedure THBoxNode.AddFixed(const N: IUiNode; AWidth: term_size_t);
var item: THBoxItem;
begin
  item.Node := N; item.Fixed := true; item.Size := AWidth; item.Weight := 0;
  SetLength(FItems, Length(FItems)+1);
  FItems[High(FItems)] := item;
end;

procedure THBoxNode.SetDebugDecorate(AEnable: boolean);
begin
  FDebugDecorate := AEnable;
end;

procedure THBoxNode.AddFlex(const N: IUiNode; AWeight: integer);
var item: THBoxItem;
begin
  if AWeight <= 0 then AWeight := 1;
  item.Node := N; item.Fixed := false; item.Size := 0; item.Weight := AWeight;
  SetLength(FItems, Length(FItems)+1);
  FItems[High(FItems)] := item;
end;

procedure THBoxNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure THBoxNode.Render;
var
  totalFixed: term_size_t;
  totalWeight: integer;
  i: Integer;
  x, allocW: term_size_t;
  rect: TUiRect;
  inner: TUiRect;
  gaps: term_size_t;
  maxAvailW: term_size_t;
begin
  // inner rect after padding
  inner.X := FRect.X + FPadding.Left;
  inner.Y := FRect.Y + FPadding.Top;
  if FRect.W > (FPadding.Left + FPadding.Right) then inner.W := FRect.W - (FPadding.Left + FPadding.Right)
  else inner.W := 0;
  if FRect.H > (FPadding.Top + FPadding.Bottom) then inner.H := FRect.H - (FPadding.Top + FPadding.Bottom)
  else inner.H := 0;

  totalFixed := 0; totalWeight := 0;
  for i := 0 to High(FItems) do
    if FItems[i].Fixed then Inc(totalFixed, FItems[i].Size) else Inc(totalWeight, FItems[i].Weight);

  if Length(FItems) > 1 then gaps := (Length(FItems)-1) * FGap else gaps := 0;
  if totalFixed + gaps > inner.W then begin
    if gaps >= inner.W then gaps := inner.W else gaps := gaps;
    if totalFixed > inner.W - gaps then totalFixed := inner.W - gaps;
  end;
  // gap 策略与余数策略：
  // - 先扣除间隙（gaps），再按权重用整数除法分配宽度
  // - 整除产生的“余数”和 clamp 后的剩余宽度由最后一项一次性吃掉
  //   可以避免逐项四舍五入引入的累计误差与列抖动
  x := inner.X;
  for i := 0 to High(FItems) do
  begin
    if FItems[i].Fixed then allocW := FItems[i].Size
    else if totalWeight > 0 then allocW := ((inner.W - totalFixed - gaps) * FItems[i].Weight) div totalWeight
    else allocW := 0;

    rect.X := x; rect.Y := inner.Y; rect.W := allocW; rect.H := inner.H;
    // Clamp each item to remaining horizontal space
    maxAvailW := (inner.X + inner.W) - x;

    if (inner.X + inner.W <= x) then maxAvailW := 0;
    if allocW > maxAvailW then allocW := maxAvailW;
    // 最后一项吃剩余空间：保证不为负，兼容小终端尺寸（仅布局约束，不改变现有行为）
    if i = High(FItems) then
      if FDebugDecorate then
      begin
        UiSetFg24(120,120,120);
        if rect.H > 0 then
        begin
          UiFillRect(rect.X, rect.Y, rect.W, 1, '-');
          UiFillRect(rect.X, rect.Y + rect.H - 1, rect.W, 1, '-');
        end;
        UiAttrReset;
      end;

    begin
      if (inner.X + inner.W > x) then allocW := (inner.X + inner.W) - x else allocW := 0;
    end;

    rect.X := x; rect.Y := inner.Y; rect.W := allocW; rect.H := inner.H;
    if (allocW > 0) and Assigned(FItems[i].Node) then
    begin
      FItems[i].Node.SetRect(rect);
      FItems[i].Node.Render;
      if FDebugDecorate then
      begin
        UiSetFg24(120,120,120);
        if rect.H > 0 then
        begin
          UiFillRect(rect.X, rect.Y, rect.W, 1, '-');
          UiFillRect(rect.X, rect.Y + rect.H - 1, rect.W, 1, '-');
        end;
        UiAttrReset;
      end;
    end;
    Inc(x, allocW);
    if i <> High(FItems) then Inc(x, FGap);
  end;
end;

function THBoxNode.HandleEvent(const E: term_event_t): boolean;
var i: Integer;
begin
  Result := true;
  for i := 0 to High(FItems) do
    if Assigned(FItems[i].Node) then
      if not FItems[i].Node.HandleEvent(E) then Exit(false);
end;

end.

