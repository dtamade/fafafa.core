unit fafafa.core.io.textsink;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;

type
  // Minimal line-oriented text sink.
  // Used by logging/reporting/benchmark output adapters.
  ITextSink = interface
    ['{2D93A6F1-0E8A-4D61-9A2B-5F8F0B2F6E2A}']
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  // Console sink (stdout).
  TConsoleSink = class(TInterfacedObject, ITextSink)
  public
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  // File sink (append or truncate).
  TFileSink = class(TInterfacedObject, ITextSink)
  private
    FPath: string;
    FAppend: Boolean;
    FStream: TFileStream;
    FOpened: Boolean;
    procedure EnsureOpen;
  public
    constructor Create(const APath: string; const AAppend: Boolean = True);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
    function Path: string;
  end;

  // In-memory string sink.
  TStringSink = class(TInterfacedObject, ITextSink)
  private
    FText: string;
  public
    procedure WriteLine(const S: string);
    procedure Flush;
    function AsText: string;
    procedure Clear;
  end;

implementation

{ TConsoleSink }

procedure TConsoleSink.WriteLine(const S: string);
begin
  System.WriteLn(S);
end;

procedure TConsoleSink.Flush;
begin
  // no-op
end;

{ TFileSink }

constructor TFileSink.Create(const APath: string; const AAppend: Boolean);
begin
  inherited Create;
  if APath = '' then
    raise EArgumentException.Create('path');
  FPath := APath;
  FAppend := AAppend;
  FStream := nil;
  FOpened := False;
end;

destructor TFileSink.Destroy;
begin
  FreeAndNil(FStream);
  inherited Destroy;
end;

procedure TFileSink.EnsureOpen;
begin
  if FOpened then Exit;

  if FAppend and FileExists(FPath) then
  begin
    FStream := TFileStream.Create(FPath, fmOpenReadWrite or fmShareDenyNone);
    FStream.Seek(0, soEnd);
  end
  else
  begin
    FStream := TFileStream.Create(FPath, fmCreate or fmShareDenyNone);
  end;

  FOpened := True;
end;

procedure TFileSink.WriteLine(const S: string);
var
  U: UTF8String;
  EOL: UTF8String;
begin
  EnsureOpen;

  U := UTF8String(S);
  if Length(U) > 0 then
    FStream.WriteBuffer(U[1], Length(U));

  EOL := UTF8String(LineEnding);
  if Length(EOL) > 0 then
    FStream.WriteBuffer(EOL[1], Length(EOL));
end;

procedure TFileSink.Flush;
begin
  // Best-effort: TFileStream does not expose portable flush/fsync here.
  // Leaving as no-op is fine for most test/report usage.
end;

function TFileSink.Path: string;
begin
  Result := FPath;
end;

{ TStringSink }

procedure TStringSink.WriteLine(const S: string);
begin
  FText := FText + S + LineEnding;
end;

procedure TStringSink.Flush;
begin
  // no-op
end;

function TStringSink.AsText: string;
begin
  Result := FText;
end;

procedure TStringSink.Clear;
begin
  FText := '';
end;

end.
