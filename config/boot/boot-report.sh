#!/bin/sh
# boot-report.sh -- append late-boot telemetry to the U-disk FAT.
# Called by boot-report.service and boot-report-late.service.
# Takes one argument used as a section label.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

LABEL="$1"
mkdir -p /mnt/uboot

FAT_DEV=""
for d in /dev/sda1 /dev/sdb1 /dev/sdc1; do
    [ -b "$d" ] || continue
    if mountpoint -q /mnt/uboot; then FAT_DEV="already-mounted"; break; fi
    if mount -t vfat -o rw,umask=000 "$d" /mnt/uboot 2>/dev/null; then
        FAT_DEV="$d"
        break
    fi
done

[ -n "$FAT_DEV" ] || exit 0

LOG=/mnt/uboot/BOOTREPORT.TXT

{
    echo ""
    echo "=================================================================="
    echo "=== USERSPACE REPORT: $LABEL -- $(date -u "+%Y-%m-%dT%H:%M:%SZ")"
    echo "=================================================================="
    echo "--- uname: $(uname -a)"
    echo "--- uptime: $(cat /proc/uptime)"
    echo "--- cmdline: $(cat /proc/cmdline)"
    echo "--- command: ip -br link"
    ip -br link 2>&1
    echo "--- command: ip -br addr"
    ip -br addr 2>&1
    echo "--- command: ip route"
    ip route 2>&1
    echo "--- /proc/net/dev:"
    cat /proc/net/dev
    echo "--- /proc/mounts:"
    cat /proc/mounts
    echo "--- command: lsblk"
    lsblk 2>&1
    echo "--- command: lsmod"
    lsmod 2>&1
    echo "--- /proc/fb:"
    cat /proc/fb 2>&1
    echo "--- /sys/class/graphics:"
    ls -l /sys/class/graphics 2>&1
    echo "--- /sys/class/drm (status):"
    for f in /sys/class/drm/*/status; do [ -e "$f" ] && echo "$f: $(cat "$f")"; done 2>&1
    echo "--- /dev/fb* /dev/dri:"
    ls -l /dev/fb* /dev/dri 2>&1
    echo "--- command: systemctl --failed"
    systemctl --failed --no-pager 2>&1
    echo "--- command: systemctl --no-pager --type=service --state=running"
    systemctl --no-pager --type=service --state=running 2>&1
    echo "--- command: systemctl status networking --no-pager"
    systemctl status networking --no-pager 2>&1
    echo "--- command: journalctl -b -n 120 --no-pager"
    journalctl -b -n 120 --no-pager 2>&1
    echo "--- dmesg tail -n 200:"
    dmesg 2>&1 | tail -n 200
    echo "=== END USERSACE REPORT: $LABEL"
} >> "$LOG" 2>&1

sync
mountpoint -q /mnt/uboot && umount /mnt/uboot 2>/dev/null
exit 0
