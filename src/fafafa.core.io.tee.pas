unit fafafa.core.io.tee;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.io;

type
  // Fan-out sink: writes to two sinks
  TTeeSink = class(TInterfacedObject, ITextSink)
  private
    FA, FB: ITextSink;
  public
    constructor Create(const S1, S2: ITextSink);
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

constructor TTeeSink.Create(const S1, S2: ITextSink);
begin
  inherited Create;
  FA := S1; FB := S2;
end;

procedure TTeeSink.WriteLine(const S: string);
begin
  if FA <> nil then FA.WriteLine(S);
  if FB <> nil then FB.WriteLine(S);
end;

procedure TTeeSink.Flush;
begin
  if FA <> nil then FA.Flush;
  if FB <> nil then FB.Flush;
end;

end.

