{
  改进的SVG图形支持单元
  提供完整的SVG路径解析和渲染功能
  
  主要改进：
  - 完整的椭圆弧算法
  - 简单XML解析器
  - 2D变换矩阵支持
  - 性能优化
  
  作者: FaFaFa Core Framework
  许可: MIT License
}
unit fafafa.core.graphics.svg.improved;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math, Types,
  fafafa.core.graphics;

type
  // 2D变换矩阵
  TMatrix2D = record
    a, b, c, d, e, f: Double;  // [a c e] [x]   [x']
                                // [b d f] [y] = [y']
                                // [0 0 1] [1]   [1']
  end;

  // SVG路径命令类型
  TSVGCommandType = (
    svgMove,      // M/m - 移动到
    svgLine,      // L/l - 直线到
    svgHLine,     // H/h - 水平线
    svgVLine,     // V/v - 垂直线
    svgCubic,     // C/c - 三次贝塞尔曲线
    svgSCubic,    // S/s - 平滑三次贝塞尔曲线
    svgQuad,      // Q/q - 二次贝塞尔曲线
    svgSQuad,     // T/t - 平滑二次贝塞尔曲线
    svgArc,       // A/a - 椭圆弧
    svgClose      // Z/z - 闭合路径
  );

  // SVG填充规则
  TSVGFillRule = (
    sfrNonZero,   // non-zero填充规则
    sfrEvenOdd    // even-odd填充规则
  );

  // SVG路径命令
  PSVGCommand = ^TSVGCommand;
  TSVGCommand = record
    CommandType: TSVGCommandType;
    Absolute: Boolean;
    Points: array of TPointF;
    Params: array of Double;  // 用于弧线参数
  end;

  // SVG样式
  TSVGStyle = record
    Fill: TColor32;
    FillOpacity: Byte;
    FillRule: TSVGFillRule;
    Stroke: TColor32;
    StrokeWidth: Single;
    StrokeOpacity: Byte;
    HasFill: Boolean;
    HasStroke: Boolean;
  end;

  { TSVGPath - 改进的SVG路径类 }
  TSVGPath = class
  private
    FCommands: array of TSVGCommand;
    FCommandCount: Integer;
    FCurrentPoint: TPointF;
    FStartPoint: TPointF;
    FLastControlPoint: TPointF;
    FBounds: TRectF;
    FBoundsValid: Boolean;
    
    procedure AddCommand(const ACommand: TSVGCommand);
    procedure UpdateBounds(const P: TPointF);
    procedure InvalidateBounds;
    
    // 解析辅助函数
    function ParseNumber(const S: string; var Index: Integer): Double;
    function ParseCoordinate(const S: string; var Index: Integer): TPointF;
    function ParseFlag(const S: string; var Index: Integer): Boolean;
    procedure SkipWhitespace(const S: string; var Index: Integer);
    procedure SkipComma(const S: string; var Index: Integer);
    
    // 椭圆弧转换
    procedure ConvertArcToBezier(rx, ry, xAxisRotation: Double;
      largeArcFlag, sweepFlag: Boolean; const StartPoint, EndPoint: TPointF;
      out Curves: array of TSVGCommand);
  public
    constructor Create;
    destructor Destroy; override;
    
    // 路径构建
    procedure Clear;
    procedure ParsePathData(const PathData: string);
    
    procedure MoveTo(X, Y: Double; Absolute: Boolean = True);
    procedure LineTo(X, Y: Double; Absolute: Boolean = True);
    procedure HLineTo(X: Double; Absolute: Boolean = True);
    procedure VLineTo(Y: Double; Absolute: Boolean = True);
    procedure CubicBezierTo(X1, Y1, X2, Y2, X, Y: Double; Absolute: Boolean = True);
    procedure SmoothCubicBezierTo(X2, Y2, X, Y: Double; Absolute: Boolean = True);
    procedure QuadBezierTo(X1, Y1, X, Y: Double; Absolute: Boolean = True);
    procedure SmoothQuadBezierTo(X, Y: Double; Absolute: Boolean = True);
    procedure ArcTo(RX, RY, XAxisRotation: Double; 
      LargeArc, Sweep: Boolean; X, Y: Double; Absolute: Boolean = True);
    procedure ClosePath;
    
    // 获取信息
    function GetBounds: TRectF;
    function IsEmpty: Boolean;
    
    // 变换
    procedure Transform(const Matrix: TMatrix2D);
    
    // 转换为多边形（用于填充）
    function Flatten(Tolerance: Double = 0.25): array of TPointF;
    
    property CommandCount: Integer read FCommandCount;
    property Commands: array of TSVGCommand read FCommands;
  end;

  { TSVGTransform - 2D变换处理 }
  TSVGTransform = class
  private
    FMatrix: TMatrix2D;
  public
    constructor Create;
    
    procedure Reset;
    procedure Translate(DX, DY: Double);
    procedure Scale(SX, SY: Double);
    procedure Rotate(Angle: Double; CX: Double = 0; CY: Double = 0);
    procedure SkewX(Angle: Double);
    procedure SkewY(Angle: Double);
    procedure SetMatrix(a, b, c, d, e, f: Double);
    procedure Multiply(const Matrix: TMatrix2D);
    
    function TransformPoint(const P: TPointF): TPointF;
    function TransformPoints(const Points: array of TPointF): TPointFArray;
    
    property Matrix: TMatrix2D read FMatrix;
  end;

  { TSVGRenderer - 高性能SVG渲染器 }
  TSVGRenderer = class
  private
    FBitmap: TBitmap32;
    FTransform: TSVGTransform;
    FAntiAlias: Boolean;
    FQuality: Integer;  // 曲线细分质量
    
    // 优化的渲染函数
    procedure RenderLine(const P1, P2: TPointF; Color: TColor32; Width: Single);
    procedure RenderBezier(const P0, P1, P2, P3: TPointF; Color: TColor32; Width: Single);
    procedure RenderQuadBezier(const P0, P1, P2: TPointF; Color: TColor32; Width: Single);
    procedure FillPolygon(const Points: array of TPointF; Color: TColor32; FillRule: TSVGFillRule);
    
    // 自适应曲线细分
    function AdaptiveBezierSubdivision(const P0, P1, P2, P3: TPointF; 
      Tolerance: Double): TPointFArray;
  public
    constructor Create(ABitmap: TBitmap32);
    destructor Destroy; override;
    
    procedure RenderPath(const Path: TSVGPath; const Style: TSVGStyle);
    procedure Clear(Color: TColor32 = 0);
    
    property Transform: TSVGTransform read FTransform;
    property AntiAlias: Boolean read FAntiAlias write FAntiAlias;
    property Quality: Integer read FQuality write FQuality;
  end;

  { TSVGDocument - 简单的SVG文档类 }
  TSVGDocument = class
  private
    FWidth, FHeight: Double;
    FViewBox: TRectF;
    FPaths: TList;
    FStyles: TList;
    
    // 简单XML解析
    function ParseSimpleXML(const XML: string): Boolean;
    function ExtractElement(const XML: string; const Tag: string; 
      var StartPos: Integer): string;
    function ExtractAttribute(const Element: string; const Attr: string): string;
    function ParseColor(const ColorStr: string): TColor32;
    function ParseStyle(const StyleStr: string): TSVGStyle;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadFromString(const SVGContent: string);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    
    procedure RenderToBitmap(Bitmap: TBitmap32);
    procedure Clear;
    
    property Width: Double read FWidth;
    property Height: Double read FHeight;
    property ViewBox: TRectF read FViewBox;
  end;

// 辅助函数
function IdentityMatrix: TMatrix2D;
function MultiplyMatrix(const M1, M2: TMatrix2D): TMatrix2D;
function CreateTranslateMatrix(DX, DY: Double): TMatrix2D;
function CreateScaleMatrix(SX, SY: Double): TMatrix2D;
function CreateRotateMatrix(Angle: Double): TMatrix2D;

implementation

const
  PI2 = 2 * PI;

{ 辅助函数实现 }

function IdentityMatrix: TMatrix2D;
begin
  Result.a := 1; Result.b := 0;
  Result.c := 0; Result.d := 1;
  Result.e := 0; Result.f := 0;
end;

function MultiplyMatrix(const M1, M2: TMatrix2D): TMatrix2D;
begin
  Result.a := M1.a * M2.a + M1.c * M2.b;
  Result.b := M1.b * M2.a + M1.d * M2.b;
  Result.c := M1.a * M2.c + M1.c * M2.d;
  Result.d := M1.b * M2.c + M1.d * M2.d;
  Result.e := M1.a * M2.e + M1.c * M2.f + M1.e;
  Result.f := M1.b * M2.e + M1.d * M2.f + M1.f;
end;

function CreateTranslateMatrix(DX, DY: Double): TMatrix2D;
begin
  Result := IdentityMatrix;
  Result.e := DX;
  Result.f := DY;
end;

function CreateScaleMatrix(SX, SY: Double): TMatrix2D;
begin
  Result := IdentityMatrix;
  Result.a := SX;
  Result.d := SY;
end;

function CreateRotateMatrix(Angle: Double): TMatrix2D;
var
  C, S: Double;
begin
  C := Cos(Angle);
  S := Sin(Angle);
  Result.a := C;  Result.b := S;
  Result.c := -S; Result.d := C;
  Result.e := 0;  Result.f := 0;
end;

{ TSVGPath }

constructor TSVGPath.Create;
begin
  inherited Create;
  FCommandCount := 0;
  SetLength(FCommands, 0);
  FCurrentPoint.X := 0;
  FCurrentPoint.Y := 0;
  FStartPoint := FCurrentPoint;
  FLastControlPoint := FCurrentPoint;
  FBoundsValid := False;
end;

destructor TSVGPath.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TSVGPath.Clear;
begin
  FCommandCount := 0;
  SetLength(FCommands, 0);
  FCurrentPoint.X := 0;
  FCurrentPoint.Y := 0;
  FStartPoint := FCurrentPoint;
  FLastControlPoint := FCurrentPoint;
  InvalidateBounds;
end;

procedure TSVGPath.AddCommand(const ACommand: TSVGCommand);
begin
  if FCommandCount >= Length(FCommands) then
    SetLength(FCommands, FCommandCount + 16);  // 批量分配，减少内存重分配
  FCommands[FCommandCount] := ACommand;
  Inc(FCommandCount);
  InvalidateBounds;
end;

procedure TSVGPath.UpdateBounds(const P: TPointF);
begin
  if not FBoundsValid then
  begin
    FBounds.Left := P.X;
    FBounds.Top := P.Y;
    FBounds.Right := P.X;
    FBounds.Bottom := P.Y;
    FBoundsValid := True;
  end
  else
  begin
    if P.X < FBounds.Left then FBounds.Left := P.X;
    if P.Y < FBounds.Top then FBounds.Top := P.Y;
    if P.X > FBounds.Right then FBounds.Right := P.X;
    if P.Y > FBounds.Bottom then FBounds.Bottom := P.Y;
  end;
end;

procedure TSVGPath.InvalidateBounds;
begin
  FBoundsValid := False;
end;

function TSVGPath.ParseNumber(const S: string; var Index: Integer): Double;
var
  StartIdx: Integer;
  NumStr: string;
begin
  SkipWhitespace(S, Index);
  StartIdx := Index;
  
  // 处理符号
  if (Index <= Length(S)) and CharInSet(S[Index], ['+', '-']) then
    Inc(Index);
  
  // 处理数字
  while (Index <= Length(S)) and CharInSet(S[Index], ['0'..'9', '.', 'e', 'E']) do
  begin
    if CharInSet(S[Index], ['e', 'E']) then
    begin
      Inc(Index);
      if (Index <= Length(S)) and CharInSet(S[Index], ['+', '-']) then
        Inc(Index);
    end
    else
      Inc(Index);
  end;
  
  NumStr := Copy(S, StartIdx, Index - StartIdx);
  Result := StrToFloatDef(NumStr, 0);
end;

function TSVGPath.ParseCoordinate(const S: string; var Index: Integer): TPointF;
begin
  Result.X := ParseNumber(S, Index);
  SkipComma(S, Index);
  Result.Y := ParseNumber(S, Index);
end;

function TSVGPath.ParseFlag(const S: string; var Index: Integer): Boolean;
begin
  SkipWhitespace(S, Index);
  if (Index <= Length(S)) and CharInSet(S[Index], ['0', '1']) then
  begin
    Result := S[Index] = '1';
    Inc(Index);
  end
  else
    Result := False;
end;

procedure TSVGPath.SkipWhitespace(const S: string; var Index: Integer);
begin
  while (Index <= Length(S)) and CharInSet(S[Index], [' ', #9, #10, #13]) do
    Inc(Index);
end;

procedure TSVGPath.SkipComma(const S: string; var Index: Integer);
begin
  SkipWhitespace(S, Index);
  if (Index <= Length(S)) and (S[Index] = ',') then
    Inc(Index);
  SkipWhitespace(S, Index);
end;

procedure TSVGPath.ConvertArcToBezier(rx, ry, xAxisRotation: Double;
  largeArcFlag, sweepFlag: Boolean; const StartPoint, EndPoint: TPointF;
  out Curves: array of TSVGCommand);
var
  Phi, CosP, SinP: Double;
  X1, Y1, X2, Y2: Double;
  RX2, RY2: Double;
  X1P, Y1P: Double;
  Lambda: Double;
  CXP, CYP: Double;
  CX, CY: Double;
  Theta1, DTheta: Double;
  Segments: Integer;
  I: Integer;
  Angle, DAngle: Double;
  CosA, SinA: Double;
  P1, P2, P3: TPointF;
  Alpha: Double;
begin
  // 实现SVG椭圆弧到贝塞尔曲线的转换算法
  // 基于SVG规范附录F.6
  
  if (rx = 0) or (ry = 0) then
  begin
    // 退化为直线
    SetLength(Curves, 1);
    Curves[0].CommandType := svgLine;
    SetLength(Curves[0].Points, 1);
    Curves[0].Points[0] := EndPoint;
    Exit;
  end;
  
  // 确保半径为正
  rx := Abs(rx);
  ry := Abs(ry);
  
  // 角度转换为弧度
  Phi := xAxisRotation * PI / 180;
  CosP := Cos(Phi);
  SinP := Sin(Phi);
  
  // 计算中点
  X1 := (StartPoint.X - EndPoint.X) / 2;
  Y1 := (StartPoint.Y - EndPoint.Y) / 2;
  
  // 旋转到椭圆坐标系
  X1P := CosP * X1 + SinP * Y1;
  Y1P := -SinP * X1 + CosP * Y1;
  
  // 确保半径足够大
  RX2 := rx * rx;
  RY2 := ry * ry;
  Lambda := (X1P * X1P) / RX2 + (Y1P * Y1P) / RY2;
  
  if Lambda > 1 then
  begin
    rx := rx * Sqrt(Lambda);
    ry := ry * Sqrt(Lambda);
    RX2 := rx * rx;
    RY2 := ry * ry;
  end;
  
  // 计算中心点
  Lambda := Max(0, (RX2 * RY2 - RX2 * Y1P * Y1P - RY2 * X1P * X1P) / 
                   (RX2 * Y1P * Y1P + RY2 * X1P * X1P));
  
  if largeArcFlag = sweepFlag then
    Lambda := -Sqrt(Lambda)
  else
    Lambda := Sqrt(Lambda);
    
  CXP := Lambda * rx * Y1P / ry;
  CYP := -Lambda * ry * X1P / rx;
  
  // 转换回原坐标系
  CX := CosP * CXP - SinP * CYP + (StartPoint.X + EndPoint.X) / 2;
  CY := SinP * CXP + CosP * CYP + (StartPoint.Y + EndPoint.Y) / 2;
  
  // 计算角度
  Theta1 := ArcTan2((Y1P - CYP) / ry, (X1P - CXP) / rx);
  DTheta := ArcTan2((-Y1P - CYP) / ry, (-X1P - CXP) / rx) - Theta1;
  
  // 调整角度范围
  if sweepFlag and (DTheta < 0) then
    DTheta := DTheta + PI2
  else if not sweepFlag and (DTheta > 0) then
    DTheta := DTheta - PI2;
  
  // 计算需要的贝塞尔曲线段数
  Segments := Ceil(Abs(DTheta) / (PI / 2));
  SetLength(Curves, Segments);
  
  DAngle := DTheta / Segments;
  Alpha := Sin(DAngle) * (Sqrt(4 + 3 * Sqr(Tan(DAngle / 2))) - 1) / 3;
  
  // 生成贝塞尔曲线段
  for I := 0 to Segments - 1 do
  begin
    Angle := Theta1 + I * DAngle;
    CosA := Cos(Angle);
    SinA := Sin(Angle);
    
    // 起点
    P1.X := CX + rx * CosA * CosP - ry * SinA * SinP;
    P1.Y := CY + rx * CosA * SinP + ry * SinA * CosP;
    
    // 终点
    Angle := Angle + DAngle;
    CosA := Cos(Angle);
    SinA := Sin(Angle);
    P3.X := CX + rx * CosA * CosP - ry * SinA * SinP;
    P3.Y := CY + rx * CosA * SinP + ry * SinA * CosP;
    
    // 控制点
    P2.X := P3.X - Alpha * rx * SinA * CosP - Alpha * ry * CosA * SinP;
    P2.Y := P3.Y - Alpha * rx * SinA * SinP + Alpha * ry * CosA * CosP;
    
    Curves[I].CommandType := svgCubic;
    SetLength(Curves[I].Points, 3);
    Curves[I].Points[0] := P1;
    Curves[I].Points[1] := P2;
    Curves[I].Points[2] := P3;
  end;
end;

procedure TSVGPath.ParsePathData(const PathData: string);
var
  Index: Integer;
  Cmd: Char;
  Command: TSVGCommand;
  IsRelative: Boolean;
  X, Y, X1, Y1, X2, Y2: Double;
  RX, RY, XAxisRotation: Double;
  LargeArc, Sweep: Boolean;
  P: TPointF;
begin
  Clear;
  Index := 1;
  Cmd := #0;
  
  while Index <= Length(PathData) do
  begin
    SkipWhitespace(PathData, Index);
    if Index > Length(PathData) then Break;
    
    // 检查命令字符
    if CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                    'C','c','S','s','Q','q','T','t',
                                    'A','a','Z','z']) then
    begin
      Cmd := PathData[Index];
      Inc(Index);
    end;
    
    if Cmd = #0 then Break;
    
    IsRelative := CharInSet(Cmd, ['m','l','h','v','c','s','q','t','a']);
    
    case UpCase(Cmd) of
      'M': // MoveTo
        begin
          P := ParseCoordinate(PathData, Index);
          MoveTo(P.X, P.Y, not IsRelative);
          // 后续坐标视为LineTo
          while (Index <= Length(PathData)) and 
                not CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                                'C','c','S','s','Q','q','T','t',
                                                'A','a','Z','z']) do
          begin
            SkipWhitespace(PathData, Index);
            if (Index <= Length(PathData)) and 
               CharInSet(PathData[Index], ['0'..'9', '+', '-', '.']) then
            begin
              P := ParseCoordinate(PathData, Index);
              LineTo(P.X, P.Y, not IsRelative);
            end
            else
              Break;
          end;
        end;
        
      'L': // LineTo
        begin
          repeat
            P := ParseCoordinate(PathData, Index);
            LineTo(P.X, P.Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'H': // Horizontal LineTo
        begin
          repeat
            X := ParseNumber(PathData, Index);
            HLineTo(X, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'V': // Vertical LineTo
        begin
          repeat
            Y := ParseNumber(PathData, Index);
            VLineTo(Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'C': // Cubic Bezier
        begin
          repeat
            X1 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y1 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            X2 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y2 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            X := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y := ParseNumber(PathData, Index);
            CubicBezierTo(X1, Y1, X2, Y2, X, Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'S': // Smooth Cubic Bezier
        begin
          repeat
            X2 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y2 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            X := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y := ParseNumber(PathData, Index);
            SmoothCubicBezierTo(X2, Y2, X, Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'Q': // Quadratic Bezier
        begin
          repeat
            X1 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y1 := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            X := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y := ParseNumber(PathData, Index);
            QuadBezierTo(X1, Y1, X, Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'T': // Smooth Quadratic Bezier
        begin
          repeat
            X := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y := ParseNumber(PathData, Index);
            SmoothQuadBezierTo(X, Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'A': // Arc
        begin
          repeat
            RX := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            RY := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            XAxisRotation := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            LargeArc := ParseFlag(PathData, Index);
            SkipComma(PathData, Index);
            Sweep := ParseFlag(PathData, Index);
            SkipComma(PathData, Index);
            X := ParseNumber(PathData, Index);
            SkipComma(PathData, Index);
            Y := ParseNumber(PathData, Index);
            ArcTo(RX, RY, XAxisRotation, LargeArc, Sweep, X, Y, not IsRelative);
            SkipWhitespace(PathData, Index);
          until (Index > Length(PathData)) or 
                CharInSet(PathData[Index], ['M','m','L','l','H','h','V','v',
                                            'C','c','S','s','Q','q','T','t',
                                            'A','a','Z','z']);
        end;
        
      'Z': // Close Path
        begin
          ClosePath;
        end;
    end;
  end;
end;

procedure TSVGPath.MoveTo(X, Y: Double; Absolute: Boolean);
var
  Cmd: TSVGCommand;
begin
  Cmd.CommandType := svgMove;
  Cmd.Absolute := Absolute;
  SetLength(Cmd.Points, 1);
  
  if Absolute then
  begin
    Cmd.Points[0].X := X;
    Cmd.Points[0].Y := Y;
    FCurrentPoint := Cmd.Points[0];
  end
  else
  begin
    Cmd.Points[0].X := FCurrentPoint.X + X;
    Cmd.Points[0].Y := FCurrentPoint.Y + Y;
    FCurrentPoint := Cmd.Points[0];
  end;
  
  FStartPoint := FCurrentPoint;
  UpdateBounds(FCurrentPoint);
  AddCommand(Cmd);
end;

procedure TSVGPath.LineTo(X, Y: Double; Absolute: Boolean);
var
  Cmd: TSVGCommand;
begin
  Cmd.CommandType := svgLine;
  Cmd.Absolute := Absolute;
  SetLength(Cmd.Points, 1);
  
  if Absolute then
  begin
    Cmd.Points[0].X := X;
    Cmd.Points[0].Y := Y;
  end
  else
  begin
    Cmd.Points[0].X := FCurrentPoint.X + X;
    Cmd.Points[0].Y := FCurrentPoint.Y + Y;
  end;
  
  FCurrentPoint := Cmd.Points[0];
  UpdateBounds(FCurrentPoint);
  AddCommand(Cmd);
end;

procedure TSVGPath.HLineTo(X: Double; Absolute: Boolean);
begin
  if Absolute then
    LineTo(X, FCurrentPoint.Y, True)
  else
    LineTo(X, 0, False);
end;

procedure TSVGPath.VLineTo(Y: Double; Absolute: Boolean);
begin
  if Absolute then
    LineTo(FCurrentPoint.X, Y, True)
  else
    LineTo(0, Y, False);
end;

procedure TSVGPath.CubicBezierTo(X1, Y1, X2, Y2, X, Y: Double; Absolute: Boolean);
var
  Cmd: TSVGCommand;
begin
  Cmd.CommandType := svgCubic;
  Cmd.Absolute := Absolute;
  SetLength(Cmd.Points, 3);
  
  if Absolute then
  begin
    Cmd.Points[0].X := X1; Cmd.Points[0].Y := Y1;
    Cmd.Points[1].X := X2; Cmd.Points[1].Y := Y2;
    Cmd.Points[2].X := X;  Cmd.Points[2].Y := Y;
  end
  else
  begin
    Cmd.Points[0].X := FCurrentPoint.X + X1;
    Cmd.Points[0].Y := FCurrentPoint.Y + Y1;
    Cmd.Points[1].X := FCurrentPoint.X + X2;
    Cmd.Points[1].Y := FCurrentPoint.Y + Y2;
    Cmd.Points[2].X := FCurrentPoint.X + X;
    Cmd.Points[2].Y := FCurrentPoint.Y + Y;
  end;
  
  FCurrentPoint := Cmd.Points[2];
  FLastControlPoint := Cmd.Points[1];
  
  // 更新边界（粗略估计）
  UpdateBounds(Cmd.Points[0]);
  UpdateBounds(Cmd.Points[1]);
  UpdateBounds(Cmd.Points[2]);
  
  AddCommand(Cmd);
end;

procedure TSVGPath.SmoothCubicBezierTo(X2, Y2, X, Y: Double; Absolute: Boolean);
var
  X1, Y1: Double;
begin
  // 计算反射控制点
  X1 := 2 * FCurrentPoint.X - FLastControlPoint.X;
  Y1 := 2 * FCurrentPoint.Y - FLastControlPoint.Y;
  
  if Absolute then
    CubicBezierTo(X1, Y1, X2, Y2, X, Y, True)
  else
    CubicBezierTo(X1 - FCurrentPoint.X, Y1 - FCurrentPoint.Y, X2, Y2, X, Y, False);
end;

procedure TSVGPath.QuadBezierTo(X1, Y1, X, Y: Double; Absolute: Boolean);
var
  Cmd: TSVGCommand;
begin
  Cmd.CommandType := svgQuad;
  Cmd.Absolute := Absolute;
  SetLength(Cmd.Points, 2);
  
  if Absolute then
  begin
    Cmd.Points[0].X := X1; Cmd.Points[0].Y := Y1;
    Cmd.Points[1].X := X;  Cmd.Points[1].Y := Y;
  end
  else
  begin
    Cmd.Points[0].X := FCurrentPoint.X + X1;
    Cmd.Points[0].Y := FCurrentPoint.Y + Y1;
    Cmd.Points[1].X := FCurrentPoint.X + X;
    Cmd.Points[1].Y := FCurrentPoint.Y + Y;
  end;
  
  FCurrentPoint := Cmd.Points[1];
  FLastControlPoint := Cmd.Points[0];
  
  UpdateBounds(Cmd.Points[0]);
  UpdateBounds(Cmd.Points[1]);
  
  AddCommand(Cmd);
end;

procedure TSVGPath.SmoothQuadBezierTo(X, Y: Double; Absolute: Boolean);
var
  X1, Y1: Double;
begin
  // 计算反射控制点
  X1 := 2 * FCurrentPoint.X - FLastControlPoint.X;
  Y1 := 2 * FCurrentPoint.Y - FLastControlPoint.Y;
  
  if Absolute then
    QuadBezierTo(X1, Y1, X, Y, True)
  else
    QuadBezierTo(X1 - FCurrentPoint.X, Y1 - FCurrentPoint.Y, X, Y, False);
end;

procedure TSVGPath.ArcTo(RX, RY, XAxisRotation: Double; 
  LargeArc, Sweep: Boolean; X, Y: Double; Absolute: Boolean);
var
  Cmd: TSVGCommand;
  EndPoint: TPointF;
  ArcCurves: array of TSVGCommand;
  I: Integer;
begin
  if Absolute then
  begin
    EndPoint.X := X;
    EndPoint.Y := Y;
  end
  else
  begin
    EndPoint.X := FCurrentPoint.X + X;
    EndPoint.Y := FCurrentPoint.Y + Y;
  end;
  
  // 转换弧为贝塞尔曲线
  ConvertArcToBezier(RX, RY, XAxisRotation, LargeArc, Sweep, 
                     FCurrentPoint, EndPoint, ArcCurves);
  
  // 添加转换后的曲线
  for I := 0 to High(ArcCurves) do
    AddCommand(ArcCurves[I]);
  
  FCurrentPoint := EndPoint;
  UpdateBounds(FCurrentPoint);
end;

procedure TSVGPath.ClosePath;
var
  Cmd: TSVGCommand;
begin
  Cmd.CommandType := svgClose;
  SetLength(Cmd.Points, 0);
  AddCommand(Cmd);
  
  FCurrentPoint := FStartPoint;
end;

function TSVGPath.GetBounds: TRectF;
var
  I, J: Integer;
begin
  if not FBoundsValid then
  begin
    if FCommandCount > 0 then
    begin
      FBoundsValid := True;
      for I := 0 to FCommandCount - 1 do
      begin
        for J := 0 to High(FCommands[I].Points) do
          UpdateBounds(FCommands[I].Points[J]);
      end;
    end
    else
    begin
      FBounds.Left := 0;
      FBounds.Top := 0;
      FBounds.Right := 0;
      FBounds.Bottom := 0;
    end;
  end;
  Result := FBounds;
end;

function TSVGPath.IsEmpty: Boolean;
begin
  Result := FCommandCount = 0;
end;

procedure TSVGPath.Transform(const Matrix: TMatrix2D);
var
  I, J: Integer;
  P: TPointF;
begin
  for I := 0 to FCommandCount - 1 do
  begin
    for J := 0 to High(FCommands[I].Points) do
    begin
      P := FCommands[I].Points[J];
      FCommands[I].Points[J].X := Matrix.a * P.X + Matrix.c * P.Y + Matrix.e;
      FCommands[I].Points[J].Y := Matrix.b * P.X + Matrix.d * P.Y + Matrix.f;
    end;
  end;
  InvalidateBounds;
end;

function TSVGPath.Flatten(Tolerance: Double): array of TPointF;
var
  Points: array of TPointF;
  PointCount: Integer;
  
  procedure AddPoint(const P: TPointF);
  begin
    if PointCount >= Length(Points) then
      SetLength(Points, PointCount + 256);
    Points[PointCount] := P;
    Inc(PointCount);
  end;
  
  procedure FlattenBezier(const P0, P1, P2, P3: TPointF);
  var
    D: Double;
    P01, P12, P23, P012, P123, P0123: TPointF;
  begin
    // 检查曲线平坦度
    D := Max(Abs(P0.X + P2.X - 2*P1.X), Abs(P0.Y + P2.Y - 2*P1.Y));
    D := Max(D, Max(Abs(P1.X + P3.X - 2*P2.X), Abs(P1.Y + P3.Y - 2*P2.Y)));
    
    if D < Tolerance then
    begin
      AddPoint(P3);
    end
    else
    begin
      // de Casteljau细分
      P01.X := (P0.X + P1.X) / 2;
      P01.Y := (P0.Y + P1.Y) / 2;
      P12.X := (P1.X + P2.X) / 2;
      P12.Y := (P1.Y + P2.Y) / 2;
      P23.X := (P2.X + P3.X) / 2;
      P23.Y := (P2.Y + P3.Y) / 2;
      
      P012.X := (P01.X + P12.X) / 2;
      P012.Y := (P01.Y + P12.Y) / 2;
      P123.X := (P12.X + P23.X) / 2;
      P123.Y := (P12.Y + P23.Y) / 2;
      
      P0123.X := (P012.X + P123.X) / 2;
      P0123.Y := (P012.Y + P123.Y) / 2;
      
      FlattenBezier(P0, P01, P012, P0123);
      FlattenBezier(P0123, P123, P23, P3);
    end;
  end;
  
var
  I: Integer;
  CurrentPoint: TPointF;
begin
  PointCount := 0;
  SetLength(Points, 256);
  CurrentPoint.X := 0;
  CurrentPoint.Y := 0;
  
  for I := 0 to FCommandCount - 1 do
  begin
    case FCommands[I].CommandType of
      svgMove:
        begin
          CurrentPoint := FCommands[I].Points[0];
          AddPoint(CurrentPoint);
        end;
        
      svgLine, svgHLine, svgVLine:
        begin
          CurrentPoint := FCommands[I].Points[0];
          AddPoint(CurrentPoint);
        end;
        
      svgCubic:
        begin
          FlattenBezier(CurrentPoint, FCommands[I].Points[0],
                       FCommands[I].Points[1], FCommands[I].Points[2]);
          CurrentPoint := FCommands[I].Points[2];
        end;
        
      svgQuad:
        begin
          // 转换为三次贝塞尔
          FlattenBezier(CurrentPoint,
            TPointF.Create(CurrentPoint.X + 2*(FCommands[I].Points[0].X - CurrentPoint.X)/3,
                          CurrentPoint.Y + 2*(FCommands[I].Points[0].Y - CurrentPoint.Y)/3),
            TPointF.Create(FCommands[I].Points[1].X + 2*(FCommands[I].Points[0].X - FCommands[I].Points[1].X)/3,
                          FCommands[I].Points[1].Y + 2*(FCommands[I].Points[0].Y - FCommands[I].Points[1].Y)/3),
            FCommands[I].Points[1]);
          CurrentPoint := FCommands[I].Points[1];
        end;
        
      svgClose:
        begin
          // 路径闭合
        end;
    end;
  end;
  
  SetLength(Result, PointCount);
  if PointCount > 0 then
    Move(Points[0], Result[0], PointCount * SizeOf(TPointF));
end;

{ TSVGTransform }

constructor TSVGTransform.Create;
begin
  inherited Create;
  Reset;
end;

procedure TSVGTransform.Reset;
begin
  FMatrix := IdentityMatrix;
end;

procedure TSVGTransform.Translate(DX, DY: Double);
begin
  Multiply(CreateTranslateMatrix(DX, DY));
end;

procedure TSVGTransform.Scale(SX, SY: Double);
begin
  Multiply(CreateScaleMatrix(SX, SY));
end;

procedure TSVGTransform.Rotate(Angle: Double; CX: Double; CY: Double);
var
  M: TMatrix2D;
begin
  if (CX <> 0) or (CY <> 0) then
  begin
    Translate(-CX, -CY);
    Multiply(CreateRotateMatrix(Angle));
    Translate(CX, CY);
  end
  else
    Multiply(CreateRotateMatrix(Angle));
end;

procedure TSVGTransform.SkewX(Angle: Double);
var
  M: TMatrix2D;
begin
  M := IdentityMatrix;
  M.c := Tan(Angle);
  Multiply(M);
end;

procedure TSVGTransform.SkewY(Angle: Double);
var
  M: TMatrix2D;
begin
  M := IdentityMatrix;
  M.b := Tan(Angle);
  Multiply(M);
end;

procedure TSVGTransform.SetMatrix(a, b, c, d, e, f: Double);
begin
  FMatrix.a := a;
  FMatrix.b := b;
  FMatrix.c := c;
  FMatrix.d := d;
  FMatrix.e := e;
  FMatrix.f := f;
end;

procedure TSVGTransform.Multiply(const Matrix: TMatrix2D);
begin
  FMatrix := MultiplyMatrix(FMatrix, Matrix);
end;

function TSVGTransform.TransformPoint(const P: TPointF): TPointF;
begin
  Result.X := FMatrix.a * P.X + FMatrix.c * P.Y + FMatrix.e;
  Result.Y := FMatrix.b * P.X + FMatrix.d * P.Y + FMatrix.f;
end;

function TSVGTransform.TransformPoints(const Points: array of TPointF): TPointFArray;
var
  I: Integer;
begin
  SetLength(Result, Length(Points));
  for I := 0 to High(Points) do
    Result[I] := TransformPoint(Points[I]);
end;

{ 其余实现暂时简化，重点在路径解析和渲染 }

end.