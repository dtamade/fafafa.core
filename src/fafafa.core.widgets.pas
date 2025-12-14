unit fafafa.core.widgets;

{$mode objfpc}{$H+}

{**
 * 基础终端组件库（初版）
 * - ITerminalWidget：组件接口
 * - TTerminalWidget：基础组件类（容器）
 * - TLabelWidget：标签
 * - TButtonWidget：按钮（带 OnClick）
 *
 * 依赖：fafafa.core.term（ITerminal/ITerminalOutput/ITerminalInput 等）
 *}

interface

uses
  Classes, SysUtils, fafafa.core.math,
  fafafa.core.term;

type
  // 轻量矩形类型（避免依赖 LCL.Types 的 Left/Top/Right/Bottom 差异）
  TRect = record
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
  end;



  TWidgetID = type string;

  // 点击事件
  TWidgetClickEvent = procedure(Sender: TObject) of object;

  // 极简鼠标事件类型（暂不依赖终端底层定义）
  TMouseEventType = (meMove, meButtonDown, meButtonUp, meWheel);
  TMouseEvent = record
    EventType: TMouseEventType;
    X, Y: Integer;
    Button: Integer;
    Delta: Integer;
  end;

  // 组件接口
  ITerminalWidget = interface(IInterface)
  ['{7B8E5B8E-0D6D-45F9-A3F4-7E1B0CFE2D6B}']
    // 标识与层级
    function GetID: TWidgetID;
    function GetParent: ITerminalWidget;
    procedure SetParent(const AParent: ITerminalWidget);

    // 几何与状态
    function GetBounds: TRect;
    procedure SetBounds(const R: TRect);
    function GetVisible: Boolean;
    procedure SetVisible(AValue: Boolean);
    function GetFocused: Boolean;
    procedure SetFocused(AValue: Boolean);

    // 子组件
    procedure AddChild(const AChild: ITerminalWidget);
    procedure RemoveChild(const AChild: ITerminalWidget);
    function ChildCount: Integer;
    function GetChild(Index: Integer): ITerminalWidget;

    // 渲染与事件
    procedure Render(const Output: ITerminalOutput);
    function HandleKey(const Key: TKeyEvent): Boolean;   // 处理键盘事件，返回是否已消费
    function HandleMouse(const Mouse: TMouseEvent): Boolean; // 处理鼠标事件
    procedure Invalidate; // 标记需要重绘

    // 属性
    property ID: TWidgetID read GetID;
    property Parent: ITerminalWidget read GetParent write SetParent;
    property Bounds: TRect read GetBounds write SetBounds;
    property Visible: Boolean read GetVisible write SetVisible;
    property Focused: Boolean read GetFocused write SetFocused;
  end;

  // 基础组件（容器）
  TTerminalWidget = class(TInterfacedObject, ITerminalWidget)
  private
    FID: TWidgetID;
    FParent: ITerminalWidget;
    FBounds: TRect;
    FVisible: Boolean;
    FFocused: Boolean;
    FChildren: TInterfaceList;
    FInvalidated: Boolean;
  protected
    procedure DrawSelf(const Output: ITerminalOutput); virtual;
  public
    constructor Create(const AID: TWidgetID; const R: TRect);
    destructor Destroy; override;

    // ITerminalWidget
    function GetID: TWidgetID;
    function GetParent: ITerminalWidget;
    procedure SetParent(const AParent: ITerminalWidget);

    function GetBounds: TRect;
    procedure SetBounds(const R: TRect);
    function GetVisible: Boolean;
    procedure SetVisible(AValue: Boolean);
    function GetFocused: Boolean;
    procedure SetFocused(AValue: Boolean);

    procedure AddChild(const AChild: ITerminalWidget);
    procedure RemoveChild(const AChild: ITerminalWidget);
    function ChildCount: Integer;
    function GetChild(Index: Integer): ITerminalWidget;

    procedure Render(const Output: ITerminalOutput); virtual;
    function HandleKey(const Key: TKeyEvent): Boolean; virtual;
    function HandleMouse(const Mouse: TMouseEvent): Boolean; virtual;
    procedure Invalidate; virtual;
  end;

  // 标签组件
  TLabelWidget = class(TTerminalWidget)
  private
    FText: string;
  protected
    procedure DrawSelf(const Output: ITerminalOutput); override;
  public
    constructor Create(const AID: TWidgetID; const R: TRect; const AText: string);
    property Text: string read FText write FText;
  end;

  // 按钮组件
  TButtonWidget = class(TTerminalWidget)
  private
    FCaption: string;
    FOnClick: TWidgetClickEvent;
    FPressed: Boolean;
  protected
    procedure DrawSelf(const Output: ITerminalOutput); override;
  public
    constructor Create(const AID: TWidgetID; const R: TRect; const ACaption: string);
    function HandleKey(const Key: TKeyEvent): Boolean; override;
    function HandleMouse(const Mouse: TMouseEvent): Boolean; override;


    procedure Click;

    property Caption: string read FCaption write FCaption;
    property OnClick: TWidgetClickEvent read FOnClick write FOnClick;
  end;

// 工具函数：在给定区域内输出单行文本（自动截断）
procedure WriteClippedLine(const Output: ITerminalOutput; X, Y, Width: Integer; const S: string);

// 简便矩形构造函数（对外导出，供 demo 使用）
function MakeRect(aX, aY, aW, aH: Integer): TRect; inline;


implementation


function MakeRect(aX, aY, aW, aH: Integer): TRect; inline;
begin
  Result.X := aX;
  Result.Y := aY;
  Result.Width := aW;
  Result.Height := aH;
end;



{ TTerminalWidget }

constructor TTerminalWidget.Create(const AID: TWidgetID; const R: TRect);
begin
  inherited Create;
  FID := AID;
  FBounds := R;
  FVisible := True;
  FFocused := False;
  FChildren := TInterfaceList.Create;
  FInvalidated := True;
end;

destructor TTerminalWidget.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

function TTerminalWidget.GetID: TWidgetID; begin Result := FID; end;
function TTerminalWidget.GetParent: ITerminalWidget; begin Result := FParent; end;
procedure TTerminalWidget.SetParent(const AParent: ITerminalWidget); begin FParent := AParent; end;
function TTerminalWidget.GetBounds: TRect; begin Result := FBounds; end;
procedure TTerminalWidget.SetBounds(const R: TRect); begin FBounds := R; Invalidate; end;
function TTerminalWidget.GetVisible: Boolean; begin Result := FVisible; end;
procedure TTerminalWidget.SetVisible(AValue: Boolean); begin FVisible := AValue; Invalidate; end;
function TTerminalWidget.GetFocused: Boolean; begin Result := FFocused; end;
procedure TTerminalWidget.SetFocused(AValue: Boolean); begin FFocused := AValue; Invalidate; end;

procedure TTerminalWidget.AddChild(const AChild: ITerminalWidget);
begin
  if Assigned(AChild) then
  begin
    AChild.SetParent(Self);
    FChildren.Add(AChild);
    Invalidate;
  end;
end;

procedure TTerminalWidget.RemoveChild(const AChild: ITerminalWidget);
var I: Integer;
begin
  for I := 0 to FChildren.Count - 1 do
    if ITerminalWidget(FChildren[I]) = AChild then
    begin
      FChildren.Delete(I);
      Break;
    end;
  Invalidate;
end;

function TTerminalWidget.ChildCount: Integer; begin Result := FChildren.Count; end;
function TTerminalWidget.GetChild(Index: Integer): ITerminalWidget;
begin
  if (Index >= 0) and (Index < FChildren.Count) then
    Result := ITerminalWidget(FChildren[Index])
  else
    Result := nil;
end;

procedure TTerminalWidget.DrawSelf(const Output: ITerminalOutput);
var
  i: Integer;
begin
  // 缺省容器：仅绘制边框（简化：单线框，ASCII）
  if (FBounds.Width >= 2) and (FBounds.Height >= 2) then
  begin
    // 顶边
    Output.MoveCursor(FBounds.X, FBounds.Y);
    Output.Write('+' + StringOfChar('-', Max(0, FBounds.Width - 2)) + '+');
    // 侧边
    for i := 1 to Max(0, FBounds.Height - 2) do
    begin
      Output.MoveCursor(FBounds.X, FBounds.Y + i);
      Output.Write('|' + StringOfChar(' ', Max(0, FBounds.Width - 2)) + '|');
    end;
    // 底边
    Output.MoveCursor(FBounds.X, FBounds.Y + FBounds.Height - 1);
    Output.Write('+' + StringOfChar('-', Max(0, FBounds.Width - 2)) + '+');
  end;
end;

procedure TTerminalWidget.Render(const Output: ITerminalOutput);
var I: Integer;
begin
  if not FVisible then Exit;
  if FInvalidated then
  begin
    DrawSelf(Output);
    FInvalidated := False;
  end;
  // 渲染子组件
  for I := 0 to FChildren.Count - 1 do
    ITerminalWidget(FChildren[I]).Render(Output);
end;

function TTerminalWidget.HandleKey(const Key: TKeyEvent): Boolean;
begin
  // 容器缺省不处理
  Result := False;
end;

function TTerminalWidget.HandleMouse(const Mouse: TMouseEvent): Boolean;
begin
  // 简化：不做命中测试，留给上层管理
  Result := False;
end;

procedure TTerminalWidget.Invalidate;
begin
  FInvalidated := True;
end;

{ TLabelWidget }

constructor TLabelWidget.Create(const AID: TWidgetID; const R: TRect; const AText: string);
begin
  inherited Create(AID, R);
  FText := AText;
end;

procedure TLabelWidget.DrawSelf(const Output: ITerminalOutput);
begin
  // 标签不绘制边框，仅绘制文本
  WriteClippedLine(Output, FBounds.X, FBounds.Y, Max(0, FBounds.Width), FText);
end;

{ TButtonWidget }

constructor TButtonWidget.Create(const AID: TWidgetID; const R: TRect; const ACaption: string);
begin
  inherited Create(AID, R);
  FCaption := ACaption;
  FPressed := False;
end;

procedure TButtonWidget.DrawSelf(const Output: ITerminalOutput);
var W: Integer; S: string; Xc: Integer;
begin
  inherited DrawSelf(Output); // 先画边框
  // 按钮文字绘制在中间
  S := ' ' + FCaption + ' ';
  W := Max(0, FBounds.Width - 2);
  if Length(S) > W then S := Copy(S, 1, W);
  Xc := FBounds.X + 1 + Max(0, (W - Length(S)) div 2);
  Output.MoveCursor(Xc, FBounds.Y + FBounds.Height div 2);
  if FFocused then Output.SetAttribute(taReverse);
  if FPressed then Output.SetAttribute(taBold);
  Output.Write(S);
  Output.ResetAttributes;
end;

function TButtonWidget.HandleKey(const Key: TKeyEvent): Boolean;
begin
  // 回车/空格触发
  if (Key.KeyType = ktEnter) or ((Key.KeyType = ktChar) and (UpCase(Key.KeyChar) = ' ')) then
  begin
    FPressed := True;
    Invalidate;
    Click;
    FPressed := False;
    Invalidate;
    Exit(True);
  end;
  Result := False;
end;

function TButtonWidget.HandleMouse(const Mouse: TMouseEvent): Boolean;
begin
  Result := False;
  // 简化：任何鼠标按下都触发点击
  if Mouse.EventType = meButtonDown then
  begin
    FPressed := True;
    Invalidate;
    Click;
    FPressed := False;
    Invalidate;
    Result := True;
  end;
end;

procedure TButtonWidget.Click;
begin
  if Assigned(FOnClick) then FOnClick(Self);
end;

{ Utils }

procedure WriteClippedLine(const Output: ITerminalOutput; X, Y, Width: Integer; const S: string);
var Txt: string;
begin
  if Width <= 0 then Exit;
  Txt := S;
  if Length(Txt) > Width then Txt := Copy(Txt, 1, Width);
  Output.MoveCursor(X, Y);
  Output.Write(Txt + StringOfChar(' ', Max(0, Width - Length(Txt))));
end;

end.

