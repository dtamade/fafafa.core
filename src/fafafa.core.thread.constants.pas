unit fafafa.core.thread.constants;

{$mode objfpc}{$H+}

interface

const
  // 等待片段时长（毫秒），用于轮询等待避免忙等，默认 10ms
  WaitSliceMs: Cardinal = 10;

implementation

end.

