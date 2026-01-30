{$CODEPAGE UTF8}
program example_quickstart;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.env;

procedure Println(const S: string);
begin
  WriteLn(S);
end;

var
  home, tmp, cfg, cache, s: string;
  paths: array of string;
  i, n: integer;
begin
  WriteLn('=== fafafa.core.env quickstart ===');

  // User dirs
  home := env_home_dir; tmp := env_temp_dir; cfg := env_user_config_dir; cache := env_user_cache_dir;
  Println('home  = ' + home);
  Println('temp  = ' + tmp);
  Println('config= ' + cfg);
  Println('cache = ' + cache);

  // Expand
  s := env_expand('HOME=$HOME');
  Println('expand: ' + s);
  {$IFDEF WINDOWS}
  s := env_expand('USERPROFILE=%USERPROFILE%');
  Println('expand(win): ' + s);
  {$ENDIF}

  // PATH entries (first few)
  paths := env_split_paths(env_get('PATH'));
  n := Length(paths); if n > 5 then n := 5;
  for i := 0 to n-1 do
    Println('PATH['+IntToStr(i)+']='+paths[i]);

  // Current dir
  Println('cwd   = ' + env_current_dir);
  Println('exe   = ' + env_executable_path);
end.

