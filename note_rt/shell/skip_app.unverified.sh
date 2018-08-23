# must use \n\r to make terminal execute 
cat  /proc/sys/kernel/printk
echo 0 > /proc/sys/kernel/printk
mount -o rw,remount /
sync
ls -l /usr/local/etc/dvdplayer/
echo 123 > /usr/local/etc/dvdplayer/gdb
echo 123 > /usr/local/etc/dvdplayer/noap
ls -l /usr/local/etc/dvdplayer/
sync