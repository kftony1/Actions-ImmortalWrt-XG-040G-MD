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

# 删除设备包中的 uci-defaults（避免覆盖自定义配置）
rm -rf package/base-files/files/etc/uci-defaults

# 删除所有生成随机 MAC 的脚本
find package/base-files -name "*.sh" -exec grep -l "generate_mac\|random.*mac\|dd.*urandom" {} \; -delete

# 复制自定义文件到 OpenWrt 源码根目录的 files 文件夹
if [ -d $GITHUB_WORKSPACE/files ]; then
    # 确保目标目录存在
    mkdir -p files
    
    # 复制文件夹内的内容（注意：不是复制文件夹本身）
    cp -rf $GITHUB_WORKSPACE/files/* files/
    
    # 清理 network 配置中自动生成的 _mac_fix 段
    sed -i '/config device .*_mac_fix/,/^$/d' files/etc/config/network
    
    echo "✅ 自定义文件已复制到 ./files/"
    echo "目录结构："
    ls -la files/
    echo "etc/config 内容："
    ls -la files/etc/config/ 2>/dev/null || echo "⚠️ 没有 etc/config 目录"
    
    # 验证 network 配置
    if [ -f files/etc/config/network ]; then
        echo "✅ network 配置存在，IP 地址："
        grep "ipaddr" files/etc/config/network
        echo "✅ MAC 地址："
        grep "macaddr" files/etc/config/network
    else
        echo "⚠️ 未找到 network 配置文件"
    fi
else
    echo "⚠️ 未找到自定义文件夹: $GITHUB_WORKSPACE/files"
fi

echo ""
echo "✅ diy-part2.sh 执行完成"
