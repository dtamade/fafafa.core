{$CODEPAGE UTF8}
unit Test_fafafa_core_term_ui_attr_min_write;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ui_backend, ui_backend_memory, ui_surface, ui_style;

type
  TTestCase_AttrMinWrite = class(TTestCase)
  published
    procedure Test_SameFrame_NoWrites;
    procedure Test_OnlyStyleChange_MinimalWrites;
  end;

implementation

var
  GWriteCount_MinWrite: SizeInt = 0;

procedure Hook_Write_MinWrite(const S: UnicodeString);
begin
  Inc(GWriteCount_MinWrite);
end;

procedure TTestCase_AttrMinWrite.Test_SameFrame_NoWrites;
var
  B: IUiBackend;
  before, after: SizeInt;
begin
  // Arrange
  B := CreateMemoryBackend(20, 3);
  UiBackendSetCurrent(B);
  UiDebug_SetOutputHooks(@Hook_Write_MinWrite, nil, nil, nil, nil, nil);

  // First frame: draw a line
  UiFrameBegin;
  UiWriteAt(1, 2, 'hello');
  UiFrameEnd;

  // Reset counter and draw the same content again without changing style
  before := GWriteCount_MinWrite;
  UiFrameBegin;
  UiWriteAt(1, 2, 'hello');
  UiFrameEnd;
  after := GWriteCount_MinWrite;

  // Assert: second identical frame should produce zero writes (backbuffer diff)
  CheckEquals(before, after, 'No writes expected for identical second frame');
  UiDebug_ResetOutputHooks;
end;

procedure TTestCase_AttrMinWrite.Test_OnlyStyleChange_MinimalWrites;
var
  B: IUiBackend;
  before, after: SizeInt;
begin
  // Arrange
  B := CreateMemoryBackend(20, 3);
  UiBackendSetCurrent(B);
  UiDebug_SetOutputHooks(@Hook_Write_MinWrite, nil, nil, nil, nil, nil);

  // Frame 1: plain text
  UiFrameBegin;
  UiAttrReset;
  UiWriteAt(1, 2, 'hello');
  UiFrameEnd;

  // Frame 2: same text, change FG color only, expect minimal text writes
  before := GWriteCount_MinWrite;
  UiFrameBegin;
  UiSetFg24(200,100,50);
  UiWriteAt(1, 2, 'hello');
  UiFrameEnd;
  after := GWriteCount_MinWrite;

  // Assert: allow small number of writes (1 segment) due to attr-aware segment emission
  CheckTrue((after - before) <= 1, 'Only one segment write expected when only style changes');
  UiDebug_ResetOutputHooks;
end;

initialization
  RegisterTest(TTestCase_AttrMinWrite);
end.

