#!/bin/bash
echo "=========================================="
echo "开始执行 diy-part2.sh"
echo "=========================================="

cd $GITHUB_WORKSPACE/openwrt

# 删除源码中的 uci-defaults（避免覆盖你的自定义配置）
rm -rf package/base-files/files/etc/uci-defaults

# 删除源码中生成随机 MAC 的脚本
find package/base-files -name "*.sh" -exec grep -l "generate_mac\|random.*mac\|dd.*urandom" {} \; -delete

echo ""
echo "=========================================="
echo "✅ diy-part2.sh 执行完成"
echo "=========================================="
