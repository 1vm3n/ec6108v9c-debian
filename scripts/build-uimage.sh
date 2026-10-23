#!/bin/bash
# build-uimage.sh -- 把 zImage + 板级 DTB 打包成 U-Boot uImage
#
# 用法：
#   SRC=~/linux-mv100 ./build-uimage.sh
#
# 输出：OUT/uImage-ec6108v9c（zImage 后面追加 DTB，bootm 加载）
set -euo pipefail

SRC=${SRC:-$PWD/linux-mv100}
OUT=${OUT:-$PWD/out}
DTB_NAME=${DTB_NAME:-hi3798mv100-ec6108v9c.dtb}

ZIMAGE="$SRC/arch/arm/boot/zImage"
DTB="$SRC/arch/arm/boot/dts/hisilicon/$DTB_NAME"

[ -f "$ZIMAGE" ] || { echo "缺少 $ZIMAGE"; exit 1; }
[ -f "$DTB" ]    || { echo "缺少 $DTB"; exit 1; }
command -v mkimage >/dev/null || { echo "缺少 mkimage：apt install u-boot-tools"; exit 1; }

mkdir -p "$OUT"
cat "$ZIMAGE" "$DTB" > "$OUT/zImage-dtb"

mkimage -A arm -O linux -T kernel -C none \
        -a 0x2000000 -e 0x2000000 -n linux \
        -d "$OUT/zImage-dtb" "$OUT/uImage-ec6108v9c"

echo
ls -l "$ZIMAGE" "$DTB" "$OUT/uImage-ec6108v9c"
md5sum "$OUT/uImage-ec6108v9c"
