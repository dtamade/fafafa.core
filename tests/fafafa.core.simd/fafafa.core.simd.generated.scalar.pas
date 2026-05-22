{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

unit fafafa.core.simd.generated.scalar;

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

{$I ../../src/generated/fafafa.core.simd.scalar.decl.inc}

implementation

uses
  Math;

{$I ../../src/generated/fafafa.core.simd.scalar.impl.inc}

end.
