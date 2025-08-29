{$CODEPAGE UTF8}
program TestFunctionalOverloads;

uses
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<LongInt>;

// 测试用的函数指针版本
function IsEven(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function IsGreaterThan(const aValue: LongInt; aData: Pointer): Boolean;
var
  LThreshold: PLongInt;
begin
  LThreshold := PLongInt(aData);
  Result := aValue > LThreshold^;
end;

// 测试用的对象和方法
type
  TTestObject = class
  public
    FThreshold: LongInt;
    constructor Create(aThreshold: LongInt);
    function IsGreaterThanThreshold(const aValue: LongInt; aData: Pointer): Boolean;
    function IsLessThanThreshold(const aValue: LongInt; aData: Pointer): Boolean;
  end;

constructor TTestObject.Create(aThreshold: LongInt);
begin
  FThreshold := aThreshold;
end;

function TTestObject.IsGreaterThanThreshold(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := aValue > FThreshold;
end;

function TTestObject.IsLessThanThreshold(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := aValue < FThreshold;
end;

var
  LVec: TIntVec;
  LFilteredVec: specialize IVec<LongInt>;
  LTestObj: TTestObject;
  LThreshold: LongInt;
  i: SizeUInt;

begin
  WriteLn('=== Testing Complete Function Overloads for Functional Programming API ===');

  // Create test vector
  LVec := TIntVec.Create;
  try
    // Add test data
    LVec.Push([10, 15, 20, 25, 30, 35, 40]);

    WriteLn('1. Original Data');
    Write('   Data: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;

    // Test Filter method with three overloads
    WriteLn('2. Testing Filter Method with Three Overloads');

    // Function pointer version - filter even numbers
    WriteLn('   Function Pointer Version - Filter Even Numbers:');
    LFilteredVec := LVec.Filter(@IsEven, nil);
    try
      Write('   Result: ');
      for i := 0 to LFilteredVec.Count - 1 do
        Write(LFilteredVec.Get(i), ' ');
      WriteLn;
    finally
      LFilteredVec := nil;
    end;

    // Function pointer version - filter numbers greater than 25
    LThreshold := 25;
    WriteLn('   Function Pointer Version - Filter Numbers > 25:');
    LFilteredVec := LVec.Filter(@IsGreaterThan, @LThreshold);
    try
      Write('   Result: ');
      for i := 0 to LFilteredVec.Count - 1 do
        Write(LFilteredVec.Get(i), ' ');
      WriteLn;
    finally
      LFilteredVec := nil;
    end;

    // Method pointer version
    LTestObj := TTestObject.Create(20);
    try
      WriteLn('   Method Pointer Version - Filter Numbers > 20:');
      LFilteredVec := LVec.Filter(@LTestObj.IsGreaterThanThreshold, nil);
      try
        Write('   Result: ');
        for i := 0 to LFilteredVec.Count - 1 do
          Write(LFilteredVec.Get(i), ' ');
        WriteLn;
      finally
        LFilteredVec := nil;
      end;
    finally
      LTestObj.Free;
    end;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // Anonymous function version
    WriteLn('   Anonymous Function Version - Filter Numbers > 30:');
    LFilteredVec := LVec.Filter(function(const aValue: LongInt): Boolean
      begin
        Result := aValue > 30;
      end);
    try
      Write('   Result: ');
      for i := 0 to LFilteredVec.Count - 1 do
        Write(LFilteredVec.Get(i), ' ');
      WriteLn;
    finally
      LFilteredVec := nil;
    end;
    {$ENDIF}

    // Test Any method with three overloads
    WriteLn('3. Testing Any Method with Three Overloads');

    // Function pointer version
    WriteLn('   Function Pointer Version - Has Even Numbers: ', LVec.Any(@IsEven, nil));

    LThreshold := 50;
    WriteLn('   Function Pointer Version - Has Numbers > 50: ', LVec.Any(@IsGreaterThan, @LThreshold));

    // Method pointer version
    LTestObj := TTestObject.Create(35);
    try
      WriteLn('   Method Pointer Version - Has Numbers > 35: ', LVec.Any(@LTestObj.IsGreaterThanThreshold, nil));
    finally
      LTestObj.Free;
    end;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // Anonymous function version
    WriteLn('   Anonymous Function Version - Has Numbers < 15: ', LVec.Any(function(const aValue: LongInt): Boolean
      begin
        Result := aValue < 15;
      end));
    {$ENDIF}

    // Test All method with three overloads
    WriteLn('4. Testing All Method with Three Overloads');

    // Function pointer version
    LThreshold := 5;
    WriteLn('   Function Pointer Version - All Numbers > 5: ', LVec.All(@IsGreaterThan, @LThreshold));

    // Method pointer version
    LTestObj := TTestObject.Create(50);
    try
      WriteLn('   Method Pointer Version - All Numbers < 50: ', LVec.All(@LTestObj.IsLessThanThreshold, nil));
    finally
      LTestObj.Free;
    end;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // Anonymous function version
    WriteLn('   Anonymous Function Version - All Numbers > 0: ', LVec.All(function(const aValue: LongInt): Boolean
      begin
        Result := aValue > 0;
      end));
    {$ENDIF}

  finally
    LVec.Free;
  end;

  WriteLn('=== Test Completed ===');
end.
