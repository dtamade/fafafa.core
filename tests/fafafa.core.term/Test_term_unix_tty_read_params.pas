{$CODEPAGE UTF8}
unit Test_term_unix_tty_read_params;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_UnixTTYReadParams = class(TTestCase)
  published
    procedure Test_Set_Get_TTY_Read_Params_Roundtrip;
    procedure Test_Set_Read_Timeout_MS_Clamp;
  end;

implementation

{$IFDEF UNIX}

procedure TTestCase_UnixTTYReadParams.Test_Set_Get_TTY_Read_Params_Roundtrip;
var
  vmin, vtime: Byte;
begin
  term_init;
  try
    // 保存当前
    CheckTrue(term_unix_get_tty_read_params(vmin, vtime));
    // 设置新值
    CheckTrue(term_unix_set_tty_read_params(1, 5));
    CheckTrue(term_unix_get_tty_read_params(vmin, vtime));
    AssertEquals(Byte(1), vmin);
    AssertEquals(Byte(5), vtime);
  finally
    term_done;
  end;
end;

procedure TTestCase_UnixTTYReadParams.Test_Set_Read_Timeout_MS_Clamp;
var
  oldms: Integer;
  vmin, vtime: Byte;
begin
  term_init;
  try
    oldms := term_unix_set_read_timeout_ms(12345); // 12.345s -> clamp to 2550ms units? Actually 255*100ms = 25500ms, so ok
    CheckTrue(term_unix_get_tty_read_params(vmin, vtime));
    AssertEquals(Byte(0), vmin);
    AssertTrue(vtime >= 123);
  finally
    term_done;
  end;
end;

{$ENDIF}

initialization
  RegisterTest(TTestCase_UnixTTYReadParams);

end.

