#!/bin/bash
# flash-usb.sh -- 把 uImage 写到启动 U 盘的 FAT 分区
#
# 用法：
#   sudo ./flash-usb.sh /path/to/uImage-ec6108v9c
#   DEV=/dev/sdb1 ./flash-usb.sh ...
#
# 厂商 fastboot 会依次尝试若干文件名，所以同一个镜像写三份。
set -euo pipefail

IMG=${1:?用法: $0 <uImage 文件>}
DEV=${DEV:-/dev/sda1}
MNT=${MNT:-/mnt/usbboot}
NAMES=${NAMES:-"recovery.img boot1.img DEBIAN.IMG"}

[ -f "$IMG" ] || { echo "找不到 $IMG"; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "需要 root"; exit 1; }

mkdir -p "$MNT"
mountpoint -q "$MNT" || mount -t vfat "$DEV" "$MNT"
trap 'umount "$MNT" 2>/dev/null || true' EXIT

echo ">>> 目标：$DEV -> $MNT"
ls -l "$MNT" | head -20

for n in $NAMES; do
    cp -f "$IMG" "$MNT/$n"
    cmp -s "$IMG" "$MNT/$n" && echo "  ✔ $n" || { echo "  ✘ $n 校验失败"; exit 1; }
done
sync
echo ">>> 完成，可以拔盘"
