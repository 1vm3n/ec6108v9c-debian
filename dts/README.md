# 设备树

`hi3798mv100-ec6108v9c.dts` 是应用到 **histb-mainline/linux `mv100` 分支**的板级设备树（完整文件，可直接覆盖同名文件）。

## 补丁说明

| 补丁 | 作用 | 效果 |
|---|---|---|
| `0001-arm-dts-ec6108v9c-emmc-8bit.patch` | `&emmc` 增加 `bus-width = <8>` 与 pinctrl | 2.0 → 44.9 MB/s |
| `0002-arm-dts-ec6108v9c-sd-4bit.patch` | `&sd` 增加 `bus-width = <4>` / `cap-sd-highspeed` | ~2 → 23.4 MB/s |

两个补丁按顺序应用：

```bash
cd arch/arm/boot/dts/hisilicon
patch -p1 < 0001-....patch
patch -p1 < 0002-....patch
```

## 为什么要显式写 bus-width

内核 `mmc_of_parse()` 在缺少 `bus-width` 时按 **1 bit** 处理，随后 `mmc_validate_host_caps()` 会打印：

```
drop UHS/DDR/HS200 support since 1-bit bus only
```

从而禁用高速模式。1-bit @ 50 MHz 的理论上限只有 6.25 MB/s，实测 2 MB/s。

## 为什么不开 1.8 V 模式

板子只有 12 V 输入、没有可切换的 VCCQ 回路（DTS 里也没有 `vqmmc-supply`）。盲目声明 `mmc-hs200-1_8v` / `mmc-ddr-1_8v` 有掉盘风险，所以只在 3.3 V 下跑 HS：

- eMMC：8-bit × 50 MHz = 理论 50 MB/s，实测 44.9
- SD：4-bit × 50 MHz = 理论 25 MB/s，实测 23.4

两者都已接近上限。
