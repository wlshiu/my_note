/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014-2018, Erik Moqvist
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * This file is part of the Simba project.
 */

#ifndef __KERNEL_TIME_H__
#define __KERNEL_TIME_H__

#include "simba.h"

/**
 * A time in seconds and nanoseconds. ``seconds`` and ``nanoseconds``
 * shall be added to get the time.
 */
struct time_t {
    /** Number of seconds. */
    int32_t seconds;
    /** Number of nanoseconds. */
    int32_t nanoseconds;
};

/**
 * A date in year, month, date, day, hour, minute and seconds.
 */
struct date_t {
    /** Second [0..59]. */
    int second;
    /** Minute [0..59]. */
    int minute;
    /** Hour [0..23]. */
    int hour;
    /** Weekday [1..7], where 1 is Monday and 7 is Sunday. */
    int day;
    /** Day in month [1..31] */
    int date;
    /** Month [1..12] where 1 is January and 12 is December. */
    int month;
    /** Year [1970..]. */
    int year;
};

/**
 * A comparsion result.
 */
enum time_compare_t {
    time_compare_less_than_t = 0,
    time_compare_equal_t = 1,
    time_compare_greater_than_t = 2
};

/**
 * Get current time in seconds and nanoseconds. The resolution of the
 * time is implementation specific and may vary a lot between
 * different architectures.
 *
 * @param[out] now_p Read current time.
 *
 * @return zero(0) or negative error code.
 */
int time_get(struct time_t *now_p);

/**
 * Set current time in seconds and nanoseconds.
 *
 * @param[in] new_p New current time.
 *
 * @return zero(0) or negative error code.
 */
int time_set(struct time_t *new_p);

/**
 * Add given times.
 *
 * @param[out] res_p The result of the adding ``left_p`` to
 *                   ``right_p``.
 * @param[in] left_p First operand.
 * @param[in] right_p Second operand.
 *
 * @return zero(0) or negative error code.
 */
int time_add(struct time_t *res_p,
             struct time_t *left_p,
             struct time_t *right_p);

/**
 * Subtract given times.
 *
 * @param[out] res_p The result of the subtrancting ``left_p`` from
 *                   ``right_p``.
 * @param[in] left_p The operand to subtract from.
 * @param[in] right_p The operand to subtract.
 *
 * @return zero(0) or negative error code.
 */
int time_subtract(struct time_t *res_p,
                  struct time_t *left_p,
                  struct time_t *right_p);

/**
 * Compare given times and return their relationship as `less than`,
 * `equal`, or `greater than`.
 *
 * @param[in] left_p First time to compare.
 * @param[in] right_p Second time to compare.
 *
 * @return The result of the comparsion.
 */
enum time_compare_t time_compare(struct time_t *left_p,
                                 struct time_t *right_p);

/**
 * Convert given unix time to a date.
 *
 * @param[out] date_p Converted time.
 * @param[in] time_p Unix time to convert.
 *
 * @return zero(0) or negative error code or negative error code.
 */
int time_unix_time_to_date(struct date_t *date_p,
                           struct time_t *time_p);

/**
 * Busy wait for given number of microseconds.
 *
 * This function may be called from interrupt context and with the
 * system lock taken.
 *
 * NOTE: The maximum allowed time to sleep is target specific.
 *
 * @param[in] useconds Microseconds to busy wait.
 *
 * @return void
 */
void time_busy_wait_us(int microseconds);

/**
 * Get current time in microseconds. Use `time_micros_resolution()`
 * and `time_micros_maximum()` to get its properties, and
 * `time_micros_elapsed()` to calculate the elapsed time between two
 * times.
 *
 * This function may be called from interrupt context and with the
 * system lock taken.
 *
 * @return Current time in microseconds.
 */
int time_micros(void);

/**
 * Calculate the elapsed time from start to stop. The caller must
 * ensure that the micro timer has not wrapped more than once for this
 * calculation to work.
 *
 * This function may be called from interrupt context and with the
 * system lock taken.
 *
 * @return The elapsed time from start to stop.
 */
int time_micros_elapsed(int start, int stop);

/**
 * Get micros resolution in microseconds, rounded up.
 *
 * This function may be called from interrupt context and with the
 * system lock taken.
 *
 * @return Resolution in microseconds or negative error code.
 */
int time_micros_resolution(void);

/**
 * Get micros maximum value plus one, often the system tick period.
 *
 * This function may be called from interrupt context and with the
 * system lock taken.
 *
 * @return Maximum value plus one in microseconds or negative error
 *         code. Returns -ENOSYS if the the micro functionality is
 *         unimplemented on this board.
 */
int time_micros_maximum(void);

#endif
