program PerformanceBenchmark;

{$mode objfpc}{$H+}

{ This is a legacy/obsolete benchmark example kept for reference only.
  NOTE:
  - Types like TStackAllocator/TFixedSizePool/TTrackingAllocator/TAlignedAllocator
    do NOT exist in current mem module. Do NOT use this file as a real benchmark.
  - The framework-level benchmark module will supersede this.
}

uses
  SysUtils, DateUtils,
  fafafa.core.mem;

const
  ITERATIONS = 10000;
  BLOCK_SIZE = 64;

var
  LStartTime, LEndTime: TDateTime;
  LDefaultAllocator: TAllocator;
  LStackAllocator: TStackAllocator;
  LFixedPool: TFixedSizePool;
  LTracker: TTrackingAllocator;
  LAligned: TAlignedAllocator;
  LPtrs: array[0..ITERATIONS-1] of Pointer;
  I: Integer;
  LElapsedMs: Int64;

procedure BenchmarkDefaultAllocator;
begin
  LStartTime := Now;
  
  // 分配
  for I := 0 to ITERATIONS-1 do
    LPtrs[I] := LDefaultAllocator.GetMem(BLOCK_SIZE);
    
  // 释放
  for I := 0 to ITERATIONS-1 do
    LDefaultAllocator.FreeMem(LPtrs[I]);
    
  LEndTime := Now;
  LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
  WriteLn('Default Allocator: ', LElapsedMs, ' ms');
end;

procedure BenchmarkStackAllocator;
begin
  LStackAllocator := TStackAllocator.Create(ITERATIONS * BLOCK_SIZE * 2);
  try
    LStartTime := Now;
    
    // 分配（栈分配器不需要释放）
    for I := 0 to ITERATIONS-1 do
      LPtrs[I] := LStackAllocator.GetMem(BLOCK_SIZE);
      
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    WriteLn('Stack Allocator: ', LElapsedMs, ' ms');
  finally
    LStackAllocator.Free;
  end;
end;

procedure BenchmarkFixedPool;
begin
  LFixedPool := TFixedSizePool.Create(BLOCK_SIZE, ITERATIONS);
  try
    LStartTime := Now;
    
    // 分配
    for I := 0 to ITERATIONS-1 do
      LPtrs[I] := LFixedPool.GetMem(BLOCK_SIZE);
      
    // 释放
    for I := 0 to ITERATIONS-1 do
      LFixedPool.FreeMem(LPtrs[I]);
      
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    WriteLn('Fixed Pool: ', LElapsedMs, ' ms');
  finally
    LFixedPool.Free;
  end;
end;

procedure BenchmarkTrackingAllocator;
begin
  LTracker := TTrackingAllocator.Create;
  try
    LStartTime := Now;
    
    // 分配
    for I := 0 to ITERATIONS-1 do
      LPtrs[I] := LTracker.GetMem(BLOCK_SIZE);
      
    // 释放
    for I := 0 to ITERATIONS-1 do
      LTracker.FreeMem(LPtrs[I]);
      
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    WriteLn('Tracking Allocator: ', LElapsedMs, ' ms');
  finally
    LTracker.Free;
  end;
end;

procedure BenchmarkAlignedAllocator;
begin
  LAligned := TAlignedAllocator.Create(16);
  try
    LStartTime := Now;
    
    // 分配
    for I := 0 to ITERATIONS-1 do
      LPtrs[I] := LAligned.GetMem(BLOCK_SIZE);
      
    // 释放
    for I := 0 to ITERATIONS-1 do
      LAligned.FreeMem(LPtrs[I]);
      
    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    WriteLn('Aligned Allocator: ', LElapsedMs, ' ms');
  finally
    LAligned.Free;
  end;
end;

begin
  WriteLn('=== Memory Allocator Performance Benchmark ===');
  WriteLn('Iterations: ', ITERATIONS);
  WriteLn('Block Size: ', BLOCK_SIZE, ' bytes');
  WriteLn;
  
  LDefaultAllocator := GetRtlAllocator;
  
  WriteLn('Running benchmarks...');
  WriteLn;
  
  BenchmarkDefaultAllocator;
  BenchmarkStackAllocator;
  BenchmarkFixedPool;
  BenchmarkTrackingAllocator;
  BenchmarkAlignedAllocator;
  
  WriteLn;
  WriteLn('=== Benchmark Complete ===');
end.
