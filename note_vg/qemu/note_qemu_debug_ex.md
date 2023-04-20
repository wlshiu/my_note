Qemu debug kernel
---


## Debug `ptrace()` syscall

+ sample app

    - app source code

        ```c
        #include <stdio.h>
        #include <stdlib.h>
        #include <sys/ptrace.h>
        #include <sys/types.h>
        #include <sys/wait.h>
        #include <unistd.h>

        int main(int argc, const char *argv[])
        {
            int pid;

            if ((pid = fork() == 0))
            {
                // The child process does a PTRACE_TRACEME,
                // While being traced, the tracee will stop each time a signal is delivered,
                // even if the signal is being ignored.
                ptrace(PTRACE_TRACEME, 0, NULL, NULL);
                execl("/bin/ls", "ls", "-l", NULL);
            }
            else
            {
                // block parent process until any of its children has finished.
                wait(NULL);
                // to tell child process to run until the next system call (enter or exit)
                // until the child process exits.
                ptrace(PTRACE_SYSCALL, pid, 0, 0);
                ptrace(PTRACE_CONT, pid, NULL, NULL);
            }

            return 0;
        }
        ```

    - compile

        ```bash
        $ aarch64-linux-gnu-gcc simple_trace.c -o simple_trace
        ```

    - put `simple_trace` to rootfs

+ Start Qemu with kernel
    > use `virt` machine

    ```
    # -S: Hold CPU and wait continue command of gdb
    # -s: 等同 "-gdb tcp::1234"
    $ qemu-system-aarch64 \
        -machine virt \
        -cpu cortex-a57 \
        -machine type=virt \
        -nographic -smp 1 \
        -m 2048 \
        -kernel ./arch/arm64/boot/Image \
        -initrd ../rootfs.img \
        --append "console=ttyAMA0" \
        -s -S
    ```

+ Start GDB

    ```
    $ arm-none-eabi-gdb ./vmlinux
        GNU gdb (GNU Tools for Arm Embedded Processors 8-2019-q3-update) 8.3.0.20190703-git
        Copyright (C) 2019 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-linux-gnu --target=arm-none-eabi".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word".
        Reading symbols from ./vmlinux...
        (gdb) set architecture aarch64
        (gdb) target remote localhost:1234
        Remote debugging using :1234
        0x00000000400000000 in ?? ()
        (gdb) c
        Continuing.
    ```

+ ARM kernel of Qemu

    - Get syscall server pointer of `sys_ptrace`

        ```
        # cat /proc/kallsyms | grep sys_ptrace
        0xffff80001008fea8 T __arm64_sys_ptrace
        0xffff800010090c90 T __arm64_compat_sys_ptrace
        ```

+ GDB set break point at `sys_ptrace`

    ```
    (gdb) b *0xffff80001008fea8
    (gdb) c
    ```

+ Execute App at ARM kernel of Qemu

    ```
    # simple_trace  <---- GDB client will break at "__arm64_sys_ptrace"
    ```

# reference

+ [gdb偵錯Qemu ARM64模擬平台上的Linux Kernel](http://www.prtos.org/gdb_qemu_arm64_linux_kernel/)

