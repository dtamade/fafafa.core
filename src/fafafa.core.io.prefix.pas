unit fafafa.core.io.prefix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.io;

type
  // Decorator that adds a prefix to each line
  TPrefixedSink = class(TInterfacedObject, ITextSink)
  private
    FInner: ITextSink;
    FPrefix: string;
  public
    constructor Create(const S: ITextSink; const Prefix: string);
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

constructor TPrefixedSink.Create(const S: ITextSink; const Prefix: string);
begin
  inherited Create;
  FInner := S;
  FPrefix := Prefix;
end;

procedure TPrefixedSink.WriteLine(const S: string);
begin
  if FInner <> nil then FInner.WriteLine(FPrefix + S);
end;

procedure TPrefixedSink.Flush;
begin
  if FInner <> nil then FInner.Flush;
end;

end.

