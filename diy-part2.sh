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

cd openwrt

# ============================================
# 1. 删除设备包中的 uci-defaults（避免覆盖自定义配置）
# ============================================
rm -rf package/base-files/files/etc/uci-defaults

# ============================================
# 2. 删除所有生成随机 MAC 的脚本
# ============================================
find package/base-files -name "*.sh" -exec grep -l "generate_mac\|random.*mac\|dd.*urandom" {} \; -delete

# ============================================
# 3. 强制固定 MAC 地址（解决驱动生成随机 MAC 的问题）
# ============================================
# 你的 MAC 地址（根据配置文件）
ETH0_MAC="50:3d:7f:7b:cb:ec"
ETH1_MAC="50:3d:7f:7b:cb:ed"

echo "设置固定 MAC 地址: eth0=$ETH0_MAC, eth1=$ETH1_MAC"

# 方法 1：创建 preinit 脚本（在网络启动前执行）
mkdir -p files/etc/preinit
cat > files/etc/preinit/fixmac << 'EOF'
#!/bin/sh
# 在 preinit 阶段强制设置 MAC 地址
sleep 1
ip link set dev eth0 address 50:3d:7f:7b:cb:ec 2>/dev/null
ip link set dev eth1 address 50:3d:7f:7b:cb:ed 2>/dev/null
EOF
chmod +x files/etc/preinit/fixmac

# 方法 2：创建 hotplug 脚本（网络设备添加时触发）
mkdir -p files/etc/hotplug.d/net
cat > files/etc/hotplug.d/net/99-fixmac << 'EOF'
#!/bin/sh
[ "$ACTION" = "add" ] && [ "$INTERFACE" = "eth0" ] && {
    ip link set dev eth0 address 50:3d:7f:7b:cb:ec
}
[ "$ACTION" = "add" ] && [ "$INTERFACE" = "eth1" ] && {
    ip link set dev eth1 address 50:3d:7f:7b:cb:ed
}
EOF
chmod +x files/etc/hotplug.d/net/99-fixmac

# 方法 3：创建 init.d 脚本（系统启动时执行）
mkdir -p files/etc/init.d
cat > files/etc/init.d/fixmac << 'EOF'
#!/bin/sh /etc/rc.common
START=01
STOP=99

start() {
    ip link set dev eth0 address 50:3d:7f:7b:cb:ec 2>/dev/null
    ip link set dev eth1 address 50:3d:7f:7b:cb:ed 2>/dev/null
    logger -t fixmac "MAC addresses fixed"
}
EOF
chmod +x files/etc/init.d/fixmac

# ============================================
# 4. 复制自定义文件
# ============================================
if [ -d $GITHUB_WORKSPACE/files ]; then
    mkdir -p files
    cp -rf $GITHUB_WORKSPACE/files/* files/
    
    # 清理 network 配置中自动生成的 _mac_fix 段
    if [ -f files/etc/config/network ]; then
        sed -i '/config device .*_mac_fix/,/^$/d' files/etc/config/network
    fi
    
    echo "✅ 自定义文件已复制到 ./files/"
else
    echo "⚠️ 未找到自定义文件夹: $GITHUB_WORKSPACE/files"
fi

echo ""
echo "=========================================="
echo "✅ diy-part2.sh 执行完成"
echo "=========================================="
