unit fafafa.core.benchmark.clean;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{*
  Clean facade for fafafa.core.benchmark
  - Curated, stable API surface suitable for most users
  - Thin wrappers forwarding to the main implementation unit
  - No behavior change; safe to adopt incrementally
*}

interface

uses
  fafafa.core.benchmark;

type
  // Re-export key types via aliases (keeps single source of truth)
  TBenchmarkConfig = fafafa.core.benchmark.TBenchmarkConfig;
  TBenchmarkMode   = fafafa.core.benchmark.TBenchmarkMode;
  TBenchmarkUnit   = fafafa.core.benchmark.TBenchmarkUnit;

  IBenchmarkRunner   = fafafa.core.benchmark.IBenchmarkRunner;
  IBenchmarkSuite    = fafafa.core.benchmark.IBenchmarkSuite;
  IBenchmarkReporter = fafafa.core.benchmark.IBenchmarkReporter;
  IBenchmarkResult   = fafafa.core.benchmark.IBenchmarkResult;

  TQuickBenchmark       = fafafa.core.benchmark.TQuickBenchmark;
  TBenchmarkResultArray = fafafa.core.benchmark.TBenchmarkResultArray;
  TMultiThreadConfig    = fafafa.core.benchmark.TMultiThreadConfig;

// Config & factories
function CreateDefaultBenchmarkConfig: TBenchmarkConfig;
function CreateBenchmarkRunner: IBenchmarkRunner;
function CreateBenchmarkSuite: IBenchmarkSuite;

// Reporters (console-first; JSON/CSV can be added later if needed)
function CreateConsoleReporter: IBenchmarkReporter;
function CreateConsoleReporterAsciiOnly: IBenchmarkReporter;

// One-shot helpers
function Bench(const aName: string; aFunc: fafafa.core.benchmark.TBenchmarkFunction): IBenchmarkResult; overload;
function BenchWithConfig(const aName: string; aFunc: fafafa.core.benchmark.TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;

// Quick API (define + run group)
function benchmark(const aName: string; aFunc: fafafa.core.benchmark.TBenchmarkFunction): TQuickBenchmark; overload;
function benchmarks(const aTests: array of TQuickBenchmark): TBenchmarkResultArray; overload;
procedure quick_benchmark(const aTests: array of TQuickBenchmark); overload;

// Multithread helpers
function CreateMultiThreadConfig(aThreadCount: Integer; aWorkPerThread: Integer = 0; aSyncThreads: Boolean = True): TMultiThreadConfig;
function RunMultiThreadBenchmark(const aName: string; aFunc: fafafa.core.benchmark.TMultiThreadBenchmarkFunction; aThreadCount: Integer): IBenchmarkResult; overload;
function RunMultiThreadBenchmark(const aName: string; aFunc: fafafa.core.benchmark.TMultiThreadBenchmarkFunction; aThreadCount: Integer; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;

implementation

function CreateDefaultBenchmarkConfig: TBenchmarkConfig;
begin
  Result := fafafa.core.benchmark.CreateDefaultBenchmarkConfig;
end;

function CreateBenchmarkRunner: IBenchmarkRunner;
begin
  Result := fafafa.core.benchmark.CreateBenchmarkRunner;
end;

function CreateBenchmarkSuite: IBenchmarkSuite;
begin
  Result := fafafa.core.benchmark.CreateBenchmarkSuite;
end;

function CreateConsoleReporter: IBenchmarkReporter;
begin
  Result := fafafa.core.benchmark.CreateConsoleReporter;
end;

function CreateConsoleReporterAsciiOnly: IBenchmarkReporter;
begin
  Result := fafafa.core.benchmark.CreateConsoleReporterAsciiOnly;
end;

function Bench(const aName: string; aFunc: fafafa.core.benchmark.TBenchmarkFunction): IBenchmarkResult;
begin
  Result := fafafa.core.benchmark.Bench(aName, aFunc);
end;

function BenchWithConfig(const aName: string; aFunc: fafafa.core.benchmark.TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult;
begin
  Result := fafafa.core.benchmark.BenchWithConfig(aName, aFunc, aConfig);
end;

function benchmark(const aName: string; aFunc: fafafa.core.benchmark.TBenchmarkFunction): TQuickBenchmark;
begin
  Result := fafafa.core.benchmark.benchmark(aName, aFunc);
end;

function benchmarks(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;
begin
  Result := fafafa.core.benchmark.benchmarks(aTests);
end;

procedure quick_benchmark(const aTests: array of TQuickBenchmark);
begin
  fafafa.core.benchmark.quick_benchmark(aTests);
end;

function CreateMultiThreadConfig(aThreadCount: Integer; aWorkPerThread: Integer; aSyncThreads: Boolean): TMultiThreadConfig;
begin
  Result := fafafa.core.benchmark.CreateMultiThreadConfig(aThreadCount, aWorkPerThread, aSyncThreads);
end;

function RunMultiThreadBenchmark(const aName: string; aFunc: fafafa.core.benchmark.TMultiThreadBenchmarkFunction; aThreadCount: Integer): IBenchmarkResult;
begin
  Result := fafafa.core.benchmark.RunMultiThreadBenchmark(aName, aFunc, aThreadCount);
end;

function RunMultiThreadBenchmark(const aName: string; aFunc: fafafa.core.benchmark.TMultiThreadBenchmarkFunction; aThreadCount: Integer; const aConfig: TBenchmarkConfig): IBenchmarkResult;
begin
  Result := fafafa.core.benchmark.RunMultiThreadBenchmark(aName, aFunc, aThreadCount, aConfig);
end;

end.

