unit fafafa.core.test.io;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.io;

type
  // Re-export shared I/O abstractions for backward compatibility
  ITextSink = fafafa.core.io.ITextSink;
  TConsoleSink = fafafa.core.io.TConsoleSink;
  TFileSink = fafafa.core.io.TFileSink;
  TStringSink = fafafa.core.io.TStringSink;

implementation

end.

