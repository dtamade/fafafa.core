use std::sync::{Arc, Mutex};
use std::sync::atomic::{AtomicU64, Ordering};
use std::thread;
use std::time::{Duration, Instant};
use parking_lot::{Mutex as ParkingLotMutex};
use spin::{Mutex as SpinMutex};

#[derive(Debug, Clone)]
struct BenchmarkResult {
    test_name: String,
    thread_count: usize,
    operations: u64,
    elapsed_ns: u64,
    ops_per_second: f64,
    avg_latency_ns: f64,
}

fn run_benchmark<F, T>(
    test_name: &str,
    thread_count: usize,
    duration_secs: u64,
    create_lock: F,
) -> BenchmarkResult
where
    F: Fn() -> T + Send + Sync + 'static,
    T: Send + Sync + 'static + BenchmarkLock,
    for<'a> &'a T: Send,
{
    println!("测试: {} ({}线程, {}秒)", test_name, thread_count, duration_secs);
    
    let lock = Arc::new(create_lock());
    let operations = Arc::new(AtomicU64::new(0));
    let duration = Duration::from_secs(duration_secs);
    
    // 预热
    for _ in 0..1000 {
        benchmark_operation(&lock);
    }
    
    thread::sleep(Duration::from_millis(100));
    
    let start_time = Instant::now();
    
    if thread_count == 1 {
        // 单线程测试
        let mut local_ops = 0u64;
        let start = Instant::now();
        
        loop {
            benchmark_operation(&lock);
            local_ops += 1;
            
            if local_ops & 0x3FF == 0 {  // 每1024次检查时间
                if start.elapsed() >= duration {
                    break;
                }
            }
        }
        
        operations.store(local_ops, Ordering::Relaxed);
    } else {
        // 多线程测试
        let mut handles = Vec::new();
        
        for _ in 0..thread_count {
            let lock_clone = Arc::clone(&lock);
            let operations_clone = Arc::clone(&operations);
            let start_time_clone = start_time;
            
            let handle = thread::spawn(move || {
                let mut local_ops = 0u64;
                
                loop {
                    benchmark_operation(&lock_clone);
                    local_ops += 1;
                    
                    if local_ops & 0x3FF == 0 {  // 每1024次检查时间
                        if start_time_clone.elapsed() >= duration {
                            break;
                        }
                    }
                }
                
                operations_clone.fetch_add(local_ops, Ordering::Relaxed);
            });
            
            handles.push(handle);
        }
        
        thread::sleep(duration);
        
        for handle in handles {
            handle.join().unwrap();
        }
    }
    
    let elapsed = start_time.elapsed();
    let total_ops = operations.load(Ordering::Relaxed);
    let elapsed_ns = elapsed.as_nanos() as u64;
    let ops_per_second = (total_ops as f64 * 1_000_000_000.0) / elapsed_ns as f64;
    let avg_latency_ns = elapsed_ns as f64 / total_ops as f64;
    
    println!("  操作数: {}", total_ops);
    println!("  耗时: {:.3} ms", elapsed_ns as f64 / 1_000_000.0);
    println!("  吞吐量: {:.0} ops/sec", ops_per_second);
    
    if thread_count == 1 {
        println!("  平均延迟: {:.2} ns/op", avg_latency_ns);
    } else {
        println!("  平均延迟: {:.2} ns/op (含竞争)", avg_latency_ns);
    }
    
    println!();
    
    BenchmarkResult {
        test_name: test_name.to_string(),
        thread_count,
        operations: total_ops,
        elapsed_ns,
        ops_per_second,
        avg_latency_ns,
    }
}

// 针对不同锁类型的基准测试操作
trait BenchmarkLock {
    fn lock_and_unlock(&self);
}

impl BenchmarkLock for Mutex<()> {
    fn lock_and_unlock(&self) {
        let _guard = self.lock().unwrap();
    }
}

impl BenchmarkLock for ParkingLotMutex<()> {
    fn lock_and_unlock(&self) {
        let _guard = self.lock();
    }
}

impl BenchmarkLock for SpinMutex<()> {
    fn lock_and_unlock(&self) {
        let _guard = self.lock();
    }
}

// 为 Arc<T> 实现 BenchmarkLock，其中 T 实现了 BenchmarkLock
impl<T: BenchmarkLock> BenchmarkLock for Arc<T> {
    fn lock_and_unlock(&self) {
        (**self).lock_and_unlock();
    }
}

fn benchmark_operation<T: BenchmarkLock>(lock: &T) {
    lock.lock_and_unlock();
}

fn main() {
    println!("Rust 自旋锁基准测试");
    println!("===================");
    println!();
    println!("测试目标: 对比不同 Rust 锁实现的性能");
    println!("测试平台: {}", std::env::consts::OS);
    println!("测试架构: {}", std::env::consts::ARCH);
    println!();
    
    let test_duration = 3; // 3秒测试
    let mut results = Vec::new();
    
    // 测试 std::sync::Mutex
    println!("=== std::sync::Mutex 测试 ===");
    for &thread_count in &[1, 2, 4, 8] {
        let result = run_benchmark(
            &format!("std::sync::Mutex ({}线程)", thread_count),
            thread_count,
            test_duration,
            || Mutex::new(()),
        );
        results.push(result);
        thread::sleep(Duration::from_millis(1000));
    }

    // 测试 parking_lot::Mutex
    println!("=== parking_lot::Mutex 测试 ===");
    for &thread_count in &[1, 2, 4, 8] {
        let result = run_benchmark(
            &format!("parking_lot::Mutex ({}线程)", thread_count),
            thread_count,
            test_duration,
            || ParkingLotMutex::new(()),
        );
        results.push(result);
        thread::sleep(Duration::from_millis(1000));
    }

    // 测试 spin::Mutex (自旋锁)
    println!("=== spin::Mutex 测试 (自旋锁) ===");
    for &thread_count in &[1, 2, 4, 8] {
        let result = run_benchmark(
            &format!("spin::Mutex ({}线程)", thread_count),
            thread_count,
            test_duration,
            || SpinMutex::new(()),
        );
        results.push(result);
        thread::sleep(Duration::from_millis(1000));
    }
    
    // 输出汇总结果
    println!("===================");
    println!("基准测试结果汇总 (按吞吐量排序)");
    println!("===================");
    
    // 按吞吐量排序
    results.sort_by(|a, b| b.ops_per_second.partial_cmp(&a.ops_per_second).unwrap());
    
    for result in &results {
        println!(
            "{:<30}: {:>10.0} ops/sec ({:>6.2} ns/op)",
            result.test_name, result.ops_per_second, result.avg_latency_ns
        );
    }
    
    println!();
    println!("Rust 基准测试完成！");
}
