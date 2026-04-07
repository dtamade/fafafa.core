unit test_mem_allocator;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.mem.allocator;

type

  { TTestCase_RtlAllocator }

  TTestCase_RtlAllocator = class(TTestCase)
  published
    procedure Test_GetMem;
    procedure Test_AllocMem;
    procedure Test_ReallocMem;
    procedure Test_FreeMem;
  end;

{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  { TTestCase_CrtAllocator }

  TTestCase_CrtAllocator = class(TTestCase)
  published
    procedure Test_GetMem;
    procedure Test_AllocMem;
    procedure Test_ReallocMem;
    procedure Test_FreeMem;
  end;
{$ENDIF}

  { TTestCase_CallbackAllocator }

  TTestCase_CallbackAllocator = class(TTestCase)
  published
    procedure Test_GetMem;
    procedure Test_AllocMem;
    procedure Test_ReallocMem;
    procedure Test_FreeMem;
    procedure Test_Create_NilCallbacks;
  end;

implementation

{ TTestCase_RtlAllocator }

procedure TTestCase_RtlAllocator.Test_GetMem;
var
  LAllocator: TRtlAllocator;
  LMem: Pointer;
begin
  LAllocator := TRtlAllocator.Create;
  try
    LMem := LAllocator.GetMem(100);
    AssertNotNull('GetMem should return a non-nil pointer for non-zero size', LMem);
    LAllocator.FreeMem(LMem);

    // 空操作原则测试: 零字节分配
    LMem := LAllocator.GetMem(0);
    AssertNull('GetMem should return nil for zero size', LMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_RtlAllocator.Test_AllocMem;
var
  LAllocator: TRtlAllocator;
  LMem: Pointer;
  LIndex: Integer;
begin
  LAllocator := TRtlAllocator.Create;
  try
    LMem := LAllocator.AllocMem(100);
    AssertNotNull('AllocMem should return a non-nil pointer for non-zero size', LMem);

    for LIndex := 0 to 99 do
      AssertEquals('AllocMem should zero-initialize memory', 0, PByte(LMem)[LIndex]);

    LAllocator.FreeMem(LMem);

    // 空操作原则测试: 零字节分配
    LMem := LAllocator.AllocMem(0);
    AssertNull('AllocMem should return nil for zero size', LMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_RtlAllocator.Test_ReallocMem;
var
  LAllocator: TRtlAllocator;
  LMem: Pointer;
  LNewMem: Pointer;
  LIndex: Integer;
begin
  LAllocator := TRtlAllocator.Create;
  try
    // nil 指针 realloc
    LNewMem := LAllocator.ReallocMem(nil, 100);
    AssertNotNull('ReallocMem(nil, size) should return non-nil', LNewMem);
    LAllocator.FreeMem(LNewMem);

    // realloc 到 0
    LMem := LAllocator.GetMem(10);
    AssertNotNull('Pre-allocated memory should not be nil', LMem);
    AssertNull('ReallocMem to zero size should return nil', LAllocator.ReallocMem(LMem, 0));

    // 其它常规测试...
    LMem := LAllocator.GetMem(50);
    for LIndex := 0 to 49 do
      PByte(LMem)[LIndex] := LIndex;

    LNewMem := LAllocator.ReallocMem(LMem, 100);
    AssertNotNull('ReallocMem to larger size should return non-nil', LNewMem);

    for LIndex := 0 to 49 do
      AssertEquals('ReallocMem should preserve existing data', LIndex, PByte(LNewMem)[LIndex]);

    LAllocator.FreeMem(LNewMem);
    LMem := LAllocator.GetMem(100);

    for LIndex := 0 to 99 do
      PByte(LMem)[LIndex] := LIndex;

    LNewMem := LAllocator.ReallocMem(LMem, 50);
    AssertNotNull('ReallocMem to smaller size should return non-nil', LNewMem);

    for LIndex := 0 to 49 do
      AssertEquals('ReallocMem should preserve existing data', LIndex, PByte(LNewMem)[LIndex]);

    LAllocator.FreeMem(LNewMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_RtlAllocator.Test_FreeMem;
var
  LAllocator: TRtlAllocator;
  LMem: Pointer;
begin
  LAllocator := TRtlAllocator.Create;
  try
    LMem := LAllocator.GetMem(10);
    AssertNotNull('GetMem should return a non-nil pointer', LMem);
    LAllocator.FreeMem(LMem);

    {$IFDEF FAFAFA_CORE_STRICT_NULL_FREE}
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 严格模式下：nil 指针释放应抛异常
    AssertException('FreeMem with nil pointer should raise an exception', EArgumentNil, procedure
    begin
      LAllocator.FreeMem(nil);
    end);
    {$ENDIF}
    {$ENDIF}
  finally
    LAllocator.Free;
  end;
end;

{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}

{ TTestCase_CrtAllocator }

procedure TTestCase_CrtAllocator.Test_GetMem;
var
  LAllocator: TCrtAllocator;
  LMem: Pointer;
begin
  LAllocator := TCrtAllocator.Create;
  try
    LMem := LAllocator.GetMem(100);
    AssertNotNull('GetMem should return a non-nil pointer for non-zero size', LMem);
    LAllocator.FreeMem(LMem);

    // 空操作原则测试: 零字节分配
    LMem := LAllocator.GetMem(0);
    AssertNull('GetMem should return nil for zero size', LMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CrtAllocator.Test_AllocMem;
var
  LAllocator: TCrtAllocator;
  LMem: Pointer;
  LIndex: Integer;
begin
  LAllocator := TCrtAllocator.Create;
  try
    LMem := LAllocator.AllocMem(100);
    AssertNotNull('AllocMem should return a non-nil pointer for non-zero size', LMem);

    for LIndex := 0 to 99 do
      AssertEquals('AllocMem should zero-initialize memory', 0, PByte(LMem)[LIndex]);

    LAllocator.FreeMem(LMem);

    // 空操作原则测试: 零字节分配
    LMem := LAllocator.AllocMem(0);
    AssertNull('AllocMem should return nil for zero size', LMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CrtAllocator.Test_ReallocMem;
var
  LAllocator: TCrtAllocator;
  LMem: Pointer;
  LNewMem: Pointer;
  LIndex: Integer;
begin
  LAllocator := TCrtAllocator.Create;
  try
    // nil 指针 realloc(等价于GetMem)
    LNewMem := LAllocator.ReallocMem(nil, 100);
    AssertNotNull('ReallocMem(nil, size) should return non-nil', LNewMem);
    LAllocator.FreeMem(LNewMem);

    // realloc 到 0(等价于FreeMem)
    LMem := LAllocator.GetMem(10);
    AssertNotNull('Pre-allocated memory should not be nil', LMem);
    AssertNull('ReallocMem to zero size should return nil', LAllocator.ReallocMem(LMem, 0));

    // 其它常规测试...
    LMem := LAllocator.GetMem(50);
    for LIndex := 0 to 49 do
      PByte(LMem)[LIndex] := LIndex;

    LNewMem := LAllocator.ReallocMem(LMem, 100);
    AssertNotNull('ReallocMem to larger size should return non-nil', LNewMem);

    for LIndex := 0 to 49 do
      AssertEquals('ReallocMem should preserve existing data', LIndex, PByte(LNewMem)[LIndex]);

    LAllocator.FreeMem(LNewMem);

    LMem := LAllocator.GetMem(100);
    for LIndex := 0 to 99 do
      PByte(LMem)[LIndex] := LIndex;

    LNewMem := LAllocator.ReallocMem(LMem, 50);
    AssertNotNull('ReallocMem to smaller size should return non-nil', LNewMem);

    for LIndex := 0 to 49 do
      AssertEquals('ReallocMem should preserve existing data', LIndex, PByte(LNewMem)[LIndex]);

    LAllocator.FreeMem(LNewMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CrtAllocator.Test_FreeMem;
var
  LAllocator: TCrtAllocator;
  LMem: Pointer;
begin
  LAllocator := TCrtAllocator.Create;
  try
    LMem := LAllocator.GetMem(10);
    AssertNotNull('GetMem should return a non-nil pointer', LMem);
    LAllocator.FreeMem(LMem);

    {$IFDEF FAFAFA_CORE_STRICT_NULL_FREE}
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 严格模式下：nil 指针释放应抛异常
    AssertException('FreeMem with nil pointer should raise an exception',
      EArgumentNil,
      procedure
      begin
        LAllocator.FreeMem(nil);
      end);
    {$ENDIF}
    {$ENDIF}
  finally
    LAllocator.Free;
  end;
end;

{$ENDIF}

{ TTestCase_CallbackAllocator }

function DummyGetMem(aSize: SizeUInt): Pointer;
begin
  Result := System.GetMem(aSize);
end;

function DummyAllocMem(aSize: SizeUInt): Pointer;
begin
  Result := System.AllocMem(aSize);
end;

function DummyReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
begin
  Result := System.ReallocMem(aDst, aSize);
end;

procedure DummyFreeMem(aDst: Pointer);
begin
  System.FreeMem(aDst);
end;

procedure TTestCase_CallbackAllocator.Test_GetMem;
var
  LAllocator: TCallbackAllocator;
  LMem: Pointer;
begin
  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem := LAllocator.GetMem(100);
    AssertNotNull('GetMem should return a non-nil pointer for non-zero size', LMem);
    LAllocator.FreeMem(LMem);
  finally
    LAllocator.Free;
  end;

  // 空操作原则测试: 零字节分配
  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem := LAllocator.GetMem(0);
    AssertNull('GetMem should return nil for zero size', LMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_AllocMem;
var
  LAllocator: TCallbackAllocator;
  LMem: Pointer;
  LIndex: Integer;
begin
  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem := LAllocator.AllocMem(100);
    AssertNotNull('AllocMem should return a non-nil pointer for non-zero size', LMem);

    for LIndex := 0 to 99 do
      AssertEquals('AllocMem should zero-initialize memory', 0, PByte(LMem)[LIndex]);
    LAllocator.FreeMem(LMem);

    // 空操作原则测试: 零字节分配
    LMem := LAllocator.AllocMem(0);
    AssertNull('AllocMem should return nil for zero size', LMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_ReallocMem;
var
  LAllocator: TCallbackAllocator;
  LMem: Pointer;
  LNewMem: Pointer;
  LIndex: Integer;
begin
  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    // nil 指针 realloc(等价于GetMem)
    LNewMem := LAllocator.ReallocMem(nil, 100);
    AssertNotNull('ReallocMem(nil, size) should return non-nil', LNewMem);
    LAllocator.FreeMem(LNewMem);

    // realloc 到 0(等价于FreeMem)
    LMem := LAllocator.GetMem(10);
    AssertNotNull('Pre-allocated memory should not be nil', LMem);
    AssertNull('ReallocMem to zero size should return nil', LAllocator.ReallocMem(LMem, 0));

    // 其它常规测试...
    LMem := LAllocator.GetMem(50);
    for LIndex := 0 to 49 do
      PByte(LMem)[LIndex] := LIndex;
    LNewMem := LAllocator.ReallocMem(LMem, 100);
    AssertNotNull('ReallocMem to larger size should return non-nil', LNewMem);
    for LIndex := 0 to 49 do
      AssertEquals('ReallocMem should preserve existing data', LIndex, PByte(LNewMem)[LIndex]);
    LAllocator.FreeMem(LNewMem);

    LMem := LAllocator.GetMem(100);
    for LIndex := 0 to 99 do
      PByte(LMem)[LIndex] := LIndex;
    LNewMem := LAllocator.ReallocMem(LMem, 50);
    AssertNotNull('ReallocMem to smaller size should return non-nil', LNewMem);
    for LIndex := 0 to 49 do
      AssertEquals('ReallocMem should preserve existing data', LIndex, PByte(LNewMem)[LIndex]);
    LAllocator.FreeMem(LNewMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_FreeMem;
var
  LAllocator: TCallbackAllocator;
  LTemp: TCallbackAllocator;
  LMem: Pointer;
begin
  // 正常释放路径验证
  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem := LAllocator.GetMem(10);
    AssertNotNull('GetMem should return a non-nil pointer', LMem);
    LAllocator.FreeMem(LMem);
  finally
    LAllocator.Free;
  end;

  // 异常路径单独验证，使用独立实例，避免与上面的 finally 干扰
  LTemp := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    {$IFDEF FAFAFA_CORE_STRICT_NULL_FREE}
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    AssertException('FreeMem with nil pointer should raise an exception',
      EArgumentNil,
      procedure
      begin
        LTemp.FreeMem(nil);
      end);
    {$ENDIF}
    {$ENDIF}
  finally
    LTemp.Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_Create_NilCallbacks;
var
  LAllocator: TCallbackAllocator;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {$IFDEF FAFAFA_CORE_CONTRACTS}
  AssertException(
    'Creating TCallbackAllocator with nil GetMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      CreateCallbackAllocator(nil, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
    end);

  AssertException(
    'Creating TCallbackAllocator with nil AllocMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      CreateCallbackAllocator(@DummyGetMem, nil, @DummyReallocMem, @DummyFreeMem);
    end);

  AssertException(
    'Creating TCallbackAllocator with nil ReallocMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, nil, @DummyFreeMem);
    end);

  AssertException(
    'Creating TCallbackAllocator with nil FreeMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, nil);
    end);
  {$ELSE}
  LAllocator := CreateCallbackAllocator(nil, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    AssertNotNull('Callback allocator should stay constructible without contracts for nil GetMem', LAllocator);
  finally
    LAllocator.Free;
  end;

  LAllocator := CreateCallbackAllocator(@DummyGetMem, nil, @DummyReallocMem, @DummyFreeMem);
  try
    AssertNotNull('Callback allocator should stay constructible without contracts for nil AllocMem', LAllocator);
  finally
    LAllocator.Free;
  end;

  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, nil, @DummyFreeMem);
  try
    AssertNotNull('Callback allocator should stay constructible without contracts for nil ReallocMem', LAllocator);
  finally
    LAllocator.Free;
  end;

  LAllocator := CreateCallbackAllocator(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, nil);
  try
    AssertNotNull('Callback allocator should stay constructible without contracts for nil FreeMem', LAllocator);
  finally
    LAllocator.Free;
  end;
  {$ENDIF}
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_RtlAllocator);
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  RegisterTest(TTestCase_CrtAllocator);
  {$ENDIF}
  RegisterTest(TTestCase_CallbackAllocator);
end.
