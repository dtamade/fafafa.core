program args_command_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.args,
  fafafa.core.args.command;

const
  ITERATIONS = 5000;
  DEEP_NESTING_LEVELS = 10;

function DummyHandler(const A: IArgs): Integer;
begin
  Result := 0;
end;

function CreateSimpleCommandTree: IRootCommand;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  Root.Register(NewCommandPath(['run'], @DummyHandler, 'Run command'));
  Root.Register(NewCommandPath(['build'], @DummyHandler, 'Build command'));
  Root.Register(NewCommandPath(['test'], @DummyHandler, 'Test command'));
  Root.Register(NewCommandPath(['deploy'], @DummyHandler, 'Deploy command'));
  Root.Register(NewCommandPath(['status'], @DummyHandler, 'Status command'));
  Result := Root;
end;

function CreateComplexCommandTree: IRootCommand;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  
  // Git-like command structure
  Root.Register(NewCommandPath(['git', 'add'], @DummyHandler, 'Add files'));
  Root.Register(NewCommandPath(['git', 'commit'], @DummyHandler, 'Commit changes'));
  Root.Register(NewCommandPath(['git', 'push'], @DummyHandler, 'Push changes'));
  Root.Register(NewCommandPath(['git', 'pull'], @DummyHandler, 'Pull changes'));
  Root.Register(NewCommandPath(['git', 'branch'], @DummyHandler, 'Branch operations'));
  Root.Register(NewCommandPath(['git', 'checkout'], @DummyHandler, 'Checkout'));
  Root.Register(NewCommandPath(['git', 'merge'], @DummyHandler, 'Merge branches'));
  Root.Register(NewCommandPath(['git', 'log'], @DummyHandler, 'Show log'));
  Root.Register(NewCommandPath(['git', 'status'], @DummyHandler, 'Show status'));
  Root.Register(NewCommandPath(['git', 'diff'], @DummyHandler, 'Show diff'));
  
  // Docker-like command structure
  Root.Register(NewCommandPath(['docker', 'run'], @DummyHandler, 'Run container'));
  Root.Register(NewCommandPath(['docker', 'build'], @DummyHandler, 'Build image'));
  Root.Register(NewCommandPath(['docker', 'ps'], @DummyHandler, 'List containers'));
  Root.Register(NewCommandPath(['docker', 'images'], @DummyHandler, 'List images'));
  Root.Register(NewCommandPath(['docker', 'stop'], @DummyHandler, 'Stop container'));
  Root.Register(NewCommandPath(['docker', 'rm'], @DummyHandler, 'Remove container'));
  Root.Register(NewCommandPath(['docker', 'rmi'], @DummyHandler, 'Remove image'));
  
  // Kubectl-like deep nesting
  Root.Register(NewCommandPath(['kubectl', 'get', 'pods'], @DummyHandler, 'Get pods'));
  Root.Register(NewCommandPath(['kubectl', 'get', 'services'], @DummyHandler, 'Get services'));
  Root.Register(NewCommandPath(['kubectl', 'get', 'deployments'], @DummyHandler, 'Get deployments'));
  Root.Register(NewCommandPath(['kubectl', 'describe', 'pod'], @DummyHandler, 'Describe pod'));
  Root.Register(NewCommandPath(['kubectl', 'describe', 'service'], @DummyHandler, 'Describe service'));
  Root.Register(NewCommandPath(['kubectl', 'apply', '-f'], @DummyHandler, 'Apply config'));
  Root.Register(NewCommandPath(['kubectl', 'delete', 'pod'], @DummyHandler, 'Delete pod'));
  
  Result := Root;
end;

function CreateDeepNestedTree: IRootCommand;
var
  Root: IRootCommand;
  i: Integer;
  path: TStringArray;
begin
  Root := NewRootCommand;
  
  // 创建深层嵌套的命令树
  for i := 1 to DEEP_NESTING_LEVELS do
  begin
    SetLength(path, i);
    path[i-1] := Format('level%d', [i]);
    if i > 1 then
      path[i-2] := Format('level%d', [i-1]);
    Root.Register(NewCommandPath(path, @DummyHandler, Format('Level %d command', [i])));
  end;
  
  Result := Root;
end;

procedure BenchmarkSimpleRouting;
var
  i: Integer;
  Root: IRootCommand;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  code: Integer;
begin
  WriteLn('=== Simple Command Routing ===');
  
  Root := CreateSimpleCommandTree;
  opts := ArgsOptionsDefault;
  
  startTime := Now;
  for i := 1 to ITERATIONS do
    code := Root.Run(['run', '--verbose'], opts);
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('Simple routing: %.0f routes/sec', [ITERATIONS / elapsed * 1000]));
end;

procedure BenchmarkComplexRouting;
var
  i: Integer;
  Root: IRootCommand;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  code: Integer;
  testCases: array[0..4] of TStringArray;
begin
  WriteLn('=== Complex Command Routing ===');
  
  Root := CreateComplexCommandTree;
  opts := ArgsOptionsDefault;
  
  // 准备测试用例
  SetLength(testCases[0], 3); testCases[0][0] := 'git'; testCases[0][1] := 'commit'; testCases[0][2] := '-m';
  SetLength(testCases[1], 2); testCases[1][0] := 'docker'; testCases[1][1] := 'ps';
  SetLength(testCases[2], 3); testCases[2][0] := 'kubectl'; testCases[2][1] := 'get'; testCases[2][2] := 'pods';
  SetLength(testCases[3], 2); testCases[3][0] := 'git'; testCases[3][1] := 'status';
  SetLength(testCases[4], 3); testCases[4][0] := 'kubectl'; testCases[4][1] := 'describe'; testCases[4][2] := 'pod';
  
  startTime := Now;
  for i := 1 to ITERATIONS do
    code := Root.Run(testCases[i mod 5], opts);
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('Complex routing: %.0f routes/sec', [ITERATIONS / elapsed * 1000]));
end;

procedure BenchmarkDeepNesting;
var
  i: Integer;
  Root: IRootCommand;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  code: Integer;
  deepPath: TStringArray;
begin
  WriteLn('=== Deep Nesting Performance ===');
  
  Root := CreateDeepNestedTree;
  opts := ArgsOptionsDefault;
  
  // 创建深层路径
  SetLength(deepPath, DEEP_NESTING_LEVELS);
  for i := 0 to DEEP_NESTING_LEVELS-1 do
    deepPath[i] := Format('level%d', [i+1]);
  
  startTime := Now;
  for i := 1 to ITERATIONS do
    code := Root.Run(deepPath, opts);
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('Deep nesting (%d levels): %.0f routes/sec', 
    [DEEP_NESTING_LEVELS, ITERATIONS / elapsed * 1000]));
end;

procedure BenchmarkCommandAliases;
var
  i: Integer;
  Root: IRootCommand;
  Cmd: ICommand;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  code: Integer;
begin
  WriteLn('=== Command Aliases Performance ===');
  
  Root := NewRootCommand;
  Cmd := NewCommand('run');
  Cmd.SetHandlerFunc(@DummyHandler);
  Cmd.AddAlias('r');
  Cmd.AddAlias('execute');
  Cmd.AddAlias('start');
  Root.Register(Cmd);
  
  opts := ArgsOptionsDefault;
  
  startTime := Now;
  for i := 1 to ITERATIONS do
  begin
    case i mod 4 of
      0: code := Root.Run(['run'], opts);
      1: code := Root.Run(['r'], opts);
      2: code := Root.Run(['execute'], opts);
      3: code := Root.Run(['start'], opts);
    end;
  end;
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('Alias routing: %.0f routes/sec', [ITERATIONS / elapsed * 1000]));
end;

procedure BenchmarkCommandNotFound;
var
  i: Integer;
  Root: IRootCommand;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  code: Integer;
begin
  WriteLn('=== Command Not Found Performance ===');
  
  Root := CreateSimpleCommandTree;
  opts := ArgsOptionsDefault;
  
  startTime := Now;
  for i := 1 to ITERATIONS do
    code := Root.Run(['nonexistent', 'command'], opts);
  endTime := Now;
  
  elapsed := MilliSecondsBetween(endTime, startTime);
  WriteLn(Format('Not found handling: %.0f lookups/sec', [ITERATIONS / elapsed * 1000]));
end;

begin
  WriteLn('fafafa.core.args Command Performance Benchmark');
  WriteLn('==============================================');
  WriteLn('Iterations per test: ', ITERATIONS);
  WriteLn('Deep nesting levels: ', DEEP_NESTING_LEVELS);
  WriteLn;
  
  BenchmarkSimpleRouting;
  WriteLn;
  
  BenchmarkComplexRouting;
  WriteLn;
  
  BenchmarkDeepNesting;
  WriteLn;
  
  BenchmarkCommandAliases;
  WriteLn;
  
  BenchmarkCommandNotFound;
  WriteLn;
  
  WriteLn('Command benchmark completed successfully.');
end.
