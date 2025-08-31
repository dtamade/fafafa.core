program test_complete_simd;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd;

procedure TestSIMDFramework;
var
  info: TSIMDInfo;
begin
  WriteLn('=== 完整 SIMD 框架测试 ===');
  
  try
    // 获取 SIMD 信息
    info := GetSIMDInfo;
    
    WriteLn('CPU 架构: ', GetSIMDArchitectureName(info.Architecture));
    WriteLn('厂商: "', info.VendorString, '"');
    WriteLn('品牌: "', info.BrandString, '"');
    
    WriteLn('');
    WriteLn('SIMD 特性支持:');
    WriteLn('  MMX: ', info.Features.MMX);
    WriteLn('  SSE: ', info.Features.SSE);
    WriteLn('  SSE2: ', info.Features.SSE2);
    WriteLn('  SSE3: ', info.Features.SSE3);
    WriteLn('  SSSE3: ', info.Features.SSSE3);
    WriteLn('  SSE4_1: ', info.Features.SSE4_1);
    WriteLn('  SSE4_2: ', info.Features.SSE4_2);
    WriteLn('  AVX: ', info.Features.AVX);
    WriteLn('  AVX2: ', info.Features.AVX2);
    WriteLn('  AVX512F: ', info.Features.AVX512F);
    
    WriteLn('');
    WriteLn('ARM 特性支持:');
    WriteLn('  NEON: ', info.Features.NEON);
    WriteLn('  SVE: ', info.Features.SVE);
    WriteLn('  SVE2: ', info.Features.SVE2);
    
    WriteLn('');
    WriteLn('RISC-V 特性支持:');
    WriteLn('  RVV: ', info.Features.RVV);
    
    WriteLn('');
    WriteLn('推荐的向量宽度: ', info.PreferredVectorWidth, ' 位');
    WriteLn('最大向量宽度: ', info.MaxVectorWidth, ' 位');
    
    // 测试特性检查函数
    WriteLn('');
    WriteLn('特性检查函数测试:');
    WriteLn('  HasSSE: ', HasSSE);
    WriteLn('  HasAVX: ', HasAVX);
    WriteLn('  HasAVX2: ', HasAVX2);
    WriteLn('  HasNEON: ', HasNEON);
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('=== 测试完成 ===');
end;

begin
  try
    TestSIMDFramework;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('按任意键退出...');
  ReadLn;
end.
