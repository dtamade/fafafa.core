{$CODEPAGE UTF8}
program example_snapshots;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.snapshot;

procedure DemoText;
var dir, name: string; ok: boolean;
begin
  dir := GetTempDir(False) + 'snap_demo_text';
  ForceDirectories(dir);
  name := 'greeting';
  // 建立基线
  ok := CompareTextSnapshot(dir, name, 'Hello, World!', True);
  Writeln('Text baseline created: ', ok);
  // 不更新比较（相同）
  ok := CompareTextSnapshot(dir, name, 'Hello, World!', False);
  Writeln('Text equals: ', ok);
  // 不更新比较（不同） -> 生成 .snap.diff.txt（统一 diff）
  ok := CompareTextSnapshot(dir, name, 'Hello, 世界!', False);
  Writeln('Text changed, expect False: ', ok, ' (see *.snap.diff.txt)');
end;

procedure DemoToml;
var dir, name: string; ok: boolean;
begin
  dir := GetTempDir(False) + 'snap_demo_toml';
  ForceDirectories(dir);
  name := 'cfg';
  ok := CompareTomlSnapshot(dir, name, 'a=1', True);
  Writeln('TOML baseline created: ', ok);
  ok := CompareTomlSnapshot(dir, name, 'a=1', False);
  Writeln('TOML equals: ', ok);
  ok := CompareTomlSnapshot(dir, name, 'a=2', False);
  Writeln('TOML changed, expect False: ', ok);
end;

procedure DemoJson;
var dir, name: string; ok: boolean;
begin
  dir := GetTempDir(False) + 'snap_demo_json';
  ForceDirectories(dir);
  name := 'resp';
  ok := CompareJsonSnapshot(dir, name, '{"b":2,"a":1}', True);
  Writeln('JSON baseline created: ', ok);
  ok := CompareJsonSnapshot(dir, name, '{"a":1,"b":2}', False);
  Writeln('JSON equals (order-insensitive): ', ok);
  ok := CompareJsonSnapshot(dir, name, '{"a":1,"b":3}', False);
  Writeln('JSON changed, expect False: ', ok);
end;

begin
  DemoText;
  DemoToml;
  DemoJson;
end.

