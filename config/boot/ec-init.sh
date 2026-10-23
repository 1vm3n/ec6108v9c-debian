#!/bin/sh
# ec-init.sh -- PID 1 wrapper for the EC6108V9C Debian 13 test boot.
#
# Selected with "init=/usr/local/sbin/ec-init.sh" on the kernel cmdline.
# It writes the kernel/early-userspace state to the U-disk FAT (BOOTREPORT.TXT)
# and THEN execs systemd, which becomes PID 1 exactly as normal.
#
# Safety: if this file is missing the kernel falls back to /sbin/init, and if it
# fails at any point the "exec /sbin/init" at the bottom still runs. It cannot brick.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

mount -t proc     proc     /proc     2>/dev/null
mount -t sysfs    sysfs    /sys      2>/dev/null
mount -t devtmpfs devtmpfs /dev      2>/dev/null
mkdir -p /dev/pts /dev/shm /mnt/uboot
mount -t devpts   devpts   /dev/pts  2>/dev/null
mount -t tmpfs    tmpfs    /dev/shm  2>/dev/null

FAT_DEV=""
for d in /dev/sda1 /dev/sdb1 /dev/sdc1; do
    [ -b "$d" ] || continue
    if mount -t vfat -o rw,umask=000 "$d" /mnt/uboot 2>/dev/null; then
        FAT_DEV="$d"
        break
    fi
done

LOG=/mnt/uboot/BOOTREPORT.TXT

if [ -n "$FAT_DEV" ]; then
    {
        echo ""
        echo "################################################################"
        echo "### PID1 REPORT -- ec-init.sh -- $(date -u "+%Y-%m-%dT%H:%M:%SZ")"
        echo "### (this file is appended to on every boot)"
        echo "################################################################"
        echo "--- mounted FAT: $FAT_DEV"
        echo "--- uname: $(uname -a)"
        echo "--- uptime(proc): $(cat /proc/uptime)"
        echo "--- cmdline: $(cat /proc/cmdline)"
        echo "--- /proc/partitions:"
        cat /proc/partitions
        echo "--- /proc/mounts:"
        cat /proc/mounts
        echo "--- blkid:"
        blkid 2>&1
        echo "--- dmesg (full):"
        dmesg
        echo "### END PID1 REPORT"
    } >> "$LOG" 2>&1
    sync
    umount /mnt/uboot 2>/dev/null
else
    # No FAT reachable: still leave a trace on the root fs so late boot can see it.
    echo "ec-init: no vfat device could be mounted at /mnt/uboot at $(date -u)" \
        >> /ec-init.no-vfat 2>/dev/null
fi

echo "ec-init: handing over to /sbin/init"
exec /sbin/init
