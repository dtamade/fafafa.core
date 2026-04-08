# example_timeout

演示带超时的等待：
- 线程在持有互斥锁的情况下调用 Cond.Wait(Mutex, TimeoutMs)
- 超时后返回 False，不会阻塞

构建：
- Windows: `BuildOrRun.bat build`
- Linux: `./BuildOrRun.sh build`

运行：
- Windows: `BuildOrRun.bat`
- Linux: `./BuildOrRun.sh`

