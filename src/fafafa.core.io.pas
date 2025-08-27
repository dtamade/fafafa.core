unit fafafa.core.io;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, SyncObjs;

type
  // Minimal, shared text output abstraction for frontends/reporters/transports
  ITextSink = interface
    ['{D7046C86-C3C3-4D2E-9C90-2C34A0E6E4B2}']
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  // Write to StdOut
  TConsoleSink = class(TInterfacedObject, ITextSink)
  public
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  // Append/write to a file (UTF-8 as per process codepage)
  TFileSink = class(TInterfacedObject, ITextSink)
  private
    FFile: Text;
    FOpened: boolean;
    FPath: string;
    procedure EnsureOpen;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  // Accumulate lines in memory
  TStringSink = class(TInterfacedObject, ITextSink)
  private
    FBuf: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
    function AsText: string;
  end;

  // No-op sink
  TNullSink = class(TInterfacedObject, ITextSink)
  public
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  // Thread-safe decorator (no dependency on core.sync while it refactors)
  TSynchronizedTextSink = class(TInterfacedObject, ITextSink)
  private
    FInner: ITextSink;
    FLock: TCriticalSection;
  public
    constructor Create(const S: ITextSink);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

{ TConsoleSink }
procedure TConsoleSink.WriteLine(const S: string);
begin
  WriteLn(S);
end;

procedure TConsoleSink.Flush;
begin
end;

{ TFileSink }
constructor TFileSink.Create(const APath: string);
begin
  inherited Create;
  FPath := APath;
  FOpened := False;
end;

destructor TFileSink.Destroy;
begin
  if FOpened then CloseFile(FFile);
  inherited Destroy;
end;

procedure TFileSink.EnsureOpen;
begin
  if not FOpened then
  begin
    AssignFile(FFile, FPath);
    if FileExists(FPath) then Append(FFile) else Rewrite(FFile);
    FOpened := True;
  end;
end;

procedure TFileSink.WriteLine(const S: string);
begin
  EnsureOpen;
  System.WriteLn(FFile, S);
end;

procedure TFileSink.Flush;
begin
  // Text I/O is unbuffered enough; no-op
end;

{ TStringSink }
constructor TStringSink.Create;
begin
  inherited Create;
  FBuf := TStringList.Create;
end;

destructor TStringSink.Destroy;
begin
  FBuf.Free;
  inherited Destroy;
end;
procedure TStringSink.WriteLine(const S: string);
begin
  FBuf.Add(S);
end;

{ TNullSink }
procedure TNullSink.WriteLine(const S: string);
begin
end;

procedure TNullSink.Flush;
begin
end;

procedure TStringSink.Flush;
begin
end;

function TStringSink.AsText: string;
begin
  Result := FBuf.Text;
end;


{ TSynchronizedTextSink }
constructor TSynchronizedTextSink.Create(const S: ITextSink);
begin
  inherited Create;
  FInner := S;
  FLock := TCriticalSection.Create;
end;

destructor TSynchronizedTextSink.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TSynchronizedTextSink.WriteLine(const S: string);
begin
  FLock.Acquire;
  try
    if FInner <> nil then FInner.WriteLine(S);
  finally
    FLock.Release;
  end;
end;

procedure TSynchronizedTextSink.Flush;
begin
  FLock.Acquire;
  try
    if FInner <> nil then FInner.Flush;
  finally
    FLock.Release;
  end;
end;

end.

