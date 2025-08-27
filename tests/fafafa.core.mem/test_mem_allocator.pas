unit test_mem_allocator;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
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
  LAllocator: IAllocator;
  LMem      : Pointer;
begin
  LAllocator := TRtlAllocator.Create;
  LMem       := LAllocator.GetMem(100);
  AssertNotNull('GetMem should return a non-nil pointer for non-zero size', LMem);
  LAllocator.FreeMem(LMem);

  // 空操作原则测试: 零字节分配
  LMem := LAllocator.GetMem(0);
  AssertNull('GetMem should return nil for zero size', LMem);

  // 释放分配器对象，避免泄漏
  LAllocator.Free;
end;

procedure TTestCase_RtlAllocator.Test_AllocMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
  i         : Integer;
begin
  LAllocator := TRtlAllocator.Create;
  try
    LMem       := LAllocator.AllocMem(100);
    AssertNotNull('AllocMem should return a non-nil pointer for non-zero size', LMem);

    for i := 0 to 99 do
      AssertEquals('AllocMem should zero-initialize memory', 0, PByte(LMem)[i]);

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
  LAllocator: IAllocator;
  LMem      : Pointer;
  LNewMem   : Pointer;
  i         : Integer;
begin
  LAllocator := TRtlAllocator.Create;

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

  for i := 0 to 49 do PByte(LMem)[i] := i;

  LNewMem := LAllocator.ReallocMem(LMem, 100);
  AssertNotNull('ReallocMem to larger size should return non-nil', LNewMem);

  for i := 0 to 49 do AssertEquals('ReallocMem should preserve existing data', i, PByte(LNewMem)[i]);

  LAllocator.FreeMem(LNewMem);
  LMem := LAllocator.GetMem(100);

  for i := 0 to 99 do PByte(LMem)[i] := i;

  LNewMem := LAllocator.ReallocMem(LMem, 50);
  AssertNotNull('ReallocMem to smaller size should return non-nil', LNewMem);

  for i := 0 to 49 do AssertEquals('ReallocMem should preserve existing data', i, PByte(LNewMem)[i]);

  LAllocator.FreeMem(LNewMem);

  // 释放分配器对象
  LAllocator.Free;
end;

procedure TTestCase_RtlAllocator.Test_FreeMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
begin
  LAllocator := TRtlAllocator.Create;
  LMem       := LAllocator.GetMem(10);
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

  // 释放分配器对象
  LAllocator.Free;
end;

{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}

{ TTestCase_CrtAllocator }

procedure TTestCase_CrtAllocator.Test_GetMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
begin
  LAllocator := TCrtAllocator.Create;
  LMem       := LAllocator.GetMem(100);
  AssertNotNull('GetMem should return a non-nil pointer for non-zero size', LMem);
  LAllocator.FreeMem(LMem);

  // 空操作原则测试: 零字节分配
  LMem := LAllocator.GetMem(0);
  AssertNull('GetMem should return nil for zero size', LMem);

  // 释放分配器对象
  LAllocator.Free;
end;

procedure TTestCase_CrtAllocator.Test_AllocMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
  i         : Integer;
begin
  LAllocator := TCrtAllocator.Create;
  LMem       := LAllocator.AllocMem(100);
  AssertNotNull('AllocMem should return a non-nil pointer for non-zero size', LMem);

  for i := 0 to 99 do
    AssertEquals('AllocMem should zero-initialize memory', 0, PByte(LMem)[i]);

  LAllocator.FreeMem(LMem);

  // 空操作原则测试: 零字节分配
  LMem := LAllocator.AllocMem(0);
  AssertNull('AllocMem should return nil for zero size', LMem);

  // 释放分配器对象
  LAllocator.Free;
end;

procedure TTestCase_CrtAllocator.Test_ReallocMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
  LNewMem   : Pointer;
  i         : Integer;
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

    for i := 0 to 49 do PByte(LMem)[i] := i;

    LNewMem := LAllocator.ReallocMem(LMem, 100);
    AssertNotNull('ReallocMem to larger size should return non-nil', LNewMem);

    for i := 0 to 49 do AssertEquals('ReallocMem should preserve existing data', i, PByte(LNewMem)[i]);

    LAllocator.FreeMem(LNewMem);

    LMem := LAllocator.GetMem(100);

    for i := 0 to 99 do PByte(LMem)[i] := i;

    LNewMem := LAllocator.ReallocMem(LMem, 50);
    AssertNotNull('ReallocMem to smaller size should return non-nil', LNewMem);

    for i := 0 to 49 do AssertEquals('ReallocMem should preserve existing data', i, PByte(LNewMem)[i]);

    LAllocator.FreeMem(LNewMem);
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_CrtAllocator.Test_FreeMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
begin
  LAllocator := TCrtAllocator.Create;
  LMem       := LAllocator.GetMem(10);
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

  // 释放分配器对象
  LAllocator.Free;
end;

{$ENDIF}

{ TTestCase_CallbackAllocator }

// Dummy callbacks for testing TCallbackAllocator
function DummyGetMem(aSize: SizeUInt): Pointer;
begin
  Result := System.GetMem(SizeInt(aSize));
end;

function DummyAllocMem(aSize: SizeUInt): Pointer;
begin
  Result := System.AllocMem(SizeInt(aSize));
end;

function DummyReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
begin
  Result := System.ReallocMem(aDst, SizeInt(aSize));
end;

procedure DummyFreeMem(aDst: Pointer);
begin
  System.FreeMem(aDst);
end;

procedure TTestCase_CallbackAllocator.Test_GetMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
begin
  LAllocator := TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem       := LAllocator.GetMem(100);
    AssertNotNull('GetMem should return a non-nil pointer for non-zero size', LMem);
    LAllocator.FreeMem(LMem);
  finally
    // 释放 TCallbackAllocator 实例
    TCallbackAllocator(LAllocator).Free;
  end;

  // 空操作原则测试: 零字节分配
  LAllocator := TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem := LAllocator.GetMem(0);
    AssertNull('GetMem should return nil for zero size', LMem);
  finally
    TCallbackAllocator(LAllocator).Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_AllocMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
  i         : Integer;
begin
  LAllocator := TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem       := LAllocator.AllocMem(100);
    AssertNotNull('AllocMem should return a non-nil pointer for non-zero size', LMem);

    for i := 0 to 99 do
      AssertEquals('AllocMem should zero-initialize memory', 0, PByte(LMem)[i]);
    LAllocator.FreeMem(LMem);

    // 空操作原则测试: 零字节分配
    LMem := LAllocator.AllocMem(0);
    AssertNull('AllocMem should return nil for zero size', LMem);
  finally
    TCallbackAllocator(LAllocator).Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_ReallocMem;
var
  LAllocator: IAllocator;
  LMem      : Pointer;
  LNewMem   : Pointer;
  i         : Integer;
begin
  LAllocator := TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
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
    for i := 0 to 49 do PByte(LMem)[i] := i;
    LNewMem := LAllocator.ReallocMem(LMem, 100);
    AssertNotNull('ReallocMem to larger size should return non-nil', LNewMem);
    for i := 0 to 49 do AssertEquals('ReallocMem should preserve existing data', i, PByte(LNewMem)[i]);
    LAllocator.FreeMem(LNewMem);

    LMem := LAllocator.GetMem(100);
    for i := 0 to 99 do PByte(LMem)[i] := i;
    LNewMem := LAllocator.ReallocMem(LMem, 50);
    AssertNotNull('ReallocMem to smaller size should return non-nil', LNewMem);
    for i := 0 to 49 do AssertEquals('ReallocMem should preserve existing data', i, PByte(LNewMem)[i]);
    LAllocator.FreeMem(LNewMem);
  finally
    TCallbackAllocator(LAllocator).Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_FreeMem;
var
  LAllocator: IAllocator;
  LTemp     : IAllocator;
  LMem      : Pointer;
begin
  // 正常释放路径验证
  LAllocator := TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
  try
    LMem := LAllocator.GetMem(10);
    AssertNotNull('GetMem should return a non-nil pointer', LMem);
    LAllocator.FreeMem(LMem);
  finally
    TCallbackAllocator(LAllocator).Free;
  end;

  // 异常路径单独验证，使用独立实例，避免与上面的 finally 干扰
  LTemp := TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
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
    TCallbackAllocator(LTemp).Free;
  end;
end;

procedure TTestCase_CallbackAllocator.Test_Create_NilCallbacks;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(
    'Creating TCallbackAllocator with nil GetMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      TCallbackAllocator.Init(nil, @DummyAllocMem, @DummyReallocMem, @DummyFreeMem);
    end);

  AssertException(
    'Creating TCallbackAllocator with nil AllocMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      TCallbackAllocator.Init(@DummyGetMem, nil, @DummyReallocMem, @DummyFreeMem);
    end);

  AssertException(
    'Creating TCallbackAllocator with nil ReallocMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, nil, @DummyFreeMem);
    end);

  AssertException(
    'Creating TCallbackAllocator with nil FreeMem callback should raise EArgumentNil',
    EArgumentNil,
    procedure
    begin
      TCallbackAllocator.Init(@DummyGetMem, @DummyAllocMem, @DummyReallocMem, nil);
    end);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_RtlAllocator);
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  RegisterTest(TTestCase_CrtAllocator);
  {$ENDIF}
  RegisterTest(TTestCase_CallbackAllocator);
end.
