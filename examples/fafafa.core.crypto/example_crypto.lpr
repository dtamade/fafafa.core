{$CODEPAGE UTF8}
program example_crypto;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.crypto;

procedure DemoHashAlgorithms;
var
  LData: string;
  LHash256, LHash512: TBytes;
  LHasher: IHashAlgorithm;
begin
  WriteLn('=== 哈希算法演示 ===');
  WriteLn;
  
  LData := 'Hello, fafafa.core.crypto!';
  WriteLn('原始数据: "', LData, '"');
  WriteLn;
  
  // 使用便利函数计算哈希
  LHash256 := HashSHA256(LData);
  LHash512 := HashSHA512(LData);
  
  WriteLn('SHA-256: ', BytesToHex(LHash256));
  WriteLn('SHA-512: ', BytesToHex(LHash512));
  WriteLn;
  
  // 使用接口进行流式哈希计算
  WriteLn('--- 流式哈希计算演示 ---');
  LHasher := CreateSHA256;
  LHasher.Update(PChar('Hello, ')^, 7);
  LHasher.Update(PChar('fafafa.core.crypto!')^, 19);
  LHash256 := LHasher.Finalize;
  
  WriteLn('流式 SHA-256: ', BytesToHex(LHash256));
  WriteLn;
end;

procedure DemoSecureRandom;
var
  LRandom: ISecureRandom;
  LBytes: TBytes;
  LInteger: Integer;
  LI: Integer;
begin
  WriteLn('=== 安全随机数生成演示 ===');
  WriteLn;
  
  LRandom := GetSecureRandom;
  
  // 生成随机字节
  LBytes := LRandom.GetBytes(16);
  WriteLn('16字节随机数: ', BytesToHex(LBytes));
  
  // 使用便利函数
  LBytes := GenerateRandomBytes(8);
  WriteLn('8字节随机数: ', BytesToHex(LBytes));
  WriteLn;
  
  // 生成随机整数
  WriteLn('--- 随机整数演示 ---');
  for LI := 1 to 10 do
  begin
    LInteger := LRandom.GetInteger(1, 100);
    Write(LInteger, ' ');
  end;
  WriteLn;
  WriteLn;
  
  // 使用便利函数
  WriteLn('使用便利函数生成随机整数 [1-6]:');
  for LI := 1 to 10 do
  begin
    LInteger := GenerateRandomInteger(1, 6);
    Write(LInteger, ' ');
  end;
  WriteLn;
  WriteLn;
end;

procedure DemoUtilityFunctions;
var
  LOriginalData: TBytes;
  LHexString: string;
  LRestoredData: TBytes;
  LData1, LData2: TBytes;
  LBuffer: array[0..15] of Byte;
  LI: Integer;
begin
  WriteLn('=== 工具函数演示 ===');
  WriteLn;
  
  // 字节与十六进制转换
  WriteLn('--- 字节与十六进制转换 ---');
  LOriginalData := TEncoding.UTF8.GetBytes('Hello World');
  LHexString := BytesToHex(LOriginalData);
  WriteLn('原始数据: "Hello World"');
  WriteLn('十六进制: ', LHexString);
  
  LRestoredData := HexToBytes(LHexString);
  WriteLn('恢复数据: "', TEncoding.UTF8.GetString(LRestoredData), '"');
  WriteLn;
  
  // 安全比较
  WriteLn('--- 安全比较演示 ---');
  LData1 := TEncoding.UTF8.GetBytes('secret');
  LData2 := TEncoding.UTF8.GetBytes('secret');
  WriteLn('比较相同数据: ', SecureCompare(LData1, LData2));
  
  LData2 := TEncoding.UTF8.GetBytes('public');
  WriteLn('比较不同数据: ', SecureCompare(LData1, LData2));
  WriteLn;
  
  // 安全清零
  WriteLn('--- 安全清零演示 ---');
  for LI := 0 to 15 do
    LBuffer[LI] := $FF;
    
  Write('清零前: ');
  for LI := 0 to 15 do
    Write(Format('%.2x ', [LBuffer[LI]]));
  WriteLn;
  
  SecureZero(LBuffer, SizeOf(LBuffer));
  
  Write('清零后: ');
  for LI := 0 to 15 do
    Write(Format('%.2x ', [LBuffer[LI]]));
  WriteLn;
  WriteLn;
end;

procedure DemoHashPerformance;
var
  LData: TBytes;
  LHasher: IHashAlgorithm;
  LResult: TBytes;
  LStartTime, LEndTime: TDateTime;
  LI: Integer;
const
  ITERATIONS = 10000;
begin
  WriteLn('=== 哈希性能测试 ===');
  WriteLn;
  
  // 准备测试数据
  SetLength(LData, 1024);
  for LI := 0 to 1023 do
    LData[LI] := LI mod 256;
    
  // SHA-256 性能测试
  WriteLn('SHA-256 性能测试 (', ITERATIONS, ' 次迭代, 1KB数据)...');
  LStartTime := Now;
  
  for LI := 1 to ITERATIONS do
  begin
    LHasher := CreateSHA256;
    LHasher.Update(LData[0], Length(LData));
    LResult := LHasher.Finalize;
  end;
  
  LEndTime := Now;
  WriteLn('耗时: ', FormatDateTime('ss.zzz', LEndTime - LStartTime), ' 秒');
  WriteLn('最后结果: ', BytesToHex(LResult));
  WriteLn;
  
  // SHA-512 性能测试
  WriteLn('SHA-512 性能测试 (', ITERATIONS, ' 次迭代, 1KB数据)...');
  LStartTime := Now;
  
  for LI := 1 to ITERATIONS do
  begin
    LHasher := CreateSHA512;
    LHasher.Update(LData[0], Length(LData));
    LResult := LHasher.Finalize;
  end;
  
  LEndTime := Now;
  WriteLn('耗时: ', FormatDateTime('ss.zzz', LEndTime - LStartTime), ' 秒');
  WriteLn('最后结果: ', BytesToHex(LResult));
  WriteLn;
end;

procedure DemoErrorHandling;
var
  LHasher: IHashAlgorithm;
  LRandom: ISecureRandom;
begin
  WriteLn('=== 错误处理演示 ===');
  WriteLn;
  
  // 测试哈希算法错误处理
  WriteLn('--- 哈希算法错误处理 ---');
  LHasher := CreateSHA256;
  LHasher.Update(PChar('test')^, 4);
  LHasher.Finalize;
  
  try
    LHasher.Finalize; // 重复调用应该抛出异常
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('✓ 正确捕获异常: ', E.ClassName, ' - ', E.Message);
  end;
  
  try
    LHasher.Update(PChar('test')^, 4); // 在finalize后update应该抛出异常
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('✓ 正确捕获异常: ', E.ClassName, ' - ', E.Message);
  end;
  WriteLn;
  
  // 测试随机数生成器错误处理
  WriteLn('--- 随机数生成器错误处理 ---');
  LRandom := GetSecureRandom;
  
  try
    LRandom.GetInteger(10, 5); // 无效范围应该抛出异常
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('✓ 正确捕获异常: ', E.ClassName, ' - ', E.Message);
  end;
  WriteLn;
  
  // 测试工具函数错误处理
  WriteLn('--- 工具函数错误处理 ---');
  try
    HexToBytes('abc'); // 奇数长度应该抛出异常
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('✓ 正确捕获异常: ', E.ClassName, ' - ', E.Message);
  end;
  WriteLn;
end;

begin
  WriteLn('fafafa.core.crypto 模块演示程序');
  WriteLn('==================================');
  WriteLn;
  
  try
    DemoHashAlgorithms;
    DemoSecureRandom;
    DemoUtilityFunctions;
    DemoHashPerformance;
    DemoErrorHandling;
    
    WriteLn('演示完成！');
  except
    on E: Exception do
    begin
      WriteLn('发生错误: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
