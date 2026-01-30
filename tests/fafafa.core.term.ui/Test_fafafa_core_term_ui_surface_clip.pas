unit Test_fafafa_core_term_ui_surface_clip;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.term,
  fafafa.core.term.ui.surface,
  ui_backend, ui_backend_memory;

procedure RegisterSurfaceClipTests;

implementation

type
  TTestCase_SurfaceClip = class(TTestCase)
  published
    procedure Test_WriteAt_Clip_Right_Beyond;
    procedure Test_WriteAt_Clip_Viewport_Narrow;
    procedure Test_FillRect_Clip_Bottom_Beyond;
    procedure Test_FillRect_Clip_TopLeft_ByViewport;
  end;

procedure TTestCase_SurfaceClip.Test_WriteAt_Clip_Right_Beyond;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
begin
  b := CreateMemoryBackend(5, 2);
  UiBackendSetCurrent(b);

  fafafa.core.term.ui.surface.UiFrameBegin;
  try
    fafafa.core.term.ui.surface.UiClear;
    // 写入超出右边界，应被裁剪为 'ABCDE' 的可见部分 'CDE'
    fafafa.core.term.ui.surface.UiWriteAt(0, 2, 'ABCDE');
  finally
    fafafa.core.term.ui.surface.UiFrameEnd;
  end;

  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(UnicodeString('  ABC'), buf[0]);
  AssertEquals(UnicodeString('     '), buf[1]);
end;

procedure TTestCase_SurfaceClip.Test_WriteAt_Clip_Viewport_Narrow;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
begin
  // 在视口内测试右侧裁剪：视口宽度 3，写入4字符
  b := CreateMemoryBackend(6, 2);
  UiBackendSetCurrent(b);

  fafafa.core.term.ui.surface.UiFrameBegin;
  try
    fafafa.core.term.ui.surface.UiClear;
    fafafa.core.term.ui.surface.UiPushView(1, 0, 3, 1, 0, 0); // 视口 (1,0), 宽3
    fafafa.core.term.ui.surface.UiWriteAt(0, 0, 'WXYZ');
    fafafa.core.term.ui.surface.UiPopView;
  finally
    fafafa.core.term.ui.surface.UiFrameEnd;
  end;

  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(UnicodeString(' WXY  '), buf[0]);
  AssertEquals(UnicodeString('      '), buf[1]);
end;

procedure TTestCase_SurfaceClip.Test_FillRect_Clip_Bottom_Beyond;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
begin
  b := CreateMemoryBackend(4, 3);
  UiBackendSetCurrent(b);

  fafafa.core.term.ui.surface.UiFrameBegin;
  try
    fafafa.core.term.ui.surface.UiClear;
    // 从 (1,1) 开始填充 3x3 超出下边界，实际覆盖行1..2，列1..3
    fafafa.core.term.ui.surface.UiFillRect(1, 1, 3, 3, '#');
  finally
    fafafa.core.term.ui.surface.UiFrameEnd;
  end;

  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(UnicodeString('    '), buf[0]);
  AssertEquals(UnicodeString(' ###'), buf[1]);
  AssertEquals(UnicodeString(' ###'), buf[2]);
end;

procedure TTestCase_SurfaceClip.Test_FillRect_Clip_TopLeft_ByViewport;
var
  b: IUiBackend;
  buf: TUnicodeStringArray;
begin
  // 通过设置视口来测试左上裁剪
  b := CreateMemoryBackend(4, 3);
  UiBackendSetCurrent(b);

  fafafa.core.term.ui.surface.UiFrameBegin;
  try
    fafafa.core.term.ui.surface.UiClear;
    fafafa.core.term.ui.surface.UiPushView(1, 1, 2, 2, 0, 0); // 视口 (1,1) 尺寸2x2
    // 在视口内从(0,0)开始填充3x3，超出部分被裁剪，实际可见为视口整个区域
    fafafa.core.term.ui.surface.UiFillRect(0, 0, 3, 3, '@');
    fafafa.core.term.ui.surface.UiPopView;
  finally
    fafafa.core.term.ui.surface.UiFrameEnd;
  end;

  buf := MemoryBackend_GetBuffer(b);
  AssertEquals(UnicodeString('    '), buf[0]);
  AssertEquals(UnicodeString(' @@ '), buf[1]);
  AssertEquals(UnicodeString(' @@ '), buf[2]);
end;

procedure RegisterSurfaceClipTests;
begin
  RegisterTest(TTestCase_SurfaceClip);
end;

initialization
  RegisterSurfaceClipTests;

end.

