#!/bin/bash
#
# diy-part1.sh - XG-040G-MD 设备配置
#

echo "=========================================="
echo "XG-040G-MD 设备配置验证"
echo "=========================================="

cd openwrt

echo "=== 检查复旦微补丁 ==="
if [ -f target/linux/generic/backport-6.12/342-mtd-spinand-Support-fmsh.patch.patch ]; then
    echo "✅ 复旦微补丁已找到"
    ls -la target/linux/generic/backport-6.12/342-mtd-spinand-Support-fmsh.patch.patch
else
    echo "⚠️ 警告: 复旦微补丁未找到"
fi

echo ""
echo "=== 检查设备树文件 ==="
if [ -f target/linux/airoha/dts/an7581-bell_xg-040g-md.dts ]; then
    echo "✅ 设备树文件已找到"
else
    echo "⚠️ 设备树文件未找到"
fi

echo ""
echo "=========================================="
echo "✅ 验证完成"
echo "=========================================="
