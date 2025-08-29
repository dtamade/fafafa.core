# fafafa.core 事件同步原语示例 Makefile

# 编译器设置
FPC = /home/dtamade/fpc/fpc/bin/x86_64-linux/fpc.sh
FPCFLAGS = -B -S2 -MObjFPC -Fu../../../src

# 输出目录
OUTDIR = bin

# 示例程序
EXAMPLES = 01_basic_event_usage 02_producer_consumer 03_thread_pool 04_reader_writer_lock 05_performance_benchmark

# 默认目标
all: $(OUTDIR) $(addprefix $(OUTDIR)/, $(EXAMPLES))

# 创建输出目录
$(OUTDIR):
	mkdir -p $(OUTDIR)

# 编译规则
$(OUTDIR)/%: %.pas
	@echo "编译 $<..."
	$(FPC) $(FPCFLAGS) -FE$(OUTDIR) $<

# 清理
clean:
	rm -rf $(OUTDIR)
	rm -f *.o *.ppu

# 运行所有示例
run-all: all
	@echo "运行所有示例..."
	@for example in $(EXAMPLES); do \
		echo ""; \
		echo "=== 运行 $$example ==="; \
		echo ""; \
		$(OUTDIR)/$$example || true; \
		echo ""; \
		echo "按回车继续下一个示例..."; \
		read; \
	done

# 单独运行示例
run-basic: $(OUTDIR)/01_basic_event_usage
	$(OUTDIR)/01_basic_event_usage

run-producer-consumer: $(OUTDIR)/02_producer_consumer
	$(OUTDIR)/02_producer_consumer

run-thread-pool: $(OUTDIR)/03_thread_pool
	$(OUTDIR)/03_thread_pool

run-reader-writer: $(OUTDIR)/04_reader_writer_lock
	$(OUTDIR)/04_reader_writer_lock

run-benchmark: $(OUTDIR)/05_performance_benchmark
	$(OUTDIR)/05_performance_benchmark

# 帮助信息
help:
	@echo "fafafa.core 事件同步原语示例编译系统"
	@echo ""
	@echo "可用目标："
	@echo "  all                 - 编译所有示例"
	@echo "  clean               - 清理编译文件"
	@echo "  run-all             - 运行所有示例"
	@echo "  run-basic           - 运行基础使用示例"
	@echo "  run-producer-consumer - 运行生产者消费者示例"
	@echo "  run-thread-pool     - 运行线程池示例"
	@echo "  run-reader-writer   - 运行读写锁示例"
	@echo "  run-benchmark       - 运行性能基准测试"
	@echo "  help                - 显示此帮助信息"

.PHONY: all clean run-all run-basic run-producer-consumer run-thread-pool run-reader-writer run-benchmark help
