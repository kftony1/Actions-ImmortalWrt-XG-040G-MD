#!/bin/bash
#
# diy-part1.sh - XG-040G-MD 设备配置（补丁来自压缩包）
#

echo "=========================================="
echo "XG-040G-MD 设备补丁验证"
echo "=========================================="

cd openwrt

# 复旦微补丁（支持 FM25G02B 和 FM25S01BI3）
echo "=== 检查复旦微补丁 ==="
if [ -f target/linux/generic/pending-6.12/641-mtd-spinand-add-fm25g02b.patch ]; then
    echo "✅ 复旦微 FM25G02B 补丁已找到"
    ls -la target/linux/generic/pending-6.12/641-mtd-spinand-add-fm25g02b.patch
elif [ -f target/linux/generic/backport-6.12/435-v6.19-mtd-spinand-add-support-for-FudanMicro-FM25S01BI3.patch ]; then
    echo "✅ 复旦微 FM25S01BI3 补丁已找到"
    ls -la target/linux/generic/backport-6.12/435-v6.19-mtd-spinand-add-support-for-FudanMicro-FM25S01BI3.patch
else
    echo "⚠️ 警告: 复旦微补丁未找到"
    echo "请检查 XG-040G-MD.tar.gz 是否正确解压"
fi

echo ""
echo "=== 检查设备树文件 ==="
if [ -f target/linux/airoha/dts/an7581-bell_xg-040g-md.dts ]; then
    echo "✅ 设备树文件已找到"
else
    echo "⚠️ 设备树文件未找到"
fi

echo ""
echo "=== 检查内核版本 ==="
if [ -f include/kernel-version.mk ]; then
    grep "LINUX_VERSION" include/kernel-version.mk | head -3
else
    echo "无法确定内核版本"
fi

echo ""
echo "=========================================="
echo "✅ XG-040G-MD 设备配置验证完成"
echo "=========================================="
