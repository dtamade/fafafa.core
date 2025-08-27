{$CODEPAGE UTF8}
program example_mem_pool_config;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.pool.slab;

procedure DemoCustomSlabConfig;
var
  C: TSlabConfig;
  P: TSlabPool;
  A, B: Pointer;
  Stats: TSlabStats;
begin
  WriteLn('--- TSlabPool Config Demo ---');
  // 基于默认配置，启用页面合并，预热2页
  C := CreateDefaultSlabConfig;
  C.EnablePageMerging := True;
  C.WarmupPages := 2;

  // 使用配置创建池（32KB 池）
  P := TSlabPool.Create(32*1024, C);
  try
    // 可选：手动预热指定类别
    P.Warmup(64, 1);

    // 分配/释放演示
    A := P.Alloc(128);
    B := P.Alloc(256);
    if (A <> nil) and (B <> nil) then
      WriteLn('Allocated 128 and 256 bytes');
    P.Free(B);
    P.Free(A);

    // 获取统计并打印关键信息
    Stats := P.GetStats;
    WriteLn('Pages: total=', Stats.TotalPages,
            ' free=', Stats.FreePages,
            ' partial=', Stats.PartialPages,
            ' full=', Stats.FullPages);
    WriteLn('Objects: total=', Stats.TotalObjects,
            ' free=', Stats.FreeObjects);

    // 打印更详细的诊断（可选）
    WriteLn('--- Diagnostics ---');
    WriteLn(P.GetDetailedDiagnostics);
  finally
    P.Destroy;
  end;
end;

function HasArg(const S: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), S) then Exit(True);
end;

begin
  try
    if HasArg('--perf') then
    begin
      WriteLn('[Perf] Diagnostics enabled');
      // Perf/Diagnostics 已默认打印；未来可在此扩展更细粒度统计输出
    end;

    DemoCustomSlabConfig;
    WriteLn('Config demo completed.');
  except
    on E: Exception do begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.
