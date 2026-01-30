unit fafafa.core.sync.namedSemaphore.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, SysUtils;

type
  // Error kinds for named semaphore operations
  TNamedSemaphoreErrorKind = (
    sekNone,
    sekInvalidArgument,
    sekTimeout,
    sekAccessDenied,
    sekResourceExhausted,
    sekNotFound,
    sekAlreadyExists,
    sekSystemError,
    sekUnknown
  );

  // Error record
  TNamedSemaphoreError = record
    Kind: TNamedSemaphoreErrorKind;
    Message: string;
    SystemErrorCode: Integer;

    class function None: TNamedSemaphoreError; static;
    class function InvalidArgument(const AMessage: string): TNamedSemaphoreError; static;
    class function Timeout(const AMessage: string): TNamedSemaphoreError; static;
    class function AccessDenied(const AMessage: string): TNamedSemaphoreError; static;
    class function ResourceExhausted(const AMessage: string): TNamedSemaphoreError; static;
    class function NotFound(const AMessage: string): TNamedSemaphoreError; static;
    class function AlreadyExists(const AMessage: string): TNamedSemaphoreError; static;
    class function SystemError(const AMessage: string; ASystemErrorCode: Integer): TNamedSemaphoreError; static;
    class function Unknown(const AMessage: string): TNamedSemaphoreError; static;

    function IsError: Boolean;
    function ToString: string;
  end;

  // Forward declaration for guard interface used by result type
  INamedSemaphoreGuard = interface;

  // Result<T>-style wrapper for guard or error
  TNamedSemaphoreGuardResult = record
    Guard: INamedSemaphoreGuard;
    Error: TNamedSemaphoreError;

    class function Success(const AGuard: INamedSemaphoreGuard): TNamedSemaphoreGuardResult; static;
    class function Failure(const AError: TNamedSemaphoreError): TNamedSemaphoreGuardResult; static;

    function IsSuccess: Boolean;
    function IsFailure: Boolean;
    function GetGuard: INamedSemaphoreGuard;
    function TryGetGuard(out AGuard: INamedSemaphoreGuard): Boolean;
  end;

  // Config
  TNamedSemaphoreConfig = record
    UseGlobalNamespace: Boolean;
    InitialCount: Integer;
    MaxCount: Integer;
    EnablePerformanceMonitoring: Boolean;
  end;

// Config helpers
function DefaultNamedSemaphoreConfig: TNamedSemaphoreConfig;
function GlobalNamedSemaphoreConfig: TNamedSemaphoreConfig;
function NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount: Integer): TNamedSemaphoreConfig;

type
  // RAII guard interface
  INamedSemaphoreGuard = interface
    ['{B2C3D4E5-6F7A-8901-BCDE-F23456789012}']
    function GetName: string;
    function GetCount: Integer;
    function IsReleased: Boolean;
    procedure Release;
  end;

  // Public interface
  INamedSemaphore = interface
    ['{C3D4E5F6-7A8B-9CDE-F012-345678901234}']
    function Wait: INamedSemaphoreGuard;                              // blocking wait
    function TryWait: INamedSemaphoreGuard;                           // non-blocking
    function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard;  // timed wait

    function WaitSafe: TNamedSemaphoreGuardResult;                              // blocking
    function TryWaitSafe: TNamedSemaphoreGuardResult;                          // non-blocking
    function TryWaitForSafe(ATimeoutMs: Cardinal): TNamedSemaphoreGuardResult; // timed

    procedure Release; overload;                                      // release 1
    procedure Release(ACount: Integer); overload;                     // release many

    function GetName: string;
    function GetCurrentCount: Integer;
    function GetMaxCount: Integer;

    function GetWaitCount: Int64;
    function GetReleaseCount: Int64;
    function GetAverageWaitTime: Double;
  end;

implementation

function DefaultNamedSemaphoreConfig: TNamedSemaphoreConfig;
begin
  Result.UseGlobalNamespace := False;
  Result.InitialCount := 1;
  Result.MaxCount := 1;
  Result.EnablePerformanceMonitoring := False;
end;

function GlobalNamedSemaphoreConfig: TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.UseGlobalNamespace := True;
end;

function NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount: Integer): TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.InitialCount := AInitialCount;
  Result.MaxCount := AMaxCount;
end;

// TNamedSemaphoreError
class function TNamedSemaphoreError.None: TNamedSemaphoreError;
begin
  Result.Kind := sekNone;
  Result.Message := '';
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.InvalidArgument(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekInvalidArgument;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.Timeout(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekTimeout;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.AccessDenied(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekAccessDenied;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.ResourceExhausted(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekResourceExhausted;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.NotFound(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekNotFound;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.AlreadyExists(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekAlreadyExists;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

class function TNamedSemaphoreError.SystemError(const AMessage: string; ASystemErrorCode: Integer): TNamedSemaphoreError;
begin
  Result.Kind := sekSystemError;
  Result.Message := AMessage;
  Result.SystemErrorCode := ASystemErrorCode;
end;

class function TNamedSemaphoreError.Unknown(const AMessage: string): TNamedSemaphoreError;
begin
  Result.Kind := sekUnknown;
  Result.Message := AMessage;
  Result.SystemErrorCode := 0;
end;

function TNamedSemaphoreError.IsError: Boolean;
begin
  Result := Kind <> sekNone;
end;

function TNamedSemaphoreError.ToString: string;
begin
  case Kind of
    sekNone: Result := 'No error';
    sekInvalidArgument: Result := 'Invalid argument: ' + Message;
    sekTimeout: Result := 'Timeout: ' + Message;
    sekAccessDenied: Result := 'Access denied: ' + Message;
    sekResourceExhausted: Result := 'Resource exhausted: ' + Message;
    sekNotFound: Result := 'Not found: ' + Message;
    sekAlreadyExists: Result := 'Already exists: ' + Message;
    sekSystemError: Result := Format('System error (%d): %s', [SystemErrorCode, Message]);
    sekUnknown: Result := 'Unknown error: ' + Message;
    // 注意：所有枚举值已覆盖，无需 else 分支
  end;
end;

// TNamedSemaphoreGuardResult
class function TNamedSemaphoreGuardResult.Success(const AGuard: INamedSemaphoreGuard): TNamedSemaphoreGuardResult;
begin
  Result.Guard := AGuard;
  Result.Error := TNamedSemaphoreError.None;
end;

class function TNamedSemaphoreGuardResult.Failure(const AError: TNamedSemaphoreError): TNamedSemaphoreGuardResult;
begin
  Result.Guard := nil;
  Result.Error := AError;
end;

function TNamedSemaphoreGuardResult.IsSuccess: Boolean;
begin
  Result := not Error.IsError;
end;

function TNamedSemaphoreGuardResult.IsFailure: Boolean;
begin
  Result := Error.IsError;
end;

function TNamedSemaphoreGuardResult.GetGuard: INamedSemaphoreGuard;
begin
  if IsFailure then
    raise ELockError.Create(Error.ToString);
  Result := Guard;
end;

function TNamedSemaphoreGuardResult.TryGetGuard(out AGuard: INamedSemaphoreGuard): Boolean;
begin
  Result := IsSuccess;
  if Result then
    AGuard := Guard
  else
    AGuard := nil;
end;

end.
