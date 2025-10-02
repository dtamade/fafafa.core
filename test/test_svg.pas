program TestSVG;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Math, Types,
  fafafa.core.graphics,
  fafafa.core.graphics.svg.improved;

procedure TestPathParsing;
var
  Path: TSVGPath;
  Points: array of TPointF;
  I: Integer;
  Bounds: TRectF;
begin
  WriteLn('=== 测试SVG路径解析 ===');
  WriteLn;
  
  Path := TSVGPath.Create;
  try
    // 测试1：简单路径
    WriteLn('测试1：简单矩形路径');
    Path.ParsePathData('M 10 10 L 110 10 L 110 110 L 10 110 Z');
    WriteLn('  命令数：', Path.CommandCount);
    Bounds := Path.GetBounds;
    WriteLn('  边界框：(', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    WriteLn;
    
    // 测试2：相对坐标
    WriteLn('测试2：相对坐标路径');
    Path.Clear;
    Path.ParsePathData('M 10 10 l 100 0 l 0 100 l -100 0 z');
    WriteLn('  命令数：', Path.CommandCount);
    Bounds := Path.GetBounds;
    WriteLn('  边界框：(', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    WriteLn;
    
    // 测试3：贝塞尔曲线
    WriteLn('测试3：贝塞尔曲线路径');
    Path.Clear;
    Path.ParsePathData('M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80');
    WriteLn('  命令数：', Path.CommandCount);
    Points := Path.Flatten(0.5);
    WriteLn('  展平后点数：', Length(Points));
    WriteLn;
    
    // 测试4：二次贝塞尔曲线
    WriteLn('测试4：二次贝塞尔曲线');
    Path.Clear;
    Path.ParsePathData('M 10 80 Q 95 10 180 80 T 350 80');
    WriteLn('  命令数：', Path.CommandCount);
    Points := Path.Flatten(0.5);
    WriteLn('  展平后点数：', Length(Points));
    WriteLn;
    
    // 测试5：椭圆弧
    WriteLn('测试5：椭圆弧路径');
    Path.Clear;
    Path.ParsePathData('M 10 10 A 30 50 0 0 1 70 60');
    WriteLn('  命令数：', Path.CommandCount);
    WriteLn('  注：弧线已转换为贝塞尔曲线');
    WriteLn;
    
    // 测试6：复杂路径（心形）
    WriteLn('测试6：复杂心形路径');
    Path.Clear;
    Path.ParsePathData('M 12,21.35 ' +
      'c -1.6,-6.9 -10.65,-6.9 -12.25,0 ' +
      'c 0,3.45 3.3,6.225 12.25,15.3 ' +
      'c 8.95,-9.075 12.25,-11.85 12.25,-15.3 ' +
      'c -1.6,-6.9 -10.65,-6.9 -12.25,0 z');
    WriteLn('  命令数：', Path.CommandCount);
    Bounds := Path.GetBounds;
    WriteLn('  边界框：(', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    Points := Path.Flatten(0.25);
    WriteLn('  展平后点数：', Length(Points));
    WriteLn;
    
  finally
    Path.Free;
  end;
end;

procedure TestTransform;
var
  Path: TSVGPath;
  Transform: TSVGTransform;
  Matrix: TMatrix2D;
  Bounds: TRectF;
begin
  WriteLn('=== 测试2D变换 ===');
  WriteLn;
  
  Path := TSVGPath.Create;
  Transform := TSVGTransform.Create;
  try
    // 创建一个正方形
    Path.ParsePathData('M 0 0 L 100 0 L 100 100 L 0 100 Z');
    
    WriteLn('原始边界框：');
    Bounds := Path.GetBounds;
    WriteLn('  (', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    
    // 测试平移
    Transform.Reset;
    Transform.Translate(50, 50);
    Path.Transform(Transform.Matrix);
    WriteLn('平移(50,50)后：');
    Bounds := Path.GetBounds;
    WriteLn('  (', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    
    // 测试缩放
    Path.Clear;
    Path.ParsePathData('M 0 0 L 100 0 L 100 100 L 0 100 Z');
    Transform.Reset;
    Transform.Scale(2, 2);
    Path.Transform(Transform.Matrix);
    WriteLn('缩放(2,2)后：');
    Bounds := Path.GetBounds;
    WriteLn('  (', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    
    // 测试旋转
    Path.Clear;
    Path.ParsePathData('M 0 0 L 100 0 L 100 100 L 0 100 Z');
    Transform.Reset;
    Transform.Rotate(PI/4, 50, 50);  // 绕中心旋转45度
    Path.Transform(Transform.Matrix);
    WriteLn('旋转45度后：');
    Bounds := Path.GetBounds;
    WriteLn('  (', Bounds.Left:0:1, ',', Bounds.Top:0:1, 
            ') - (', Bounds.Right:0:1, ',', Bounds.Bottom:0:1, ')');
    
    WriteLn;
    
  finally
    Transform.Free;
    Path.Free;
  end;
end;

procedure TestArcConversion;
var
  Path: TSVGPath;
  I: Integer;
begin
  WriteLn('=== 测试椭圆弧算法 ===');
  WriteLn;
  
  Path := TSVGPath.Create;
  try
    // 测试各种弧参数组合
    WriteLn('测试1：简单弧');
    Path.Clear;
    Path.ArcTo(50, 30, 0, False, True, 100, 50, True);
    WriteLn('  生成命令数：', Path.CommandCount);
    
    WriteLn('测试2：大弧');
    Path.Clear;
    Path.MoveTo(0, 0);
    Path.ArcTo(50, 50, 0, True, False, 100, 0, True);
    WriteLn('  生成命令数：', Path.CommandCount);
    
    WriteLn('测试3：旋转弧');
    Path.Clear;
    Path.MoveTo(0, 0);
    Path.ArcTo(50, 30, 45, False, True, 100, 0, True);
    WriteLn('  生成命令数：', Path.CommandCount);
    
    WriteLn('测试4：退化为直线');
    Path.Clear;
    Path.MoveTo(0, 0);
    Path.ArcTo(0, 0, 0, False, True, 100, 100, True);
    WriteLn('  生成命令数：', Path.CommandCount, ' (应该为1)');
    
    WriteLn;
  finally
    Path.Free;
  end;
end;

procedure TestPerformance;
var
  Path: TSVGPath;
  ComplexPath: string;
  StartTime: QWord;
  Points: array of TPointF;
  I: Integer;
begin
  WriteLn('=== 性能测试 ===');
  WriteLn;
  
  // 构建复杂路径
  ComplexPath := 'M 0 0 ';
  for I := 1 to 100 do
  begin
    ComplexPath := ComplexPath + Format('L %d %d ', [Random(500), Random(500)]);
    if I mod 10 = 0 then
      ComplexPath := ComplexPath + Format('C %d,%d %d,%d %d,%d ', 
        [Random(500), Random(500), Random(500), Random(500), Random(500), Random(500)]);
  end;
  ComplexPath := ComplexPath + 'Z';
  
  Path := TSVGPath.Create;
  try
    // 测试解析性能
    StartTime := GetTickCount64;
    Path.ParsePathData(ComplexPath);
    WriteLn('解析100个线段+10个曲线耗时：', GetTickCount64 - StartTime, 'ms');
    WriteLn('  生成命令数：', Path.CommandCount);
    
    // 测试展平性能
    StartTime := GetTickCount64;
    Points := Path.Flatten(0.5);
    WriteLn('展平路径耗时：', GetTickCount64 - StartTime, 'ms');
    WriteLn('  生成点数：', Length(Points));
    
    // 测试变换性能
    StartTime := GetTickCount64;
    for I := 1 to 100 do
    begin
      Path.Transform(CreateRotateMatrix(0.01));
    end;
    WriteLn('100次旋转变换耗时：', GetTickCount64 - StartTime, 'ms');
    
    WriteLn;
  finally
    Path.Free;
  end;
end;

procedure GenerateSVGFile;
var
  SVG: TStringList;
  Path: TSVGPath;
  Points: array of TPointF;
  I: Integer;
begin
  WriteLn('=== 生成SVG文件 ===');
  WriteLn;
  
  SVG := TStringList.Create;
  Path := TSVGPath.Create;
  try
    SVG.Add('<?xml version="1.0" encoding="UTF-8"?>');
    SVG.Add('<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">');
    
    // 添加背景
    SVG.Add('  <rect width="400" height="400" fill="#f0f0f0"/>');
    
    // 测试各种图形
    
    // 1. 矩形
    SVG.Add('  <!-- 矩形 -->');
    SVG.Add('  <path d="M 20 20 L 120 20 L 120 120 L 20 120 Z" ');
    SVG.Add('        fill="blue" fill-opacity="0.5" stroke="navy" stroke-width="2"/>');
    
    // 2. 圆形（用贝塞尔曲线近似）
    SVG.Add('  <!-- 圆形 -->');
    SVG.Add('  <path d="M 200 70 ');
    SVG.Add('        C 200 97.6 177.6 120 150 120');
    SVG.Add('        C 122.4 120 100 97.6 100 70');
    SVG.Add('        C 100 42.4 122.4 20 150 20');
    SVG.Add('        C 177.6 20 200 42.4 200 70 Z"');
    SVG.Add('        fill="red" fill-opacity="0.5" stroke="darkred" stroke-width="2"/>');
    
    // 3. 星形
    SVG.Add('  <!-- 星形 -->');
    SVG.Add('  <path d="M 270 60 L 280 40 L 290 60 L 310 60 L 295 75');
    SVG.Add('        L 300 95 L 280 80 L 260 95 L 265 75 L 250 60 Z"');
    SVG.Add('        fill="yellow" stroke="orange" stroke-width="2"/>');
    
    // 4. 心形
    SVG.Add('  <!-- 心形 -->');
    SVG.Add('  <path d="M 60 180');
    SVG.Add('        c -20 -40 -60 -40 -60 0');
    SVG.Add('        c 0 20 20 40 60 80');
    SVG.Add('        c 40 -40 60 -60 60 -80');
    SVG.Add('        c 0 -40 -40 -40 -60 0 z"');
    SVG.Add('        fill="pink" stroke="red" stroke-width="2"');
    SVG.Add('        transform="translate(100,0)"/>');
    
    // 5. 波浪线
    SVG.Add('  <!-- 波浪线 -->');
    SVG.Add('  <path d="M 20 300 Q 40 280 60 300 T 100 300 T 140 300 T 180 300"');
    SVG.Add('        fill="none" stroke="green" stroke-width="3"/>');
    
    // 6. 螺旋（使用弧线）
    SVG.Add('  <!-- 螺旋 -->');
    SVG.Add('  <path d="M 250 250');
    SVG.Add('        A 10 10 0 0 1 270 250');
    SVG.Add('        A 20 20 0 0 1 230 250');
    SVG.Add('        A 30 30 0 0 1 290 250');
    SVG.Add('        A 40 40 0 0 1 210 250"');
    SVG.Add('        fill="none" stroke="purple" stroke-width="2"/>');
    
    // 7. 文字路径示例
    SVG.Add('  <!-- 文字说明 -->');
    SVG.Add('  <text x="200" y="380" font-family="Arial" font-size="14" fill="black">');
    SVG.Add('    SVG Path Test - FaFaFa Framework');
    SVG.Add('  </text>');
    
    SVG.Add('</svg>');
    
    // 保存文件
    SVG.SaveToFile('test_output.svg');
    WriteLn('已生成文件：test_output.svg');
    WriteLn('可以用浏览器打开查看');
    WriteLn;
    
  finally
    Path.Free;
    SVG.Free;
  end;
end;

begin
  Randomize;
  
  WriteLn('========================================');
  WriteLn('   SVG 路径解析和渲染测试程序');
  WriteLn('   FaFaFa Core Framework');
  WriteLn('========================================');
  WriteLn;
  
  try
    TestPathParsing;
    TestTransform;
    TestArcConversion;
    TestPerformance;
    GenerateSVGFile;
    
    WriteLn('========================================');
    WriteLn('所有测试完成！');
    WriteLn('========================================');
  except
    on E: Exception do
    begin
      WriteLn('错误：', E.Message);
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.