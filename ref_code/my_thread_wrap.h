/**
 * Copyright (c) 2023 Wei-Lun Hsu. All Rights Reserved.
 */
/** @file my_thread_wrap.h
 *
 * @author Wei-Lun Hsu
 * @version 0.1
 * @date 2023/11/19
 * @license
 * @description
 */

#ifndef __my_thread_wrap_H_whYIKiTb_l2Xk_Hgmk_sJfS_uULBlz0OrvLY__
#define __my_thread_wrap_H_whYIKiTb_l2Xk_Hgmk_sJfS_uULBlz0OrvLY__

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__WIN32__ ) || define(WIN32)
    #include <windows.h>

    typedef HANDLE  mutex_t;
    typedef HANDLE  thread_t;

    #define mutex_init(m)       m = CreateMutex(NULL, FALSE, NULL)
    #define mutex_lock(m)       WaitForSingleObject(m, INFINITE)
    #define mutex_unlock(m)     ReleaseMutex(m)
    #define mutex_destroy(m)    CloseHandle(m)

    #define thread_init(t, func, arg)       t = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)func, arg, 0, NULL)
    #define thread_join(t)                  WaitForSingleObject(t, INFINITE)

    static inline int cpu_cores() {
        SYSTEM_INFO sysinfo;
        GetSystemInfo(&sysinfo);
        return sysinfo.dwNumberOfProcessors;
    }
#else
    #include <pthread.h>
    #include <assert.h>

    typedef pthread_mutex_t     mutex_t;
    typedef pthread_t           thread_t;

    #define mutex_init(m)       pthread_mutex_init(&(m), NULL)
    #define mutex_lock(m)       assert(pthread_mutex_lock(&(m)) == 0)
    #define mutex_unlock(m)     pthread_mutex_unlock(&(m))
    #define mutex_destroy(m)    pthread_mutex_destroy(&(m))

    #define thread_init(t, func, arg)   pthread_create(&t, NULL, func, arg)
    #define thread_join(t)              pthread_join(t, NULL)

    static inline int cpu_cores() {
        return sysconf(_SC_NPROCESSORS_ONLN);
    }
#endif

#ifdef __cplusplus
}
#endif

#endif
