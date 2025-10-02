unit fafafa.core.time.consts;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

const
  // Base rate constants
  NANOSECONDS_PER_SECOND  = Int64(1000000000);
  MICROSECONDS_PER_SECOND = Int64(1000000);
  MILLISECONDS_PER_SECOND = Int64(1000);

  // Convenience for conversions
  NANOSECONDS_PER_MILLI = Int64(1000000);
  NANOSECONDS_PER_MICRO = Int64(1000);

implementation

end.

