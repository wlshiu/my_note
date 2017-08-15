Linux Signal
---

    ```
              signal                                program_main
              trigger             (sigaction set)   interrupt position
                |                 sig_hanlder()         ^
    user        |                    ^      |           |
    ------------|--------------------|------|-----------|--
    kernel      |                    |      |           |
                V                    |      |           |
            do_signal() -------------+      +---> sys_sigreturn()
                        if user assign
                        customer's handler

    ```

+ sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
    > Map the `signum` to signal handler `act->sa_handler`

+ sigprocmask(int how, const sigset_t *new_set, sigset_t *old_set)
    > how : How to operate
    > - SIG_BLOCK
    >   > Add `new_set` signal types, and save the original set to `old_set`
    > - SIG_UNBLOCK
    >   > Delete `new_set` signal types, and save the original set to `old_set`
    > - SIG_SETMASK
    >   > Replace with `new_set` signal types, and save the original set to `old_set`

+ sigsuspend(const sigset_t *sigmask)
    1. Input the target signal type (sigmask)
    2. Replace `org_mask` with `sigmask` and pend thread
    3. Catch `sigmask` signal and enter the mapping sig_handler()
    4. Leave sig_handler() and *re-store* to `org_mask`
    5. Leave sigsuspend()
    6. Continous thread

+ int sigpending(sigset_t *sigmask);
    > Report `cur_set` to `singmask`
    >> You can find out which signals are pending at any time by calling `sigpending()`.

+ int sigemptyset(sigset_t *set);
    > set all flags to `0`
+ int sigfillset(sigset_t *set);
    > set all flags to `1`
+ int sigaddset(sigset_t *set, int signo);
    > pull flag high with `signo`
+ int sigdelset(sigset_t *set, int signo);
    > pull flag low with `signo`
+ int sigismember(sigset_t *set, int signo);
    > check flag is high or not




