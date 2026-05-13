#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

echo "=========================================="
echo "开始执行 diy-part2.sh"
echo "=========================================="

cd $GITHUB_WORKSPACE/openwrt

# ============================================
# 1. 删除设备包中的 uci-defaults（避免覆盖自定义配置）
# ============================================
rm -rf package/base-files/files/etc/uci-defaults

# ============================================
# 2. 删除所有生成随机 MAC 的脚本
# ============================================
find package/base-files -name "*.sh" -exec grep -l "generate_mac\|random.*mac\|dd.*urandom" {} \; -delete

# ============================================
# 3. 创建 init.d 脚本固定 MAC 地址
# ============================================
ETH0_MAC="50:3d:7f:7b:cb:ec"
ETH1_MAC="50:3d:7f:7b:cb:ed"

mkdir -p files/etc/init.d
cat > files/etc/init.d/fixmac << EOF
#!/bin/sh /etc/rc.common
START=01

start() {
    ip link set dev eth0 address $ETH0_MAC 2>/dev/null
    ip link set dev eth1 address $ETH1_MAC 2>/dev/null
    logger -t fixmac "MAC addresses fixed"
}
EOF
chmod +x files/etc/init.d/fixmac

# ============================================
# 4. 复制自定义文件（如果存在）
# ============================================
if [ -d $GITHUB_WORKSPACE/files ]; then
    cp -rf $GITHUB_WORKSPACE/files/* files/ 2>/dev/null
    echo "✅ 自定义文件已复制"
fi

echo ""
echo "=========================================="
echo "✅ diy-part2.sh 执行完成"
echo "=========================================="
