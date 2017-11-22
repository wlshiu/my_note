#!/bin/sh


# enable register
chmod 777 /sys/crt/register && echo 0x1234abcd > /sys/crt/register && echo 0xb406aa04 > /sys/crt/register  && cat /sys/crt/register
# check response: reg addr = 0xb406aa04 , val = 0x00000000

if [ ! -e /mnt/sda1/watchdog ]; then
    echo -e "\nno /mnt/sda1/watchdog\n"
    exit 1
fi

cp /mnt/sda1/watchdog /home
/home/watchdog
# check response: [enable_watchdog] Disable watchdog success !

# disable register
chmod 777 /sys/crt/register && echo 0x1234abcd > /sys/crt/register && echo 0xb406aa04 > /sys/crt/register  && cat /sys/crt/register
# check response: reg addr = 0xb406aa04 , val = 0x000000A5

ps -a | grep Application

echo -e "\nNeed to stop signal: handle SIG33 SIG53 SIGUSR2 SIGCHLD nostop noprint\n"

