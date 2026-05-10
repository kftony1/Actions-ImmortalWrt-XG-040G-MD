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

# 复制自定义文件到编译目录
if [ -d $GITHUB_WORKSPACE/files ]; then
    cp -rf $GITHUB_WORKSPACE/files .
    echo "✅ 自定义文件夹已复制"
    ls -la files/
else
    echo "⚠️ 未找到自定义文件夹: $GITHUB_WORKSPACE/files"
fi
