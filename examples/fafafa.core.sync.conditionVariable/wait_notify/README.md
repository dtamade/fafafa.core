# example_wait_notify

演示条件变量的基础等待/通知：
- 工作线程持有互斥锁等待条件成立
- 主线程设置条件并 Signal 唤醒

构建：
- Windows: 双击 `buildOrTest.bat`
- Linux: 进入该目录执行 `lazbuild example_wait_notify.lpi`

