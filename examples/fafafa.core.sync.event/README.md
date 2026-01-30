# fafafa.core.sync.event Examples

## Overview

This directory contains practical examples demonstrating the usage of `fafafa.core.sync.event` module.

## Examples

### Basic Usage
- `example_basic_usage.lpr` - Basic event operations (create, set, wait, reset)
- `example_auto_vs_manual.lpr` - Comparison between auto-reset and manual-reset events

### Practical Patterns
- `example_producer_consumer.lpr` - Producer-consumer pattern using events
- `example_thread_coordination.lpr` - Multi-thread coordination and synchronization
- `example_timeout_handling.lpr` - Proper timeout handling and error management

## Building Examples

### Windows
```batch
buildExamples.bat
```

### Linux
```bash
chmod +x buildExamples.sh
./buildExamples.sh
```

## Running Examples

Each example is a standalone executable that demonstrates specific functionality:

```batch
# Windows
bin\example_basic_usage.exe

# Linux
./bin/example_basic_usage
```

## Key Concepts Demonstrated

- **Auto-reset vs Manual-reset events**
- **Thread synchronization patterns**
- **Timeout handling**
- **Producer-consumer coordination**
- **Multi-thread coordination**
- **Error handling and recovery**
