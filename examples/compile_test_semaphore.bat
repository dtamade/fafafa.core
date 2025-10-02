@echo off
fpc -Mobjfpc -Sh -O1 -g -gl -l ^
  -FuD:\projects\Pascal\lazarus\My\libs\fafafa.core\src ^
  -FiD:\projects\Pascal\lazarus\My\libs\fafafa.core\src ^
  -FE. ^
  test_semaphore.pas