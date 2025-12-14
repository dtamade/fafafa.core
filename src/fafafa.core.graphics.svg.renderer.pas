{
  SVG渲染器集成模块
  将SVG路径渲染到TBitmap32，支持抗锯齿和高质量渲染
  
  特性：
  - 与TBitmap32深度集成
  - 支持抗锯齿渲染
  - 硬件加速混合
  - 渐变填充
  - 描边样式
  
  作者: FaFaFa Core Framework
  许可: MIT License
}
unit fafafa.core.graphics.svg.renderer;

{$mode objfpc}{$H+}
{$ASMMODE Intel}

interface

uses
  SysUtils, Classes, fafafa.core.math, Types,
  fafafa.core.graphics,
  fafafa.core.graphics.svg.improved;

type
  // 渐变类型
  TGradientType = (
    gtLinear,   // 线性渐变
    gtRadial    // 径向渐变
  );

  // 渐变停止点
  TGradientStop = record
    Offset: Single;    // 0.0 到 1.0
    Color: TColor32;
  end;

  // 渐变定义
  TGradient = class
  private
    FType: TGradientType;
    FStops: array of TGradientStop;
    FStartPoint: TPointF;
    FEndPoint: TPointF;
    FCenter: TPointF;
    FRadius: Single;
    FTransform: TMatrix2D;
    
    function InterpolateColor(Offset: Single): TColor32;
  public
    constructor Create(AType: TGradientType);
    destructor Destroy; override;
    
    procedure AddStop(Offset: Single; Color: TColor32);
    procedure ClearStops;
    function GetColorAt(X, Y: Single): TColor32;
    
    property GradientType: TGradientType read FType;
    property Transform: TMatrix2D read FTransform write FTransform;
  end;

  // 描边样式
  TStrokeStyle = record
    Width: Single;
    Color: TColor32;
    DashArray: array of Single;
    DashOffset: Single;
    LineCap: (lcButt, lcRound, lcSquare);
    LineJoin: (ljMiter, ljRound, ljBevel);
    MiterLimit: Single;
  end;

  // 填充样式
  TFillStyle = record
    Color: TColor32;
    Gradient: TGradient;
    Opacity: Byte;
    Rule: TSVGFillRule;
  end;

  { TSVGRasterizer - 高性能SVG光栅化器 }
  TSVGRasterizer = class
  private
    FBitmap: TBitmap32;
    FAntiAlias: Boolean;
    FSampleBits: Integer;  // 抗锯齿采样位数 (2, 4, 8)
    FTransform: TMatrix2D;
    
    // 边缘表结构（用于扫描线填充）
    type
      PEdge = ^TEdge;
      TEdge = record
        YMin, YMax: Integer;
        X: Single;
        DX: Single;  // 斜率的倒数
        Next: PEdge;
      end;
    
    var
      FEdgeTable: array of PEdge;
      FActiveEdgeList: PEdge;
    
    // 内部渲染函数
    procedure BuildEdgeTable(const Points: array of TPointF);
    procedure ClearEdgeTable;
    procedure ScanlineFill(const FillStyle: TFillStyle);
    procedure DrawAALine(X1, Y1, X2, Y2: Single; Color: TColor32; Width: Single);
    procedure DrawThickLine(X1, Y1, X2, Y2: Single; const Style: TStrokeStyle);
    
    // 抗锯齿辅助
    function ComputeCoverage(X, Y: Single; Radius: Single): Byte;
    procedure SetAAPixel(X, Y: Integer; Color: TColor32; Coverage: Byte);
    
  public
    constructor Create(ABitmap: TBitmap32);
    destructor Destroy; override;
    
    // 主渲染方法
    procedure RenderPath(const Path: TSVGPath; const FillStyle: TFillStyle; 
      const StrokeStyle: TStrokeStyle);
    procedure Clear(Color: TColor32 = 0);
    
    // 渲染设置
    property AntiAlias: Boolean read FAntiAlias write FAntiAlias;
    property SampleBits: Integer read FSampleBits write FSampleBits;
    property Transform: TMatrix2D read FTransform write FTransform;
  end;

  { TSVGRenderer - 完整的SVG渲染器 }
  TSVGRenderer = class
  private
    FBitmap: TBitmap32;
    FRasterizer: TSVGRasterizer;
    FViewBox: TRectF;
    FPreserveAspectRatio: Boolean;
    
    // 样式栈（用于继承）
    FStyleStack: TList;
    
    function CalculateTransform: TMatrix2D;
    procedure PushStyle(const Style: TSVGStyle);
    procedure PopStyle;
    function GetCurrentStyle: TSVGStyle;
    
  public
    constructor Create(ABitmap: TBitmap32);
    destructor Destroy; override;
    
    // 渲染单个路径
    procedure RenderPath(const Path: TSVGPath; const Style: TSVGStyle);
    
    // 渲染路径组
    procedure BeginScene(const ViewBox: TRectF);
    procedure EndScene;
    
    // 批量渲染优化
    procedure RenderPaths(const Paths: array of TSVGPath; 
      const Styles: array of TSVGStyle);
    
    // 特效
    procedure RenderWithShadow(const Path: TSVGPath; const Style: TSVGStyle;
      ShadowColor: TColor32; ShadowOffset: TPointF; ShadowBlur: Single);
    
    property ViewBox: TRectF read FViewBox write FViewBox;
    property PreserveAspectRatio: Boolean read FPreserveAspectRatio write FPreserveAspectRatio;
  end;

  { TSVGIconRenderer - 图标渲染器（优化小尺寸） }
  TSVGIconRenderer = class
  private
    FCache: TList;  // 缓存渲染结果
    FRenderer: TSVGRenderer;
    
    type
      PCacheEntry = ^TCacheEntry;
      TCacheEntry = record
        Hash: Cardinal;
        Size: TSize;
        Bitmap: TBitmap32;
      end;
    
    function ComputeHash(const Path: TSVGPath; Size: TSize): Cardinal;
    function FindInCache(Hash: Cardinal; Size: TSize): TBitmap32;
    procedure AddToCache(Hash: Cardinal; Size: TSize; Bitmap: TBitmap32);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 渲染图标到指定大小
    function RenderIcon(const Path: TSVGPath; Size: Integer; 
      Color: TColor32 = clBlack32): TBitmap32;
    
    // 批量渲染多个尺寸
    procedure RenderMultiSize(const Path: TSVGPath; 
      const Sizes: array of Integer; Color: TColor32 = clBlack32);
    
    // 清理缓存
    procedure ClearCache;
  end;

// 实用函数
function CreateStrokeStyle(Width: Single; Color: TColor32): TStrokeStyle;
function CreateFillStyle(Color: TColor32): TFillStyle;
function CreateGradientFill(Gradient: TGradient): TFillStyle;

// 便捷渲染函数
procedure RenderSVGToBitmap(const SVGPath: string; Bitmap: TBitmap32; 
  const ViewBox: TRectF);
procedure RenderSVGIcon(const SVGPath: string; Bitmap: TBitmap32; 
  Size: Integer; Color: TColor32 = clBlack32);

implementation

{ TGradient }

constructor TGradient.Create(AType: TGradientType);
begin
  inherited Create;
  FType := AType;
  SetLength(FStops, 0);
  FTransform := IdentityMatrix;
  FRadius := 1.0;
end;

destructor TGradient.Destroy;
begin
  SetLength(FStops, 0);
  inherited Destroy;
end;

procedure TGradient.AddStop(Offset: Single; Color: TColor32);
var
  Len: Integer;
begin
  Len := Length(FStops);
  SetLength(FStops, Len + 1);
  FStops[Len].Offset := EnsureRange(Offset, 0, 1);
  FStops[Len].Color := Color;
  
  // 保持停止点按offset排序
  // 简单的插入排序
  while (Len > 0) and (FStops[Len].Offset < FStops[Len-1].Offset) do
  begin
    // 交换
    FStops[Len] := FStops[Len-1];
    FStops[Len-1].Offset := Offset;
    FStops[Len-1].Color := Color;
    Dec(Len);
  end;
end;

procedure TGradient.ClearStops;
begin
  SetLength(FStops, 0);
end;

function TGradient.InterpolateColor(Offset: Single): TColor32;
var
  I: Integer;
  T: Single;
  C1, C2: TColor32;
  R1, G1, B1, A1: Byte;
  R2, G2, B2, A2: Byte;
begin
  Offset := EnsureRange(Offset, 0, 1);
  
  if Length(FStops) = 0 then
  begin
    Result := clBlack32;
    Exit;
  end;
  
  if Length(FStops) = 1 then
  begin
    Result := FStops[0].Color;
    Exit;
  end;
  
  // 找到offset所在的区间
  for I := 1 to High(FStops) do
  begin
    if Offset <= FStops[I].Offset then
    begin
      // 在FStops[I-1]和FStops[I]之间插值
      if FStops[I].Offset = FStops[I-1].Offset then
        T := 0
      else
        T := (Offset - FStops[I-1].Offset) / 
             (FStops[I].Offset - FStops[I-1].Offset);
      
      C1 := FStops[I-1].Color;
      C2 := FStops[I].Color;
      
      // 分解颜色
      A1 := C1 shr 24;
      R1 := (C1 shr 16) and $FF;
      G1 := (C1 shr 8) and $FF;
      B1 := C1 and $FF;
      
      A2 := C2 shr 24;
      R2 := (C2 shr 16) and $FF;
      G2 := (C2 shr 8) and $FF;
      B2 := C2 and $FF;
      
      // 线性插值
      Result := 
        (Round(A1 + T * (A2 - A1)) shl 24) or
        (Round(R1 + T * (R2 - R1)) shl 16) or
        (Round(G1 + T * (G2 - G1)) shl 8) or
        Round(B1 + T * (B2 - B1));
      
      Exit;
    end;
  end;
  
  // Offset超过最后一个停止点
  Result := FStops[High(FStops)].Color;
end;

function TGradient.GetColorAt(X, Y: Single): TColor32;
var
  Offset: Single;
  DX, DY, Dist: Single;
begin
  case FType of
    gtLinear:
      begin
        // 计算点到起点的投影
        DX := FEndPoint.X - FStartPoint.X;
        DY := FEndPoint.Y - FStartPoint.Y;
        Dist := Sqrt(DX * DX + DY * DY);
        
        if Dist > 0 then
        begin
          Offset := ((X - FStartPoint.X) * DX + (Y - FStartPoint.Y) * DY) / (Dist * Dist);
          Result := InterpolateColor(Offset);
        end
        else
          Result := InterpolateColor(0);
      end;
      
    gtRadial:
      begin
        // 计算点到中心的距离
        DX := X - FCenter.X;
        DY := Y - FCenter.Y;
        Dist := Sqrt(DX * DX + DY * DY);
        
        if FRadius > 0 then
          Offset := Dist / FRadius
        else
          Offset := 0;
          
        Result := InterpolateColor(Offset);
      end;
  end;
end;

{ TSVGRasterizer }

constructor TSVGRasterizer.Create(ABitmap: TBitmap32);
begin
  inherited Create;
  FBitmap := ABitmap;
  FAntiAlias := True;
  FSampleBits := 4;
  FTransform := IdentityMatrix;
  SetLength(FEdgeTable, 0);
  FActiveEdgeList := nil;
end;

destructor TSVGRasterizer.Destroy;
begin
  ClearEdgeTable;
  inherited Destroy;
end;

procedure TSVGRasterizer.ClearEdgeTable;
var
  I: Integer;
  Edge, Next: PEdge;
begin
  for I := 0 to High(FEdgeTable) do
  begin
    Edge := FEdgeTable[I];
    while Edge <> nil do
    begin
      Next := Edge^.Next;
      Dispose(Edge);
      Edge := Next;
    end;
    FEdgeTable[I] := nil;
  end;
  SetLength(FEdgeTable, 0);
  FActiveEdgeList := nil;
end;

procedure TSVGRasterizer.BuildEdgeTable(const Points: array of TPointF);
var
  I, J, YMin, YMax: Integer;
  P1, P2: TPointF;
  Edge: PEdge;
  DX, DY: Single;
begin
  ClearEdgeTable;
  
  if Length(Points) < 3 then Exit;
  
  // 找到Y范围
  YMin := Round(Points[0].Y);
  YMax := YMin;
  for I := 1 to High(Points) do
  begin
    J := Round(Points[I].Y);
    if J < YMin then YMin := J;
    if J > YMax then YMax := J;
  end;
  
  // 分配边缘表
  SetLength(FEdgeTable, YMax - YMin + 1);
  for I := 0 to High(FEdgeTable) do
    FEdgeTable[I] := nil;
  
  // 构建边缘
  for I := 0 to High(Points) do
  begin
    P1 := Points[I];
    if I = High(Points) then
      P2 := Points[0]
    else
      P2 := Points[I + 1];
    
    // 跳过水平边
    if Round(P1.Y) = Round(P2.Y) then Continue;
    
    New(Edge);
    
    // 确保P1.Y < P2.Y
    if P1.Y > P2.Y then
    begin
      // 交换
      Edge^.YMin := Round(P2.Y);
      Edge^.YMax := Round(P1.Y);
      Edge^.X := P2.X;
      DX := P1.X - P2.X;
      DY := P1.Y - P2.Y;
    end
    else
    begin
      Edge^.YMin := Round(P1.Y);
      Edge^.YMax := Round(P2.Y);
      Edge^.X := P1.X;
      DX := P2.X - P1.X;
      DY := P2.Y - P1.Y;
    end;
    
    Edge^.DX := DX / DY;  // 斜率的倒数
    
    // 插入到边缘表
    J := Edge^.YMin - YMin;
    if (J >= 0) and (J <= High(FEdgeTable)) then
    begin
      Edge^.Next := FEdgeTable[J];
      FEdgeTable[J] := Edge;
    end
    else
      Dispose(Edge);
  end;
end;

procedure TSVGRasterizer.ScanlineFill(const FillStyle: TFillStyle);
var
  Y, X, I: Integer;
  Edge, PrevEdge, TempEdge: PEdge;
  Intersections: array of Single;
  IntersectionCount: Integer;
  Color: TColor32;
  Coverage: Byte;
begin
  if Length(FEdgeTable) = 0 then Exit;
  
  SetLength(Intersections, 100);  // 预分配
  
  // 扫描每一行
  for Y := 0 to High(FEdgeTable) do
  begin
    // 添加新的活动边
    Edge := FEdgeTable[Y];
    while Edge <> nil do
    begin
      TempEdge := Edge^.Next;
      Edge^.Next := FActiveEdgeList;
      FActiveEdgeList := Edge;
      Edge := TempEdge;
    end;
    
    // 收集交点
    IntersectionCount := 0;
    Edge := FActiveEdgeList;
    while Edge <> nil do
    begin
      if IntersectionCount >= Length(Intersections) then
        SetLength(Intersections, IntersectionCount + 100);
      
      Intersections[IntersectionCount] := Edge^.X;
      Inc(IntersectionCount);
      
      Edge := Edge^.Next;
    end;
    
    // 排序交点
    for I := 0 to IntersectionCount - 2 do
      for X := I + 1 to IntersectionCount - 1 do
        if Intersections[I] > Intersections[X] then
        begin
          // 交换
          Color := Round(Intersections[I]);
          Intersections[I] := Intersections[X];
          Intersections[X] := Color;
        end;
    
    // 填充扫描线
    I := 0;
    while I < IntersectionCount - 1 do
    begin
      // 填充从Intersections[I]到Intersections[I+1]
      for X := Round(Intersections[I]) to Round(Intersections[I + 1]) do
      begin
        if (X >= 0) and (X < FBitmap.Width) and 
           (Y >= 0) and (Y < FBitmap.Height) then
        begin
          if FillStyle.Gradient <> nil then
            Color := FillStyle.Gradient.GetColorAt(X, Y)
          else
            Color := FillStyle.Color;
          
          // 应用透明度
          Color := (Color and $00FFFFFF) or (Cardinal(FillStyle.Opacity) shl 24);
          
          if FAntiAlias then
          begin
            Coverage := ComputeCoverage(X, Y, 0.5);
            SetAAPixel(X, Y, Color, Coverage);
          end
          else
            FBitmap.Pixels[X, Y] := BlendColor(FBitmap.Pixels[X, Y], Color);
        end;
      end;
      
      Inc(I, 2);  // 跳到下一对
    end;
    
    // 更新活动边并删除完成的边
    PrevEdge := nil;
    Edge := FActiveEdgeList;
    while Edge <> nil do
    begin
      // 更新X坐标
      Edge^.X := Edge^.X + Edge^.DX;
      
      // 检查是否完成
      if Y >= Edge^.YMax - 1 then
      begin
        // 从活动列表中删除
        if PrevEdge = nil then
          FActiveEdgeList := Edge^.Next
        else
          PrevEdge^.Next := Edge^.Next;
        
        TempEdge := Edge^.Next;
        Dispose(Edge);
        Edge := TempEdge;
      end
      else
      begin
        PrevEdge := Edge;
        Edge := Edge^.Next;
      end;
    end;
  end;
end;

procedure TSVGRasterizer.DrawAALine(X1, Y1, X2, Y2: Single; Color: TColor32; Width: Single);
var
  DX, DY, Dist: Single;
  Steps, I: Integer;
  X, Y, XStep, YStep: Single;
  IX, IY: Integer;
  Coverage: Byte;
  Radius: Single;
begin
  DX := X2 - X1;
  DY := Y2 - Y1;
  Dist := Sqrt(DX * DX + DY * DY);
  
  if Dist < 0.001 then Exit;
  
  Steps := Round(Dist * 2);  // 超采样
  if Steps < 1 then Steps := 1;
  
  XStep := DX / Steps;
  YStep := DY / Steps;
  Radius := Width / 2;
  
  X := X1;
  Y := Y1;
  
  for I := 0 to Steps do
  begin
    // 绘制圆形笔刷
    for IY := Round(Y - Radius - 1) to Round(Y + Radius + 1) do
    begin
      for IX := Round(X - Radius - 1) to Round(X + Radius + 1) do
      begin
        if (IX >= 0) and (IX < FBitmap.Width) and
           (IY >= 0) and (IY < FBitmap.Height) then
        begin
          // 计算到线中心的距离
          DX := IX - X;
          DY := IY - Y;
          Dist := Sqrt(DX * DX + DY * DY);
          
          if Dist <= Radius then
          begin
            if FAntiAlias then
            begin
              Coverage := Round(255 * (1 - Max(0, (Dist - Radius + 1) / 1)));
              SetAAPixel(IX, IY, Color, Coverage);
            end
            else
              FBitmap.Pixels[IX, IY] := Color;
          end;
        end;
      end;
    end;
    
    X := X + XStep;
    Y := Y + YStep;
  end;
end;

procedure TSVGRasterizer.DrawThickLine(X1, Y1, X2, Y2: Single; const Style: TStrokeStyle);
begin
  if Style.Width <= 1 then
    DrawAALine(X1, Y1, X2, Y2, Style.Color, 1)
  else
    DrawAALine(X1, Y1, X2, Y2, Style.Color, Style.Width);
  
  // TODO: 实现虚线样式
end;

function TSVGRasterizer.ComputeCoverage(X, Y: Single; Radius: Single): Byte;
var
  SubX, SubY: Single;
  Count, Total: Integer;
  I, J: Integer;
  Samples: Integer;
begin
  if not FAntiAlias then
  begin
    Result := 255;
    Exit;
  end;
  
  Samples := 1 shl FSampleBits;
  Count := 0;
  Total := Samples * Samples;
  
  // 超采样
  for I := 0 to Samples - 1 do
  begin
    SubY := Y + (I / Samples) - 0.5;
    for J := 0 to Samples - 1 do
    begin
      SubX := X + (J / Samples) - 0.5;
      
      // 简单的点在圆内测试
      if Sqrt(Sqr(SubX - X) + Sqr(SubY - Y)) <= Radius then
        Inc(Count);
    end;
  end;
  
  Result := Round(255 * Count / Total);
end;

procedure TSVGRasterizer.SetAAPixel(X, Y: Integer; Color: TColor32; Coverage: Byte);
var
  BG, FG: TColor32;
  A: Byte;
begin
  if (X < 0) or (X >= FBitmap.Width) or 
     (Y < 0) or (Y >= FBitmap.Height) then Exit;
  
  if Coverage = 0 then Exit;
  
  if Coverage = 255 then
  begin
    FBitmap.Pixels[X, Y] := Color;
    Exit;
  end;
  
  // 混合
  BG := FBitmap.Pixels[X, Y];
  
  // 调整alpha通道
  A := (Color shr 24) and $FF;
  A := (A * Coverage) div 255;
  FG := (Color and $00FFFFFF) or (A shl 24);
  
  // 使用优化的混合函数
  FBitmap.Pixels[X, Y] := BlendColor(BG, FG);
end;

procedure TSVGRasterizer.RenderPath(const Path: TSVGPath; 
  const FillStyle: TFillStyle; const StrokeStyle: TStrokeStyle);
var
  Points: array of TPointF;
  I: Integer;
  Cmd: TSVGCommand;
  CurrentPoint, LastPoint: TPointF;
begin
  if Path.IsEmpty then Exit;
  
  // 展平路径
  Points := Path.Flatten(0.5);
  
  // 应用变换
  for I := 0 to High(Points) do
  begin
    Points[I].X := FTransform.a * Points[I].X + FTransform.c * Points[I].Y + FTransform.e;
    Points[I].Y := FTransform.b * Points[I].X + FTransform.d * Points[I].Y + FTransform.f;
  end;
  
  // 填充
  if FillStyle.Color <> clNone32 then
  begin
    BuildEdgeTable(Points);
    ScanlineFill(FillStyle);
  end;
  
  // 描边
  if (StrokeStyle.Color <> clNone32) and (StrokeStyle.Width > 0) then
  begin
    LastPoint := Points[0];
    for I := 1 to High(Points) do
    begin
      CurrentPoint := Points[I];
      DrawThickLine(LastPoint.X, LastPoint.Y, 
                   CurrentPoint.X, CurrentPoint.Y, StrokeStyle);
      LastPoint := CurrentPoint;
    end;
  end;
end;

procedure TSVGRasterizer.Clear(Color: TColor32);
begin
  FBitmap.Clear(Color);
end;

{ TSVGRenderer }

constructor TSVGRenderer.Create(ABitmap: TBitmap32);
begin
  inherited Create;
  FBitmap := ABitmap;
  FRasterizer := TSVGRasterizer.Create(ABitmap);
  FStyleStack := TList.Create;
  FPreserveAspectRatio := True;
end;

destructor TSVGRenderer.Destroy;
begin
  while FStyleStack.Count > 0 do
    PopStyle;
  FStyleStack.Free;
  FRasterizer.Free;
  inherited Destroy;
end;

function TSVGRenderer.CalculateTransform: TMatrix2D;
var
  ScaleX, ScaleY, Scale: Single;
  TransX, TransY: Single;
begin
  Result := IdentityMatrix;
  
  if (FViewBox.Right - FViewBox.Left <= 0) or 
     (FViewBox.Bottom - FViewBox.Top <= 0) then Exit;
  
  ScaleX := FBitmap.Width / (FViewBox.Right - FViewBox.Left);
  ScaleY := FBitmap.Height / (FViewBox.Bottom - FViewBox.Top);
  
  if FPreserveAspectRatio then
  begin
    Scale := Min(ScaleX, ScaleY);
    ScaleX := Scale;
    ScaleY := Scale;
    
    // 居中
    TransX := (FBitmap.Width - Scale * (FViewBox.Right - FViewBox.Left)) / 2;
    TransY := (FBitmap.Height - Scale * (FViewBox.Bottom - FViewBox.Top)) / 2;
  end
  else
  begin
    TransX := 0;
    TransY := 0;
  end;
  
  // 构建变换矩阵
  Result.a := ScaleX;
  Result.d := ScaleY;
  Result.e := TransX - FViewBox.Left * ScaleX;
  Result.f := TransY - FViewBox.Top * ScaleY;
end;

procedure TSVGRenderer.PushStyle(const Style: TSVGStyle);
var
  P: ^TSVGStyle;
begin
  New(P);
  P^ := Style;
  FStyleStack.Add(P);
end;

procedure TSVGRenderer.PopStyle;
var
  P: ^TSVGStyle;
begin
  if FStyleStack.Count > 0 then
  begin
    P := FStyleStack[FStyleStack.Count - 1];
    Dispose(P);
    FStyleStack.Delete(FStyleStack.Count - 1);
  end;
end;

function TSVGRenderer.GetCurrentStyle: TSVGStyle;
var
  P: ^TSVGStyle;
begin
  if FStyleStack.Count > 0 then
  begin
    P := FStyleStack[FStyleStack.Count - 1];
    Result := P^;
  end
  else
  begin
    // 默认样式
    Result.Fill := clBlack32;
    Result.Stroke := clNone32;
    Result.StrokeWidth := 1;
    Result.FillOpacity := 255;
    Result.StrokeOpacity := 255;
  end;
end;

procedure TSVGRenderer.RenderPath(const Path: TSVGPath; const Style: TSVGStyle);
var
  FillStyle: TFillStyle;
  StrokeStyle: TStrokeStyle;
begin
  // 转换样式
  if Style.HasFill then
  begin
    FillStyle.Color := Style.Fill;
    FillStyle.Opacity := Style.FillOpacity;
    FillStyle.Rule := Style.FillRule;
    FillStyle.Gradient := nil;
  end
  else
    FillStyle.Color := clNone32;
  
  if Style.HasStroke then
  begin
    StrokeStyle.Color := Style.Stroke;
    StrokeStyle.Width := Style.StrokeWidth;
  end
  else
    StrokeStyle.Color := clNone32;
  
  FRasterizer.Transform := CalculateTransform;
  FRasterizer.RenderPath(Path, FillStyle, StrokeStyle);
end;

procedure TSVGRenderer.BeginScene(const ViewBox: TRectF);
begin
  FViewBox := ViewBox;
  FRasterizer.Transform := CalculateTransform;
end;

procedure TSVGRenderer.EndScene;
begin
  // 清理临时资源
  while FStyleStack.Count > 0 do
    PopStyle;
end;

procedure TSVGRenderer.RenderPaths(const Paths: array of TSVGPath; 
  const Styles: array of TSVGStyle);
var
  I: Integer;
begin
  BeginScene(FViewBox);
  try
    for I := 0 to High(Paths) do
    begin
      if I <= High(Styles) then
        RenderPath(Paths[I], Styles[I])
      else
        RenderPath(Paths[I], GetCurrentStyle);
    end;
  finally
    EndScene;
  end;
end;

procedure TSVGRenderer.RenderWithShadow(const Path: TSVGPath; 
  const Style: TSVGStyle; ShadowColor: TColor32; 
  ShadowOffset: TPointF; ShadowBlur: Single);
var
  ShadowBitmap: TBitmap32;
  ShadowStyle: TSVGStyle;
  Transform: TMatrix2D;
begin
  // 创建阴影位图
  ShadowBitmap := TBitmap32.Create;
  try
    ShadowBitmap.SetSize(FBitmap.Width, FBitmap.Height);
    ShadowBitmap.Clear(0);
    
    // 设置阴影样式
    ShadowStyle := Style;
    ShadowStyle.Fill := ShadowColor;
    ShadowStyle.Stroke := ShadowColor;
    
    // 应用偏移
    Transform := CalculateTransform;
    Transform.e := Transform.e + ShadowOffset.X;
    Transform.f := Transform.f + ShadowOffset.Y;
    FRasterizer.Transform := Transform;
    
    // 渲染阴影
    // TODO: 实现高斯模糊
    
    // 混合阴影到主位图
    FBitmap.Draw(0, 0, ShadowBitmap);
    
  finally
    ShadowBitmap.Free;
  end;
  
  // 渲染主路径
  RenderPath(Path, Style);
end;

{ TSVGIconRenderer }

constructor TSVGIconRenderer.Create;
begin
  inherited Create;
  FCache := TList.Create;
  FRenderer := nil;
end;

destructor TSVGIconRenderer.Destroy;
begin
  ClearCache;
  FCache.Free;
  FRenderer.Free;
  inherited Destroy;
end;

function TSVGIconRenderer.ComputeHash(const Path: TSVGPath; Size: TSize): Cardinal;
var
  I: Integer;
begin
  Result := Size.Width xor (Size.Height shl 16);
  
  // 简单的路径哈希
  for I := 0 to Path.CommandCount - 1 do
    Result := Result xor (Cardinal(Path.Commands[I].CommandType) shl I);
end;

function TSVGIconRenderer.FindInCache(Hash: Cardinal; Size: TSize): TBitmap32;
var
  I: Integer;
  Entry: PCacheEntry;
begin
  Result := nil;
  
  for I := 0 to FCache.Count - 1 do
  begin
    Entry := FCache[I];
    if (Entry^.Hash = Hash) and 
       (Entry^.Size.Width = Size.Width) and
       (Entry^.Size.Height = Size.Height) then
    begin
      Result := Entry^.Bitmap;
      Exit;
    end;
  end;
end;

procedure TSVGIconRenderer.AddToCache(Hash: Cardinal; Size: TSize; Bitmap: TBitmap32);
var
  Entry: PCacheEntry;
begin
  New(Entry);
  Entry^.Hash := Hash;
  Entry^.Size := Size;
  Entry^.Bitmap := TBitmap32.Create;
  Entry^.Bitmap.Assign(Bitmap);
  FCache.Add(Entry);
end;

function TSVGIconRenderer.RenderIcon(const Path: TSVGPath; 
  Size: Integer; Color: TColor32): TBitmap32;
var
  Hash: Cardinal;
  CacheSize: TSize;
  Style: TSVGStyle;
  Bounds: TRectF;
begin
  CacheSize.Width := Size;
  CacheSize.Height := Size;
  Hash := ComputeHash(Path, CacheSize);
  
  // 检查缓存
  Result := FindInCache(Hash, CacheSize);
  if Result <> nil then Exit;
  
  // 创建新位图
  Result := TBitmap32.Create;
  Result.SetSize(Size, Size);
  Result.Clear(0);
  
  // 创建渲染器
  if FRenderer = nil then
    FRenderer := TSVGRenderer.Create(Result)
  else
    FRenderer.FBitmap := Result;
  
  // 设置样式
  Style.Fill := Color;
  Style.HasFill := True;
  Style.Stroke := clNone32;
  Style.HasStroke := False;
  Style.FillOpacity := 255;
  Style.FillRule := sfrNonZero;
  
  // 设置视图框
  Bounds := Path.GetBounds;
  FRenderer.ViewBox := Bounds;
  FRenderer.PreserveAspectRatio := True;
  
  // 渲染
  FRenderer.RenderPath(Path, Style);
  
  // 添加到缓存
  AddToCache(Hash, CacheSize, Result);
end;

procedure TSVGIconRenderer.RenderMultiSize(const Path: TSVGPath; 
  const Sizes: array of Integer; Color: TColor32);
var
  I: Integer;
begin
  for I := 0 to High(Sizes) do
    RenderIcon(Path, Sizes[I], Color);
end;

procedure TSVGIconRenderer.ClearCache;
var
  I: Integer;
  Entry: PCacheEntry;
begin
  for I := 0 to FCache.Count - 1 do
  begin
    Entry := FCache[I];
    Entry^.Bitmap.Free;
    Dispose(Entry);
  end;
  FCache.Clear;
end;

{ 实用函数 }

function CreateStrokeStyle(Width: Single; Color: TColor32): TStrokeStyle;
begin
  Result.Width := Width;
  Result.Color := Color;
  SetLength(Result.DashArray, 0);
  Result.DashOffset := 0;
  Result.LineCap := lcButt;
  Result.LineJoin := ljMiter;
  Result.MiterLimit := 4;
end;

function CreateFillStyle(Color: TColor32): TFillStyle;
begin
  Result.Color := Color;
  Result.Gradient := nil;
  Result.Opacity := 255;
  Result.Rule := sfrNonZero;
end;

function CreateGradientFill(Gradient: TGradient): TFillStyle;
begin
  Result.Color := clNone32;
  Result.Gradient := Gradient;
  Result.Opacity := 255;
  Result.Rule := sfrNonZero;
end;

procedure RenderSVGToBitmap(const SVGPath: string; Bitmap: TBitmap32; 
  const ViewBox: TRectF);
var
  Path: TSVGPath;
  Renderer: TSVGRenderer;
  Style: TSVGStyle;
begin
  Path := TSVGPath.Create;
  Renderer := TSVGRenderer.Create(Bitmap);
  try
    Path.ParsePathData(SVGPath);
    
    Style.Fill := clBlack32;
    Style.HasFill := True;
    Style.Stroke := clNone32;
    Style.HasStroke := False;
    Style.FillOpacity := 255;
    
    Renderer.ViewBox := ViewBox;
    Renderer.RenderPath(Path, Style);
  finally
    Renderer.Free;
    Path.Free;
  end;
end;

procedure RenderSVGIcon(const SVGPath: string; Bitmap: TBitmap32; 
  Size: Integer; Color: TColor32);
var
  Path: TSVGPath;
  IconRenderer: TSVGIconRenderer;
  Result: TBitmap32;
begin
  Path := TSVGPath.Create;
  IconRenderer := TSVGIconRenderer.Create;
  try
    Path.ParsePathData(SVGPath);
    Result := IconRenderer.RenderIcon(Path, Size, Color);
    Bitmap.Assign(Result);
  finally
    IconRenderer.Free;
    Path.Free;
  end;
end;

end.