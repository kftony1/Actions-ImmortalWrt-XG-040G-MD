cd /mnt/d/Users/Admin/Desktop/OpenWrt/XG-040G-MD && cat > diy-part2.sh << 'EOF'
#!/bin/bash
#
# diy-part2.sh - XG-040G-MD 配置修改
#

echo "=========================================="
echo "开始执行 diy-part2.sh"
echo "=========================================="

# 注意：此时已经在 openwrt/ 目录下，不需要 cd
echo "当前目录: $(pwd)"

# 1. 清理冲突文件
echo ""
echo "=== 1. 清理冲突文件 ==="
# 删除源码中的 uci-defaults（避免覆盖你的自定义配置）
rm -rf package/base-files/files/etc/uci-defaults
# 删除源码中生成随机 MAC 的脚本
find package/base-files -name "*.sh" -exec grep -l "generate_mac\|random.*mac\|dd.*urandom" {} \; -delete 2>/dev/null
echo "✅ 清理完成"

# 2. 添加性能优化配置（如果 files 目录中没有）
echo ""
echo "=== 2. 添加性能优化配置 ==="
if [ ! -f files/etc/sysctl.d/99-xg040g-md.conf ]; then
    mkdir -p files/etc/sysctl.d
    cat > files/etc/sysctl.d/99-xg040g-md.conf << 'INNEREOF'
# XG-040G-MD 性能优化
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.netfilter.nf_conntrack_max = 65535
INNEREOF
    echo "✅ 已添加性能优化配置"
else
    echo "✅ 性能优化配置已存在"
fi

# 3. 强制添加 Airoha 驱动配置
echo ""
echo "=== 3. 强制添加 Airoha 驱动配置 ==="
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
EOF

chmod +x diy-part2.sh && echo "✅ diy-part2.sh 已更新（已移除 USB 网络支持）"
