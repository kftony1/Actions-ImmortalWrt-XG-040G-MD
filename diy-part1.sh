#!/bin/bash
#
# diy-part1.sh - XG-040G-MD 设备配置验证
#

echo "=========================================="
echo "XG-040G-MD 设备配置验证"
echo "=========================================="

# 注意：此时已经在 openwrt/ 目录下，不需要 cd
echo "当前目录: $(pwd)"

echo "=== 检查设备树文件 ==="
if [ -f target/linux/airoha/dts/an7581-bell_xg-040g-md.dts ]; then
    echo "✅ 设备树文件已找到"
    echo "复旦微闪存修复验证:"
    grep -E "disabled|afe|FM25" target/linux/airoha/dts/an7581-bell_xg-040g-md.dts 2>/dev/null | head -3 || echo "未找到复旦微相关配置"
else
    echo "⚠️ 警告: 设备树文件未找到"
    echo "target/linux/airoha/dts/ 目录内容:"
    ls -la target/linux/airoha/dts/ 2>/dev/null || echo "目录不存在"
fi

echo ""
echo "=== 检查补丁文件 ==="
if ls target/linux/airoha/patches-6.12/*.patch 2>/dev/null; then
    echo "✅ 补丁文件已找到"
    if [ -f target/linux/airoha/patches-6.12/100-mtd-spinand-add-fmsh-fm25g02b-support.patch ]; then
        echo "✅ 复旦微闪存补丁已找到"
    fi
else
    echo "⚠️ 警告: 补丁目录为空或不存在"
fi

echo ""
echo "=== 检查自定义配置 ==="
if [ -d files ]; then
    echo "✅ files 目录已存在"
    echo "files 目录文件数: $(find files -type f 2>/dev/null | wc -l)"
else
    echo "⚠️ 警告: files 目录未找到"
fi

echo ""
echo "=========================================="
echo "✅ diy-part1.sh 执行完成"
echo "=========================================="
