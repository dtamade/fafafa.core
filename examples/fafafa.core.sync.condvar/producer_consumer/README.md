# example_producer_consumer

演示经典的生产者-消费者：
- 生产者线程向队列放入数据并 Signal
- 消费者线程在条件变量上等待，消费数据
- 结束时 Broadcast 唤醒所有等待者退出

构建：
- Windows: `BuildOrRun.bat build`
- Linux: `./BuildOrRun.sh build`

运行：
- Windows: `BuildOrRun.bat`
- Linux: `./BuildOrRun.sh`

