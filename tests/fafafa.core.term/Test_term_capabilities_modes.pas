{$CODEPAGE UTF8}
unit Test_term_capabilities_modes;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_TermCapabilitiesModes = class(TTestCase)
  private
    FTerm: pterm_t;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Modes_Supported_When_ANSI;
  end;

implementation

procedure TTestCase_TermCapabilitiesModes.SetUp;
begin
  New(FTerm);
  FillByte(FTerm^, SizeOf(term_t), 0);
  // 模拟启用 ANSI
  FTerm^.compatibles := [tc_ansi];
end;

procedure TTestCase_TermCapabilitiesModes.TearDown;
begin
  if Assigned(FTerm) then
  begin
    Dispose(FTerm);
    FTerm := nil;
  end;
end;

procedure TTestCase_TermCapabilitiesModes.Test_Modes_Supported_When_ANSI;
begin
  CheckTrue(term_support_focus_1004(FTerm), 'focus mode should be supported when ANSI is supported');
  CheckTrue(term_support_paste_2004(FTerm), 'paste mode should be supported when ANSI is supported');
  CheckTrue(term_support_sync_update(FTerm), 'sync update should be supported when ANSI is supported');
end;

initialization
  RegisterTest(TTestCase_TermCapabilitiesModes);
end.

