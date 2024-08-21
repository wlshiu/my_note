#!/bin/bash

udev_info=$HOME/.___udev_attr

ls --color=never /sys/bus/usb-serial/devices/ | \
    xargs  echo /sys/bus/usb-serial/devices/ | \
    sed 's/[[:space:]]//g' | sed 's/$/\//' | \
    xargs udevadm info -a -p > ${udev_info}



grep -A4 'looking at devices*' ${udev_info}

rm -f ${udev_info}

