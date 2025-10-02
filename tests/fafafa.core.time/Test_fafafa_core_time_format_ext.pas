unit Test_fafafa_core_time_format_ext;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_TimeFormatExt = class(TTestCase)
  published
    procedure Test_FormatDurationHuman_Defaults;
    procedure Test_FormatDurationHuman_Abbr_Toggle;
    procedure Test_FormatDurationHuman_SecPrecision;
  end;

implementation

procedure TTestCase_TimeFormatExt.Test_FormatDurationHuman_Defaults;
var s: string;
begin
  // 默认：abbr=true, sec precision=0
  s := FormatDurationHuman(TDuration.FromNs(999));
  CheckEquals('999ns', s);
  s := FormatDurationHuman(TDuration.FromUs(42));
  CheckEquals('42us', s);
  s := FormatDurationHuman(TDuration.FromMs(7));
  CheckEquals('7ms', s);
  s := FormatDurationHuman(TDuration.FromSec(2));
  CheckEquals('2s', s);
end;

procedure TTestCase_TimeFormatExt.Test_FormatDurationHuman_Abbr_Toggle;
var s: string;
begin
  SetDurationFormatUseAbbr(False);
  try
    s := FormatDurationHuman(TDuration.FromMs(3));
    CheckEquals('3 milliseconds', s);
    s := FormatDurationHuman(TDuration.FromSec(1));
    CheckEquals('1 seconds', s);
  finally
    SetDurationFormatUseAbbr(True);
  end;
end;

procedure TTestCase_TimeFormatExt.Test_FormatDurationHuman_SecPrecision;
var s: string;
begin
  SetDurationFormatSecPrecision(3);
  try
    s := FormatDurationHuman(TDuration.FromNs(1500000000)); // 1.5s
    // 容许本地化差异最小化，这里直接比对固定格式
    CheckEquals('1.500s', s);
  finally
    SetDurationFormatSecPrecision(0);
  end;
end;

initialization
  RegisterTest(TTestCase_TimeFormatExt);
end.

