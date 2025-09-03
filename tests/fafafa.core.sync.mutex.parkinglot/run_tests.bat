@echo off
chcp 65001 >nul
echo 开始运行 Parking Lot Mutex 单元测试...
echo.

echo === 全局工厂函数测试 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Global --format=plain
echo.

echo === 基本功能测试 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_IParkingLotMutex --format=plain
echo.

echo === 并发测试 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Concurrency --format=plain
echo.

echo === 性能测试 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Performance --format=plain
echo.

echo === 边界条件测试 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_EdgeCases --format=plain
echo.

echo === 平台特定测试 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Platform --format=plain
echo.

echo === 完整测试套件 ===
bin\fafafa.core.sync.mutex.parkinglot.test.exe --format=plain --progress
echo.

echo 测试完成！
pause
