{$CODEPAGE UTF8}
program example_strict_os;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.os;

procedure Run;
var
  path, home, user: string;
  ok: Boolean;
begin
  Writeln('=== strict variants demo ===');

  ok := os_exe_path_ex(path);
  if ok then
    Writeln('exe: ', path)
  else
    Writeln('exe: <unavailable>');

  ok := os_home_dir_ex(home);
  if ok and (home <> '') then
    Writeln('home: ', home)
  else
    Writeln('home: <unavailable>');

  ok := os_username_ex(user);
  if ok and (user <> '') then
    Writeln('user: ', user)
  else
    Writeln('user: <unavailable>');

  // timezone 与 iana（最佳努力，不强行断言）
  Writeln('timezone: ', os_timezone);
  Writeln('timezone_iana: ', os_timezone_iana);
end;

begin
  Run;
end.

