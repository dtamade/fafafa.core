program TestSVGRender;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Types,
  fafafa.core.graphics,
  fafafa.core.graphics.svg.improved,
  fafafa.core.graphics.svg.renderer;

// 常用SVG图标路径
const
  // 主页图标
  ICON_HOME = 'M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z';
  
  // 设置图标
  ICON_SETTINGS = 'M12 15.5A3.5 3.5 0 0 1 8.5 12A3.5 3.5 0 0 1 12 8.5a3.5 3.5 0 0 1 3.5 3.5a3.5 3.5 0 0 1-3.5 3.5m7.43-2.53c.04-.32.07-.64.07-.97c0-.33-.03-.66-.07-1l2.11-1.63c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.3-.61-.22l-2.49 1c-.52-.39-1.06-.73-1.69-.98l-.37-2.65A.506.506 0 0 0 14 2h-4c-.25 0-.46.18-.5.42l-.37 2.65c-.63.25-1.17.59-1.69.98l-2.49-1c-.22-.08-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64L4.57 11c-.04.34-.07.67-.07 1c0 .33.03.65.07.97l-2.11 1.66c-.19.15-.25.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1.01c.52.4 1.06.74 1.69.99l.37 2.65c.04.24.25.42.5.42h4c.25 0 .46-.18.5-.42l.37-2.65c.63-.26 1.17-.59 1.69-.99l2.49 1.01c.22.08.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64l-2.11-1.66Z';
  
  // 搜索图标
  ICON_SEARCH = 'M15.5 14h-.79l-.28-.27A6.471 6.471 0 0 0 16 9.5A6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5S14 7.01 14 9.5S11.99 14 9.5 14z';
  
  // 心形图标
  ICON_HEART = 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5C2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3C19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z';
  
  // 星形图标
  ICON_STAR = 'M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2L9.19 8.63L2 9.24l5.46 4.73L5.82 21z';

procedure RenderBasicSVG;
var
  Bitmap: TBitmap32;
  Path: TSVGPath;
  Renderer: TSVGRenderer;
  Style: TSVGStyle;
  ViewBox: TRectF;
begin
  WriteLn('=== 基础SVG渲染 ===');
  WriteLn;
  
  Bitmap := TBitmap32.Create;
  Path := TSVGPath.Create;
  Renderer := TSVGRenderer.Create(Bitmap);
  try
    Bitmap.SetSize(200, 200);
    Bitmap.Clear(clWhite32);
    
    // 解析一个简单的矩形路径
    Path.ParsePathData('M 20 20 L 180 20 L 180 180 L 20 180 Z');
    
    // 设置样式
    Style.Fill := $FF4169E1;  // 蓝色填充
    Style.HasFill := True;
    Style.Stroke := $FF000080;  // 深蓝色描边
    Style.HasStroke := True;
    Style.StrokeWidth := 3;
    Style.FillOpacity := 200;  // 半透明
    Style.StrokeOpacity := 255;
    Style.FillRule := sfrNonZero;
    
    // 设置视图
    ViewBox.Left := 0;
    ViewBox.Top := 0;
    ViewBox.Right := 200;
    ViewBox.Bottom := 200;
    
    Renderer.ViewBox := ViewBox;
    Renderer.RenderPath(Path, Style);
    
    // 保存结果
    Bitmap.SaveToFile('test_basic.bmp');
    WriteLn('已生成: test_basic.bmp');
    
  finally
    Renderer.Free;
    Path.Free;
    Bitmap.Free;
  end;
end;

procedure RenderGradient;
var
  Bitmap: TBitmap32;
  Path: TSVGPath;
  Rasterizer: TSVGRasterizer;
  Gradient: TGradient;
  FillStyle: TFillStyle;
  StrokeStyle: TStrokeStyle;
begin
  WriteLn('=== 渐变填充渲染 ===');
  WriteLn;
  
  Bitmap := TBitmap32.Create;
  Path := TSVGPath.Create;
  Rasterizer := TSVGRasterizer.Create(Bitmap);
  Gradient := TGradient.Create(gtLinear);
  try
    Bitmap.SetSize(300, 200);
    Bitmap.Clear(clWhite32);
    
    // 创建圆形路径
    Path.ParsePathData('M 150 50 A 50 50 0 1 1 150 150 A 50 50 0 1 1 150 50');
    
    // 设置渐变
    Gradient.AddStop(0.0, $FFFF0000);  // 红色
    Gradient.AddStop(0.5, $FFFFFF00);  // 黄色
    Gradient.AddStop(1.0, $FF00FF00);  // 绿色
    
    // 创建渐变填充样式
    FillStyle := CreateGradientFill(Gradient);
    StrokeStyle := CreateStrokeStyle(2, clBlack32);
    
    // 渲染
    Rasterizer.RenderPath(Path, FillStyle, StrokeStyle);
    
    // 保存结果
    Bitmap.SaveToFile('test_gradient.bmp');
    WriteLn('已生成: test_gradient.bmp');
    
  finally
    Gradient.Free;
    Rasterizer.Free;
    Path.Free;
    Bitmap.Free;
  end;
end;

procedure RenderIcons;
var
  IconRenderer: TSVGIconRenderer;
  Path: TSVGPath;
  Bitmap: TBitmap32;
  Icons: array[0..4] of string;
  Names: array[0..4] of string;
  I: Integer;
begin
  WriteLn('=== 图标渲染 ===');
  WriteLn;
  
  Icons[0] := ICON_HOME;   Names[0] := 'home';
  Icons[1] := ICON_SETTINGS; Names[1] := 'settings';
  Icons[2] := ICON_SEARCH;  Names[2] := 'search';
  Icons[3] := ICON_HEART;   Names[3] := 'heart';
  Icons[4] := ICON_STAR;    Names[4] := 'star';
  
  IconRenderer := TSVGIconRenderer.Create;
  Path := TSVGPath.Create;
  try
    for I := 0 to 4 do
    begin
      Path.Clear;
      Path.ParsePathData(Icons[I]);
      
      // 渲染不同尺寸
      Bitmap := IconRenderer.RenderIcon(Path, 24, clBlack32);
      Bitmap.SaveToFile(Format('icon_%s_24.bmp', [Names[I]]));
      
      Bitmap := IconRenderer.RenderIcon(Path, 48, $FF4169E1);
      Bitmap.SaveToFile(Format('icon_%s_48.bmp', [Names[I]]));
      
      Bitmap := IconRenderer.RenderIcon(Path, 96, $FFFF4500);
      Bitmap.SaveToFile(Format('icon_%s_96.bmp', [Names[I]]));
      
      WriteLn('已生成图标: ', Names[I]);
    end;
    
    WriteLn('缓存中的图标数: ', IconRenderer.FCache.Count);
    
  finally
    Path.Free;
    IconRenderer.Free;
  end;
end;

procedure RenderComplexPath;
var
  Bitmap: TBitmap32;
  Path: TSVGPath;
  Renderer: TSVGRenderer;
  Style: TSVGStyle;
  ViewBox: TRectF;
begin
  WriteLn('=== 复杂路径渲染 ===');
  WriteLn;
  
  Bitmap := TBitmap32.Create;
  Path := TSVGPath.Create;
  Renderer := TSVGRenderer.Create(Bitmap);
  try
    Bitmap.SetSize(400, 400);
    Bitmap.Clear($FFF0F0F0);
    
    // 创建一个复杂的花朵形状
    Path.ParsePathData(
      'M 200 100 ' +
      'C 150 100, 100 150, 100 200 ' +
      'C 100 150, 150 100, 200 100 ' +
      'C 200 50, 250 0, 300 0 ' +
      'C 250 0, 200 50, 200 100 ' +
      'C 200 100, 250 150, 300 200 ' +
      'C 250 150, 200 100, 200 100 ' +
      'C 200 150, 250 200, 300 200 ' +
      'C 250 200, 200 150, 200 100 ' +
      'C 200 150, 150 200, 100 200 ' +
      'C 150 200, 200 150, 200 100 ' +
      'Z'
    );
    
    // 设置样式
    Style.Fill := $FFFF69B4;  // 粉色
    Style.HasFill := True;
    Style.Stroke := $FF8B008B;  // 深紫色
    Style.HasStroke := True;
    Style.StrokeWidth := 2;
    Style.FillOpacity := 220;
    Style.StrokeOpacity := 255;
    
    // 设置视图框
    ViewBox.Left := 0;
    ViewBox.Top := 0;
    ViewBox.Right := 400;
    ViewBox.Bottom := 400;
    
    Renderer.ViewBox := ViewBox;
    Renderer.PreserveAspectRatio := True;
    
    // 渲染带阴影
    Renderer.RenderWithShadow(Path, Style, 
      $80000000,  // 半透明黑色阴影
      PointF(5, 5),  // 偏移
      3);  // 模糊半径
    
    // 保存结果
    Bitmap.SaveToFile('test_complex.bmp');
    WriteLn('已生成: test_complex.bmp');
    
  finally
    Renderer.Free;
    Path.Free;
    Bitmap.Free;
  end;
end;

procedure RenderAnimation;
var
  Bitmap: TBitmap32;
  Path: TSVGPath;
  Renderer: TSVGRenderer;
  Transform: TSVGTransform;
  Style: TSVGStyle;
  ViewBox: TRectF;
  I: Integer;
  Angle: Double;
begin
  WriteLn('=== 动画序列渲染 ===');
  WriteLn;
  
  Bitmap := TBitmap32.Create;
  Path := TSVGPath.Create;
  Renderer := TSVGRenderer.Create(Bitmap);
  Transform := TSVGTransform.Create;
  try
    Bitmap.SetSize(200, 200);
    
    // 创建星形路径
    Path.ParsePathData(ICON_STAR);
    
    // 设置样式
    Style.Fill := $FFFFD700;  // 金色
    Style.HasFill := True;
    Style.Stroke := $FFFF8C00;  // 深橙色
    Style.HasStroke := True;
    Style.StrokeWidth := 1;
    Style.FillOpacity := 255;
    
    // 设置视图框
    ViewBox.Left := 0;
    ViewBox.Top := 0;
    ViewBox.Right := 24;
    ViewBox.Bottom := 24;
    
    Renderer.ViewBox := ViewBox;
    
    // 生成旋转动画帧
    for I := 0 to 7 do
    begin
      Bitmap.Clear($FFF0F0F0);
      
      // 应用旋转变换
      Angle := (I * 45) * PI / 180;
      Transform.Reset;
      Transform.Rotate(Angle, 12, 12);  // 绕中心旋转
      
      Path.Transform(Transform.Matrix);
      Renderer.RenderPath(Path, Style);
      
      // 恢复原始状态
      Transform.Reset;
      Transform.Rotate(-Angle, 12, 12);
      Path.Transform(Transform.Matrix);
      
      // 保存帧
      Bitmap.SaveToFile(Format('anim_frame_%d.bmp', [I]));
    end;
    
    WriteLn('已生成8帧动画');
    
  finally
    Transform.Free;
    Renderer.Free;
    Path.Free;
    Bitmap.Free;
  end;
end;

procedure BenchmarkPerformance;
var
  Bitmap: TBitmap32;
  Path: TSVGPath;
  Renderer: TSVGRenderer;
  IconRenderer: TSVGIconRenderer;
  Style: TSVGStyle;
  StartTime: QWord;
  I: Integer;
begin
  WriteLn('=== 性能测试 ===');
  WriteLn;
  
  Bitmap := TBitmap32.Create;
  Path := TSVGPath.Create;
  Renderer := TSVGRenderer.Create(Bitmap);
  IconRenderer := TSVGIconRenderer.Create;
  try
    Bitmap.SetSize(100, 100);
    
    // 解析复杂路径
    Path.ParsePathData(ICON_SETTINGS);
    
    Style.Fill := clBlack32;
    Style.HasFill := True;
    Style.Stroke := clNone32;
    Style.HasStroke := False;
    
    Renderer.ViewBox := RectF(0, 0, 24, 24);
    
    // 测试直接渲染
    StartTime := GetTickCount64;
    for I := 1 to 1000 do
    begin
      Bitmap.Clear(clWhite32);
      Renderer.RenderPath(Path, Style);
    end;
    WriteLn('1000次直接渲染耗时: ', GetTickCount64 - StartTime, 'ms');
    
    // 测试缓存渲染
    StartTime := GetTickCount64;
    for I := 1 to 1000 do
    begin
      IconRenderer.RenderIcon(Path, 100, clBlack32);
    end;
    WriteLn('1000次缓存渲染耗时: ', GetTickCount64 - StartTime, 'ms');
    WriteLn('  (第一次会创建缓存，后续从缓存读取)');
    
    // 测试抗锯齿开关
    Renderer.FRasterizer.AntiAlias := False;
    StartTime := GetTickCount64;
    for I := 1 to 1000 do
    begin
      Bitmap.Clear(clWhite32);
      Renderer.RenderPath(Path, Style);
    end;
    WriteLn('1000次无抗锯齿渲染耗时: ', GetTickCount64 - StartTime, 'ms');
    
  finally
    IconRenderer.Free;
    Renderer.Free;
    Path.Free;
    Bitmap.Free;
  end;
end;

begin
  WriteLn('========================================');
  WriteLn('   SVG 渲染集成测试');
  WriteLn('   FaFaFa Core Framework');
  WriteLn('========================================');
  WriteLn;
  
  try
    RenderBasicSVG;
    WriteLn;
    
    RenderGradient;
    WriteLn;
    
    RenderIcons;
    WriteLn;
    
    RenderComplexPath;
    WriteLn;
    
    RenderAnimation;
    WriteLn;
    
    BenchmarkPerformance;
    WriteLn;
    
    WriteLn('========================================');
    WriteLn('所有测试完成！');
    WriteLn('生成的文件在当前目录');
    WriteLn('========================================');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.