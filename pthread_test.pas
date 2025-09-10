program pthread_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  pthreads,
  {$ENDIF}
  SysUtils;

{$IFDEF UNIX}
var
  mutex: pthread_mutex_t;
{$ENDIF}

begin
  WriteLn('Testing pthread availability...');
  {$IFDEF UNIX}
  WriteLn('pthread_mutex_t size: ', SizeOf(pthread_mutex_t));
  {$ELSE}
  WriteLn('Not Unix platform');
  {$ENDIF}
  WriteLn('Test completed.');
end.
