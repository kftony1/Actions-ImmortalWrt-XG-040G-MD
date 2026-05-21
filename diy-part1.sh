#!/bin/bash
#
# diy-part1.sh - XG-040G-MD 设备配置
#

echo "=========================================="
echo "XG-040G-MD 设备配置"
echo "=========================================="

# 注意：此时已经在 openwrt/ 目录下，不需要 cd
echo "当前目录: $(pwd)"

echo "=== 检查设备树文件 ==="
if [ -f target/linux/airoha/dts/an7581-bell_xg-040g-md.dts ]; then
    echo "✅ 设备树文件已找到"
else
    echo "⚠️ 警告: 设备树文件未找到"
    echo "target/linux/airoha/dts/ 目录内容:"
    ls -la target/linux/airoha/dts/ 2>/dev/null || echo "目录不存在"
fi

echo ""
echo "=== 检查补丁文件 ==="
# 静默清理损坏的补丁
find target/linux/airoha/patches-6.12/ -name "*.patch" -size -100c 2>/dev/null | while read patch; do
    mv "$patch" "${patch}.disabled" 2>/dev/null
done

PATCH_COUNT=$(find target/linux/airoha/patches-6.12/ -name "*.patch" ! -name "*.disabled" 2>/dev/null | wc -l)
echo "✅ 发现 $PATCH_COUNT 个有效补丁"

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
