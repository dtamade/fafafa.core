program once_usage_example_en;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.once;

var
  GlobalCounter: Integer = 0;
  GlobalInitialized: Boolean = False;

// Example 1: Simple global initialization
procedure GlobalInitProc;
begin
  WriteLn('Executing global initialization...');
  GlobalInitialized := True;
  Inc(GlobalCounter);
end;

procedure TestBasicUsage;
var
  Once: IOnce;
begin
  WriteLn('=== Example 1: Basic Usage ===');
  
  // Create Once instance and pass callback
  Once := MakeOnce(@GlobalInitProc);
  
  WriteLn('First call to Execute:');
  Once.Execute;
  
  WriteLn('Second call to Execute (should be ignored):');
  Once.Execute;
  
  WriteLn('Third call to Execute (should be ignored):');
  Once.Execute;
  
  WriteLn('Global initialization status: ', GlobalInitialized);
  WriteLn('Callback execution count: ', GlobalCounter);
  WriteLn('Is completed: ', Once.Completed);
  WriteLn;
end;

// Example 2: Object method callback
type
  TExampleClass = class
  private
    FValue: Integer;
  public
    constructor Create;
    procedure InitializeMethod;
    function GetValue: Integer;
  end;

constructor TExampleClass.Create;
begin
  inherited Create;
  FValue := 0;
end;

procedure TExampleClass.InitializeMethod;
begin
  WriteLn('Executing object method initialization...');
  FValue := 42;
end;

function TExampleClass.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TestMethodCallback;
var
  Once: IOnce;
  Obj: TExampleClass;
begin
  WriteLn('=== Example 2: Object Method Callback ===');
  
  Obj := TExampleClass.Create;
  try
    // Use object method as callback
    Once := MakeOnce(@Obj.InitializeMethod);
    
    WriteLn('Initial value: ', Obj.GetValue);
    
    WriteLn('First call to Execute:');
    Once.Execute;
    WriteLn('Value: ', Obj.GetValue);
    
    WriteLn('Second call to Execute (should be ignored):');
    Once.Execute;
    WriteLn('Value: ', Obj.GetValue);
    
    WriteLn('Is completed: ', Once.Completed);
  finally
    Obj.Free;
  end;
  WriteLn;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
// Example 3: Anonymous procedure
procedure TestAnonymousProc;
var
  Once: IOnce;
  LocalValue: string;
begin
  WriteLn('=== Example 3: Anonymous Procedure ===');
  
  LocalValue := 'Uninitialized';
  
  // Use anonymous procedure that can capture local variables
  Once := MakeOnce(
    procedure
    begin
      WriteLn('Executing anonymous procedure initialization...');
      LocalValue := 'Initialized';
    end
  );
  
  WriteLn('Initial value: ', LocalValue);
  
  WriteLn('First call to Execute:');
  Once.Execute;
  WriteLn('Value: ', LocalValue);
  
  WriteLn('Second call to Execute (should be ignored):');
  Once.Execute;
  WriteLn('Value: ', LocalValue);
  
  WriteLn('Is completed: ', Once.Completed);
  WriteLn;
end;
{$ENDIF}

// Example 4: Singleton pattern implementation
type
  TExampleSingleton = class
  private
    class var FInstance: TExampleSingleton;
    class var FOnce: IOnce;
    FValue: string;
    class procedure CreateInstanceProc;
  public
    constructor Create;
    class constructor CreateClass;
    class function GetInstance: TExampleSingleton;
    function GetValue: string;
  end;

constructor TExampleSingleton.Create;
begin
  inherited Create;
  FValue := 'Singleton Instance Created';
end;

class constructor TExampleSingleton.CreateClass;
begin
  FOnce := MakeOnce(@CreateInstanceProc);
end;

class procedure TExampleSingleton.CreateInstanceProc;
begin
  WriteLn('Creating singleton instance...');
  FInstance := TExampleSingleton.Create;
end;

class function TExampleSingleton.GetInstance: TExampleSingleton;
begin
  FOnce.Execute;
  Result := FInstance;
end;

function TExampleSingleton.GetValue: string;
begin
  Result := FValue;
end;

procedure TestSingletonPattern;
var
  Instance1, Instance2: TExampleSingleton;
begin
  WriteLn('=== Example 4: Singleton Pattern ===');
  
  WriteLn('Getting first instance:');
  Instance1 := TExampleSingleton.GetInstance;
  WriteLn('Instance value: ', Instance1.GetValue);
  
  WriteLn('Getting second instance:');
  Instance2 := TExampleSingleton.GetInstance;
  WriteLn('Instance value: ', Instance2.GetValue);
  
  WriteLn('Are both instances the same: ', Instance1 = Instance2);
  WriteLn;
end;

// Example 5: ILock interface compatibility
procedure TestILockInterface;
var
  Once: IOnce;
  Lock: ILock;
begin
  WriteLn('=== Example 5: ILock Interface Compatibility ===');
  
  Once := MakeOnce(@GlobalInitProc);
  Lock := Once; // IOnce inherits from ILock
  
  WriteLn('TryAcquire (not executed): ', Lock.TryAcquire);
  
  WriteLn('Calling Acquire (equivalent to Execute):');
  Lock.Acquire;
  
  WriteLn('TryAcquire (executed): ', Lock.TryAcquire);
  
  WriteLn('Calling Release (no operation):');
  Lock.Release;
  
  WriteLn('TryAcquire (still executed): ', Lock.TryAcquire);
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.sync.once Usage Examples');
    WriteLn('===================================');
    WriteLn;
    
    TestBasicUsage;
    TestMethodCallback;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    TestAnonymousProc;
    {$ENDIF}
    
    TestSingletonPattern;
    TestILockInterface;
    
    WriteLn('All examples completed!');
    
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
