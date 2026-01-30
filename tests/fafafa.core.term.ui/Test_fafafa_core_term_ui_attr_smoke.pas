unit Test_fafafa_core_term_ui_attr_smoke;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.term,
  fafafa.core.term.ui.surface,
  ui_backend, ui_backend_memory;

type
  TTestCase_AttrSmoke = class(TTestCase)
  published
    procedure Test_SetAttr_Write_Smoke;
  end;

implementation

procedure TTestCase_AttrSmoke.Test_SetAttr_Write_Smoke;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
  Attr: TUiAttr;
begin
  // Arrange
  b := CreateMemoryBackend(6, 2);
  UiBackendSetCurrent(b);

  // Compose attr: fg red, bg blue (values不重要，我们不校验颜色，只要不出错)
  FillChar(Attr, SizeOf(Attr), 0);
  Attr.HasFg := True; Attr.Fg.R := 255; Attr.Fg.G := 0; Attr.Fg.B := 0;
  Attr.HasBg := True; Attr.Bg.R := 0; Attr.Bg.G := 0; Attr.Bg.B := 255;

  // Act
  fafafa.core.term.ui.surface.UiFrameBegin;
  try
    fafafa.core.term.ui.surface.UiSetAttr(Attr);
    fafafa.core.term.ui.surface.UiWriteAt(0, 0, 'XY');
  finally
    fafafa.core.term.ui.surface.UiFrameEnd;
  end;

  // Assert
  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(2, Length(buf));
  AssertEquals(UnicodeString('XY    '), buf[0]);
  AssertEquals(UnicodeString('      '), buf[1]);
end;

initialization
  RegisterTest(TTestCase_AttrSmoke);

end.

