#!/bin/bash
echo "=========================================="
echo "开始执行 diy-part2.sh"
echo "=========================================="

cd $GITHUB_WORKSPACE/openwrt

# 1. 清理冲突文件
echo ""
echo "=== 1. 清理冲突文件 ==="
rm -rf package/base-files/files/etc/uci-defaults
find package/base-files -name "*.sh" -exec grep -l "generate_mac\|random.*mac\|dd.*urandom" {} \; -delete
echo "✅ 清理完成"

# 2. 强制添加 Airoha 驱动配置
echo ""
echo "=== 2. 强制添加 Airoha 驱动配置 ==="

# 确保这些配置存在
for config in \
    "CONFIG_PACKAGE_kmod-airoha-eth=y" \
    "CONFIG_PACKAGE_kmod-airoha-switch=y" \
    "CONFIG_PACKAGE_kmod-airoha-npu=y" \
    "CONFIG_PACKAGE_kmod-phy-airoha-en8811h=y" \
    "CONFIG_PACKAGE_airoha-en8811h-firmware=y" \
    "CONFIG_PACKAGE_airoha-en7581-npu-firmware=y" \
    "CONFIG_PACKAGE_kmod-i2c-an7581=y" \
    "CONFIG_AIROHA_ETH=y"
do
    if ! grep -q "^$config$" .config 2>/dev/null; then
        echo "$config" >> .config
        echo "✅ 已添加: $config"
    else
        echo "✅ 已存在: $config"
    fi
done

echo ""
echo "=========================================="
echo "✅ diy-part2.sh 执行完成"
echo "=========================================="
