# example_timeout

演示带超时的等待：
- 线程在持有互斥锁的情况下调用 Cond.Wait(Mutex, TimeoutMs)
- 超时后返回 False，不会阻塞

构建：
- Windows: 双击 `buildOrTest.bat`
- Linux: 进入该目录执行 `lazbuild example_timeout.lpi`

