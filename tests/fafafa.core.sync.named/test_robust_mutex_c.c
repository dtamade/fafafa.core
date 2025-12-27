/*
 * Robust Mutex Test in C
 * Verify if robust mutexes work correctly on this system
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>
#include <time.h>

int main() {
    printf("=== Robust Mutex Test in C ===\n");
    printf("sizeof(pthread_mutex_t) = %zu bytes\n", sizeof(pthread_mutex_t));
    printf("sizeof(pthread_mutexattr_t) = %zu bytes\n", sizeof(pthread_mutexattr_t));

    const char* shm_name = "/fafafa_robust_c_test";

    // Clean up any existing shared memory
    shm_unlink(shm_name);

    // Create shared memory
    int fd = shm_open(shm_name, O_CREAT | O_RDWR, 0600);
    if (fd < 0) {
        perror("shm_open");
        return 1;
    }

    if (ftruncate(fd, sizeof(pthread_mutex_t)) < 0) {
        perror("ftruncate");
        close(fd);
        shm_unlink(shm_name);
        return 1;
    }

    pthread_mutex_t* mutex = mmap(NULL, sizeof(pthread_mutex_t),
        PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (mutex == MAP_FAILED) {
        perror("mmap");
        close(fd);
        shm_unlink(shm_name);
        return 1;
    }

    printf("Mutex mapped at: %p\n", mutex);

    // Initialize mutex attributes
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);

    int ret = pthread_mutexattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
    if (ret != 0) {
        printf("setpshared failed: %s\n", strerror(ret));
        return 1;
    }

    ret = pthread_mutexattr_setrobust(&attr, PTHREAD_MUTEX_ROBUST);
    if (ret != 0) {
        printf("setrobust failed: %s\n", strerror(ret));
        return 1;
    }

    // Verify attributes
    int robust_val, pshared_val;
    pthread_mutexattr_getrobust(&attr, &robust_val);
    pthread_mutexattr_getpshared(&attr, &pshared_val);
    printf("Robust attribute: %d (expected %d)\n", robust_val, PTHREAD_MUTEX_ROBUST);
    printf("Pshared attribute: %d (expected %d)\n", pshared_val, PTHREAD_PROCESS_SHARED);

    // Initialize mutex
    ret = pthread_mutex_init(mutex, &attr);
    pthread_mutexattr_destroy(&attr);

    if (ret != 0) {
        printf("pthread_mutex_init failed: %s\n", strerror(ret));
        munmap(mutex, sizeof(pthread_mutex_t));
        close(fd);
        shm_unlink(shm_name);
        return 1;
    }
    printf("Mutex initialized successfully\n");

    // Fork
    pid_t pid = fork();

    if (pid == 0) {
        // Child process
        printf("[Child] Locking mutex...\n");
        ret = pthread_mutex_lock(mutex);
        if (ret != 0) {
            printf("[Child] Lock failed: %s\n", strerror(ret));
            _exit(1);
        }
        printf("[Child] Mutex locked, sending SIGKILL...\n");
        kill(getpid(), SIGKILL);
        // Should not reach here
        _exit(0);
    } else if (pid > 0) {
        // Parent process
        usleep(200000);  // 200ms

        int status;
        waitpid(pid, &status, 0);
        printf("[Parent] Child terminated\n");

        // Try to lock with timeout
        struct timespec ts;
        clock_gettime(CLOCK_REALTIME, &ts);
        ts.tv_sec += 5;  // 5 second timeout

        printf("[Parent] Attempting pthread_mutex_timedlock...\n");
        ret = pthread_mutex_timedlock(mutex, &ts);
        printf("[Parent] pthread_mutex_timedlock returned: %d", ret);

        if (ret == 0) {
            printf(" (success)\n");
            pthread_mutex_unlock(mutex);
        } else if (ret == EOWNERDEAD) {
            printf(" (EOWNERDEAD - owner died)\n");
            printf("[Parent] Calling pthread_mutex_consistent...\n");
            ret = pthread_mutex_consistent(mutex);
            if (ret == 0) {
                printf("[PASS] Mutex recovered successfully!\n");
                pthread_mutex_unlock(mutex);
            } else {
                printf("[FAIL] pthread_mutex_consistent failed: %s\n", strerror(ret));
            }
        } else if (ret == ETIMEDOUT) {
            printf(" (ETIMEDOUT - robust not working!)\n");
            printf("[FAIL] Robust mutex feature not working on this system\n");
        } else if (ret == EINVAL) {
            printf(" (EINVAL - invalid argument)\n");
            printf("[FAIL] Mutex invalid or not properly initialized\n");
        } else {
            printf(" (%s)\n", strerror(ret));
        }

        // Cleanup
        pthread_mutex_destroy(mutex);
        munmap(mutex, sizeof(pthread_mutex_t));
        close(fd);
        shm_unlink(shm_name);

        printf("=== Test Complete ===\n");
    } else {
        perror("fork");
        pthread_mutex_destroy(mutex);
        munmap(mutex, sizeof(pthread_mutex_t));
        close(fd);
        shm_unlink(shm_name);
        return 1;
    }

    return 0;
}
