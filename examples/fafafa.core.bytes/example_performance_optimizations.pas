program example_performance_optimizations;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.bytes;

procedure DemoOptimizedGrowthStrategy;
var
  bb: TBytesBuilder;
  i: Integer;
  startTime, endTime: QWord;
begin
  WriteLn('=== 演示优化的内存增长策略 ===');
  
  bb.Init(0);
  startTime := GetTickCount64;
  
  // 模拟大量小数据追加
  for i := 1 to 10000 do
  begin
    bb.AppendByte(Byte(i and $FF));
  end;
  
  endTime := GetTickCount64;
  WriteLn('追加 10000 字节耗时: ', endTime - startTime, ' ms');
  WriteLn('最终容量: ', bb.Capacity, ', 长度: ', bb.Length);
  WriteLn('容量利用率: ', Format('%.2f%%', [bb.Length * 100.0 / bb.Capacity]));
  WriteLn;
end;

procedure DemoHighPerformanceBatchOps;
var
  bb: TBytesBuilder;
  pattern: TBytes;
  result: TBytes;
  startTime, endTime: QWord;
begin
  WriteLn('=== 演示高性能批量操作 ===');
  
  bb.Init(0);
  
  // 演示 AppendFill
  WriteLn('使用 AppendFill 填充 1MB 零字节...');
  startTime := GetTickCount64;
  bb.AppendFill(0, 1024 * 1024);
  endTime := GetTickCount64;
  WriteLn('AppendFill 耗时: ', endTime - startTime, ' ms');
  
  bb.Clear;
  
  // 演示 AppendRepeat
  WriteLn('使用 AppendRepeat 重复模式...');
  pattern := HexToBytes('DEADBEEF');
  startTime := GetTickCount64;
  bb.AppendRepeat(pattern, 10000);  // 重复 10000 次
  endTime := GetTickCount64;
  WriteLn('AppendRepeat 耗时: ', endTime - startTime, ' ms');
  WriteLn('生成数据长度: ', bb.Length, ' 字节');
  
  // 验证结果
  result := bb.ToBytes;
  WriteLn('前8字节: ', BytesToHexUpper(BytesSlice(result, 0, 8)));
  WriteLn('后8字节: ', BytesToHexUpper(BytesSlice(result, Length(result) - 8, 8)));
  WriteLn;
end;

procedure DemoZeroCopyOperations;
var
  bb: TBytesBuilder;
  data1, data2: TBytes;
  usedLen: SizeInt;
  p: Pointer;
  n: SizeInt;
begin
  WriteLn('=== 演示零拷贝操作 ===');
  
  bb.Init(0);
  bb.AppendHex('DEADBEEFCAFEBABE');
  
  // 演示 Peek（借用指针）
  bb.Peek(p, n);
  WriteLn('Peek 借用指针，长度: ', n);
  WriteLn('通过指针读取前4字节: ', BytesToHexUpper(BytesSlice(TBytes(p), 0, 4)));
  
  // 演示 DetachNoTrim（严格零拷贝）
  data1 := bb.DetachNoTrim(usedLen);
  WriteLn('DetachNoTrim 零拷贝转移，使用长度: ', usedLen, ', 容量: ', Length(data1));
  
  // 重新构建
  bb.Init(0);
  bb.AppendHex('0123456789ABCDEF');
  
  // 演示 IntoBytes（智能零拷贝）
  bb.ShrinkToFit;  // 确保容量等于长度
  data2 := bb.IntoBytes;
  WriteLn('IntoBytes 智能转移，长度: ', Length(data2));
  WriteLn('数据内容: ', BytesToHexUpper(data2));
  WriteLn;
end;

procedure DemoErrorHandlingConsistency;
var
  bb: TBytesBuilder;
  data: TBytes;
begin
  WriteLn('=== 演示统一的错误处理 ===');
  
  try
    // 测试 HexToBytes 的统一异常
    data := HexToBytes('GG');  // 非法字符
  except
    on E: EInvalidArgument do
      WriteLn('HexToBytes 非法字符异常: ', E.Message);
  end;
  
  try
    // 测试 HexToBytes 的奇数长度异常
    data := HexToBytes('ABC');  // 奇数长度
  except
    on E: EInvalidArgument do
      WriteLn('HexToBytes 奇数长度异常: ', E.Message);
  end;
  
  bb.Init(0);
  try
    // 测试负数参数异常
    bb.AppendFill(0, -1);
  except
    on E: EInvalidArgument do
      WriteLn('AppendFill 负数参数异常: ', E.Message);
  end;
  
  try
    // 测试 AppendRepeat 负数异常
    bb.AppendRepeat(HexToBytes('00'), -1);
  except
    on E: EInvalidArgument do
      WriteLn('AppendRepeat 负数参数异常: ', E.Message);
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.bytes 性能优化演示');
  WriteLn('================================');
  WriteLn;
  
  DemoOptimizedGrowthStrategy;
  DemoHighPerformanceBatchOps;
  DemoZeroCopyOperations;
  DemoErrorHandlingConsistency;
  
  WriteLn('演示完成。');
  WriteLn('按回车键退出...');
  ReadLn;
end.
