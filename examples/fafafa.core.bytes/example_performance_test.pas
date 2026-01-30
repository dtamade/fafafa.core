program example_performance_test;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, DateUtils, StrUtils,
  fafafa.core.base,
  fafafa.core.bytes;

procedure TestAppendRepeatPerformance;
var
  bb: TBytesBuilder;
  pattern: TBytes;
  startTime, endTime: TDateTime;
  i: Integer;
  result: TBytes;
begin
  WriteLn('=== AppendRepeat 性能测试 ===');
  
  // 准备测试数据
  pattern := HexToBytes('DEADBEEF');
  
  // 测试小规模重复（1000次）
  bb.Init(0);
  startTime := Now;
  bb.AppendRepeat(pattern, 1000);
  endTime := Now;
  result := bb.ToBytes;
  
  WriteLn('小规模测试 (1000次重复):');
  WriteLn('  模式长度: ', Length(pattern), ' 字节');
  WriteLn('  总长度: ', Length(result), ' 字节');
  WriteLn('  耗时: ', MilliSecondsBetween(endTime, startTime), ' ms');
  WriteLn('  验证: ', IfThen(Length(result) = 4000, '通过', '失败'));
  WriteLn;
  
  // 测试大规模重复（100000次）
  bb.Reset;
  startTime := Now;
  bb.AppendRepeat(pattern, 100000);
  endTime := Now;
  result := bb.ToBytes;
  
  WriteLn('大规模测试 (100000次重复):');
  WriteLn('  模式长度: ', Length(pattern), ' 字节');
  WriteLn('  总长度: ', Length(result), ' 字节');
  WriteLn('  耗时: ', MilliSecondsBetween(endTime, startTime), ' ms');
  WriteLn('  验证: ', IfThen(Length(result) = 400000, '通过', '失败'));
  WriteLn;
  
  // 验证数据正确性
  WriteLn('数据正确性验证:');
  WriteLn('  前4字节: ', BytesToHexUpper(Copy(result, 0, 4)));
  WriteLn('  后4字节: ', BytesToHexUpper(Copy(result, Length(result)-4, 4)));
  WriteLn('  期望值: DEADBEEF');
end;

procedure TestHexPerformance;
var
  data: TBytes;
  hexStr: string;
  startTime, endTime: TDateTime;
  i: Integer;
begin
  WriteLn('=== Hex 编解码性能测试 ===');
  
  // 准备大量测试数据
  SetLength(data, 10000);
  for i := 0 to High(data) do
    data[i] := Byte(i mod 256);
  
  // 测试 Hex 编码
  startTime := Now;
  for i := 1 to 100 do
    hexStr := BytesToHex(data);
  endTime := Now;
  
  WriteLn('Hex 编码测试 (100次 x 10KB):');
  WriteLn('  数据长度: ', Length(data), ' 字节');
  WriteLn('  Hex 长度: ', Length(hexStr), ' 字符');
  WriteLn('  平均耗时: ', MilliSecondsBetween(endTime, startTime) / 100:0:2, ' ms/次');
  WriteLn;
  
  // 测试 Hex 解码
  startTime := Now;
  for i := 1 to 100 do
    data := HexToBytes(hexStr);
  endTime := Now;
  
  WriteLn('Hex 解码测试 (100次 x 20K字符):');
  WriteLn('  Hex 长度: ', Length(hexStr), ' 字符');
  WriteLn('  数据长度: ', Length(data), ' 字节');
  WriteLn('  平均耗时: ', MilliSecondsBetween(endTime, startTime) / 100:0:2, ' ms/次');
end;

procedure TestBytesBuilderGrowth;
var
  bb: TBytesBuilder;
  startTime, endTime: TDateTime;
  i: Integer;
  finalSize: SizeInt;
begin
  WriteLn('=== BytesBuilder 增长策略测试 ===');
  
  bb.Init(1);
  startTime := Now;
  
  // 逐步增长到 1MB
  for i := 1 to 1000000 do
    bb.AppendByte(Byte(i mod 256));
  
  endTime := Now;
  finalSize := bb.Length();
  
  WriteLn('增长测试 (1M 字节逐个添加):');
  WriteLn('  最终长度: ', finalSize, ' 字节');
  WriteLn('  最终容量: ', bb.Capacity, ' 字节');
  WriteLn('  容量利用率: ', (finalSize * 100.0 / bb.Capacity):0:1, '%');
  WriteLn('  总耗时: ', MilliSecondsBetween(endTime, startTime), ' ms');
  WriteLn('  平均速度: ', (finalSize / 1024 / 1024) / (MilliSecondsBetween(endTime, startTime) / 1000):0:2, ' MB/s');
end;

begin
  WriteLn('fafafa.core.bytes 性能测试');
  WriteLn('编译时间: ', {$I %DATE%}, ' ', {$I %TIME%});
  WriteLn;
  
  try
    TestAppendRepeatPerformance;
    WriteLn;
    TestHexPerformance;
    WriteLn;
    TestBytesBuilderGrowth;
    
    WriteLn;
    WriteLn('所有性能测试完成！');
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
