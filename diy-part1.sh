#!/bin/bash
#
# diy-part1.sh - XG-040G-MD 设备配置验证
#

echo "=========================================="
echo "XG-040G-MD 设备配置验证"
echo "=========================================="

cd $GITHUB_WORKSPACE/openwrt

echo "=== 检查设备树文件 ==="
if [ -f target/linux/airoha/dts/an7581-bell_xg-040g-md.dts ]; then
    echo "✅ 设备树文件已找到"
else
    echo "⚠️ 警告: 设备树文件未找到"
fi

echo ""
echo "=== 检查自定义配置 ==="
if [ -d files ]; then
    echo "✅ files 目录已存在"
else
    echo "⚠️ 警告: files 目录未找到"
fi

echo ""
echo "=========================================="
echo "✅ 验证完成"
echo "=========================================="
