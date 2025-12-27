{**
 * test_layout_overflow.pas - TMemLayout 溢出保护测试
 *
 * @desc 测试 P0-5 修复：NextPowerOfTwo 和 TryCreate 的溢出保护
 *}
program test_layout_overflow;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.layout;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;

procedure Check(aCondition: Boolean; const aTestName: string);
begin
  if aCondition then
  begin
    Inc(GTestsPassed);
    WriteLn('  [PASS] ', aTestName);
  end
  else
  begin
    Inc(GTestsFailed);
    WriteLn('  [FAIL] ', aTestName);
  end;
end;

procedure TestNextPowerOfTwo;
begin
  WriteLn('=== TestNextPowerOfTwo ===');

  // 基本测试
  Check(NextPowerOfTwo(0) = 1, '0 -> 1');
  Check(NextPowerOfTwo(1) = 1, '1 -> 1');
  Check(NextPowerOfTwo(2) = 2, '2 -> 2');
  Check(NextPowerOfTwo(3) = 4, '3 -> 4');
  Check(NextPowerOfTwo(4) = 4, '4 -> 4');
  Check(NextPowerOfTwo(5) = 8, '5 -> 8');
  Check(NextPowerOfTwo(7) = 8, '7 -> 8');
  Check(NextPowerOfTwo(8) = 8, '8 -> 8');
  Check(NextPowerOfTwo(9) = 16, '9 -> 16');
  Check(NextPowerOfTwo(15) = 16, '15 -> 16');
  Check(NextPowerOfTwo(16) = 16, '16 -> 16');
  Check(NextPowerOfTwo(17) = 32, '17 -> 32');

  // 较大值
  Check(NextPowerOfTwo(1000) = 1024, '1000 -> 1024');
  Check(NextPowerOfTwo(1024) = 1024, '1024 -> 1024');
  Check(NextPowerOfTwo(1025) = 2048, '1025 -> 2048');

  // 边界测试（不应死循环或崩溃）
  {$IFDEF CPU64}
  // 64位系统：最大2的幂是 2^63
  Check(NextPowerOfTwo(High(SizeUInt)) > 0, 'High(SizeUInt) 应返回有效值（饱和策略）');
  Check(NextPowerOfTwo(High(SizeUInt) div 2) > 0, 'High/2 应返回有效值');
  Check(IsPowerOfTwo(NextPowerOfTwo(High(SizeUInt))), 'High(SizeUInt) 结果应是2的幂');
  {$ELSE}
  // 32位系统：最大2的幂是 2^31
  Check(NextPowerOfTwo(High(SizeUInt)) > 0, 'High(SizeUInt) 应返回有效值（饱和策略）');
  Check(IsPowerOfTwo(NextPowerOfTwo(High(SizeUInt))), 'High(SizeUInt) 结果应是2的幂');
  {$ENDIF}

  WriteLn;
end;

procedure TestTryNextPowerOfTwo;
var
  LResult: SizeUInt;
begin
  WriteLn('=== TestTryNextPowerOfTwo ===');

  // 基本测试
  Check(TryNextPowerOfTwo(0, LResult) and (LResult = 1), '0 -> 1');
  Check(TryNextPowerOfTwo(1, LResult) and (LResult = 1), '1 -> 1');
  Check(TryNextPowerOfTwo(3, LResult) and (LResult = 4), '3 -> 4');
  Check(TryNextPowerOfTwo(1000, LResult) and (LResult = 1024), '1000 -> 1024');

  // 溢出测试（应返回 False）
  {$IFDEF CPU64}
  // 2^63 + 1 无法表示为 2 的幂（下一个是 2^64，超出范围）
  Check(not TryNextPowerOfTwo(SizeUInt(1) shl 63 + 1, LResult),
        '超过最大2的幂时应返回 False');
  {$ELSE}
  Check(not TryNextPowerOfTwo(SizeUInt(1) shl 31 + 1, LResult),
        '超过最大2的幂时应返回 False');
  {$ENDIF}

  WriteLn;
end;

procedure TestMemLayoutCreate;
var
  L: TMemLayout;
begin
  WriteLn('=== TestMemLayoutCreate ===');

  // 基本创建
  L := TMemLayout.Create(100, 16);
  Check(L.Size = 100, 'Size = 100');
  Check(L.Align = 16, 'Align = 16');
  Check(L.IsValid, '布局应有效');

  // 默认对齐
  L := TMemLayout.Create(100, 0);
  Check(L.Size = 100, 'Size = 100 (默认对齐)');
  Check(L.Align = MEM_DEFAULT_ALIGN, 'Align = 默认对齐');

  // 非2的幂对齐（应向上取整）
  L := TMemLayout.Create(100, 3);
  Check(L.Align = 4, '对齐 3 应向上取整到 4');
  Check(IsPowerOfTwo(L.Align), '对齐应是2的幂');

  L := TMemLayout.Create(100, 5);
  Check(L.Align = 8, '对齐 5 应向上取整到 8');

  // 极大对齐值（饱和策略）
  L := TMemLayout.Create(100, High(SizeUInt));
  Check(IsPowerOfTwo(L.Align), '极大对齐值应饱和到有效的2的幂');
  Check(L.IsValid, '极大对齐布局应有效');

  WriteLn;
end;

procedure TestMemLayoutTryCreate;
var
  L: TMemLayout;
begin
  WriteLn('=== TestMemLayoutTryCreate ===');

  // 基本测试
  Check(TMemLayout.TryCreate(100, 16, L), 'TryCreate(100, 16) 应成功');
  Check(L.Size = 100, 'Size = 100');
  Check(L.Align = 16, 'Align = 16');

  // 默认对齐
  Check(TMemLayout.TryCreate(100, 0, L), 'TryCreate(100, 0) 应成功');
  Check(L.Align = MEM_DEFAULT_ALIGN, 'Align = 默认对齐');

  // 非2的幂对齐（应向上取整）
  Check(TMemLayout.TryCreate(100, 3, L), 'TryCreate(100, 3) 应成功');
  Check(L.Align = 4, '对齐 3 应向上取整到 4');

  // 溢出测试
  {$IFDEF CPU64}
  Check(not TMemLayout.TryCreate(100, SizeUInt(1) shl 63 + 1, L),
        'TryCreate 极大对齐应失败');
  {$ELSE}
  Check(not TMemLayout.TryCreate(100, SizeUInt(1) shl 31 + 1, L),
        'TryCreate 极大对齐应失败');
  {$ENDIF}

  WriteLn;
end;

procedure TestZeroSizedLayout;
var
  L: TMemLayout;
begin
  WriteLn('=== TestZeroSizedLayout ===');

  L := TMemLayout.Create(0, 1);
  Check(L.IsZeroSized, 'Size=0 应该是 ZeroSized');
  Check(L.IsValid, 'ZeroSized 布局应有效');

  L := TMemLayout.Empty;
  Check(L.IsZeroSized, 'Empty 应该是 ZeroSized');
  Check(L.Size = 0, 'Empty.Size = 0');
  Check(L.Align = 1, 'Empty.Align = 1');

  WriteLn;
end;

begin
  WriteLn('================================================');
  WriteLn('  fafafa.core.mem.layout 溢出保护测试');
  WriteLn('  P0-5 TDD 验证');
  WriteLn('================================================');
  WriteLn;

  TestNextPowerOfTwo;
  TestTryNextPowerOfTwo;
  TestMemLayoutCreate;
  TestMemLayoutTryCreate;
  TestZeroSizedLayout;

  WriteLn('================================================');
  WriteLn('  测试结果: ', GTestsPassed, ' 通过, ', GTestsFailed, ' 失败');
  WriteLn('================================================');

  if GTestsFailed > 0 then
    Halt(1)
  else
    WriteLn('所有测试通过！');
end.
