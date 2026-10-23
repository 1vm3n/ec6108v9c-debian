# EC6108V9C → Debian 13

把华为 EC6108V9C（ CA 版，Hi3798MV100）IPTV 机顶盒改造成一台 Debian 13 armhf 小服务器的记录、补丁与脚本。

本仓库**只包含**设备树补丁、构建脚本、服务配置和踩坑记录，**不包含**任何厂商固件或二进制。

---

## 硬件

| 项 | 规格 |
|---|---|
| SoC | HiSilicon **Hi3798MV100**，4× Cortex-A7（ARMv7，NEON/VFPv4） |
| 内存 | 1 GB DDR3（内核可用 970 MiB） |
| 存储 | 8 GB eMMC（Hynix H8G4a），原厂 16 分区 |
| 网络 | 10/100 Mbps 以太网（实测 93.5 Mbps） |
| 显示 | HDMI，mainline `histb` DRM 驱动 |
| 供电 | 12 V 单电源，**无 1.8 V 切换**、无温度传感器、无 DVFS |

## 最终效果

| 指标 | 原厂 / 未修复 | 本项目 |
|---|---|---|
| eMMC 顺序读 | 2.0 MB/s | **44.9 MB/s** |
| eMMC 顺序写 | 2.1 MB/s | **29.0 MB/s** |
| SD 卡顺序读 | ~2 MB/s | **23.4 MB/s** |
| 冷启动 | 34 s | **14.5 s** |
| 交换 | 无 | zram 485 MB（lzo-rle） |
| 系统 | Android / IPTV | Debian 13.7 trixie armhf |

## 四个关键修复

| 问题 | 根因 | 修复 |
|---|---|---|
| eMMC 只有 2 MB/s | 板级 DTS 缺 `bus-width`，内核按 1-bit 初始化 | [0001](dts/patches/0001-arm-dts-ec6108v9c-emmc-8bit.patch) |
| SD 槽只有 2 MB/s | 同上，1-bit + 默认 25 MHz | [0002](dts/patches/0002-arm-dts-ec6108v9c-sd-4bit.patch) |
| 开机 34 秒 | `boot-report-late.service` 里 `sleep 20` 且挂在启动事务上 | 改成 timer 触发 |
| 1 GB 内存无交换 | 内核未开 `CONFIG_ZRAM` | 重编内核 + systemd-zram-generator |

详见 [docs/02-性能与踩坑.md](docs/02-性能与踩坑.md)。

## 目录

```
dts/            板级设备树 + 两个补丁
scripts/        打包 uImage、刷写 U 盘、配置同步
config/         systemd / zram / nginx / sshd 配置
docs/           硬件与启动链说明、性能实测与踩坑记录
```

## 构建

依赖：`arm-linux-gnu-gcc`、`mkimage`（u-boot-tools）、`dtc`。

内核源码来自 [histb-mainline/linux](https://github.com/histb-mainline/linux) 的 `mv100` 分支（本项目验证于 7.3.0-rc6）。

```bash
# 1. 源码树里应用设备树补丁
cd linux-mv100
git apply /path/to/dts/patches/0001-*.patch 0002-*.patch

# 2. 编译
make ARCH=arm CROSS_COMPILE=arm-linux-gnu- zImage hisilicon/hi3798mv100-ec6108v9c.dtb

# 3. 打包（zImage + 追加 DTB → uImage）
./scripts/build-uimage.sh
```

## 刷写

这台机器的启动链是**厂商签名 fastboot**，从 U 盘 FAT 分区加载 uImage（文件名 `recovery.img` / `boot1.img` / `DEBIAN.IMG` 都试）。高安版还需短接 J16 才能进恢复模式。

```bash
./scripts/flash-usb.sh /path/to/uImage
```

> 仓库不提供 `fastboot.bin` 和分区备份，请从你自己的机器上 dump。

## 不包含的内容

- ❌ 厂商签名固件（`fastboot.bin`、`p1/p2/p3` 分区 dump）——版权与签名材料
- ❌ 编译好的内核 / 根文件系统镜像
- ❌ 内核源码树（请从上游拉取）

## 许可

- 设备树与脚本：**GPL-2.0**（与内核一致，见 [LICENSE](LICENSE)）
- 文档：CC BY-SA 4.0

> 分发内核二进制属于 GPL-2.0 覆盖行为，请同时提供对应源码或指向本仓库的补丁。
