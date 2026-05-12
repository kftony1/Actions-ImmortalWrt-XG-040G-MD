cd /mnt/d/Users/Admin/Desktop

cat > diy-part1.sh << 'EOF'
#!/bin/bash
#
# diy-part1.sh - XG-040G-MD 设备配置
#

echo "=========================================="
echo "XG-040G-MD 设备配置"
echo "=========================================="

cd openwrt

# ============================================
# 1. 删除所有冲突的复旦微补丁
# ============================================
echo "=== 删除冲突补丁 ==="
rm -f target/linux/generic/backport-6.12/435-v6.19-mtd-spinand-add-support-for-FudanMicro-FM25S01BI3.patch
rm -f target/linux/generic/backport-6.6/435-v6.19-mtd-spinand-add-support-for-FudanMicro-FM25S01BI3.patch
rm -f target/linux/generic/backport-6.12/640-spinand-add-fmsh-support.patch
rm -f target/linux/generic/backport-6.6/640-spinand-add-fmsh-support.patch
rm -f target/linux/generic/pending-6.12/641-mtd-spinand-add-fm25g02b.patch
rm -f target/linux/generic/pending-6.6/641-mtd-spinand-add-fm25g02b.patch
echo "✅ 冲突补丁已删除"

# ============================================
# 2. 直接修改 Makefile 添加 fmsh.o
# ============================================
echo "=== 修改 Makefile ==="
if ! grep -q "fmsh.o" drivers/mtd/nand/spi/Makefile 2>/dev/null; then
    sed -i 's/spinand-objs := core.o otp.o/spinand-objs := core.o fmsh.o otp.o/' drivers/mtd/nand/spi/Makefile
    echo "✅ Makefile 已修改"
fi

# ============================================
# 3. 修改 core.c 注册制造商
# ============================================
echo "=== 修改 core.c ==="
if ! grep -q "fmsh_spinand_manufacturer" drivers/mtd/nand/spi/core.c 2>/dev/null; then
    sed -i '/&xtx_spinand_manufacturer,/a\	&fmsh_spinand_manufacturer,' drivers/mtd/nand/spi/core.c
    echo "✅ core.c 已修改"
fi

# ============================================
# 4. 修改 spinand.h 添加声明
# ============================================
echo "=== 修改 spinand.h ==="
if ! grep -q "fmsh_spinand_manufacturer" include/linux/mtd/spinand.h 2>/dev/null; then
    sed -i '/extern const struct spinand_manufacturer xtx_spinand_manufacturer;/a extern const struct spinand_manufacturer fmsh_spinand_manufacturer;' include/linux/mtd/spinand.h
    echo "✅ spinand.h 已修改"
fi

# ============================================
# 5. 追加 FM25G02B 到现有的 fmsh.c
# ============================================
echo "=== 添加 FM25G02B 到 fmsh.c ==="

# 检查 fmsh.c 是否已存在
if [ -f drivers/mtd/nand/spi/fmsh.c ]; then
    # 检查是否已有 FM25G02B
    if ! grep -q "FM25G02B" drivers/mtd/nand/spi/fmsh.c; then
        # 在芯片列表末尾添加 FM25G02B
        sed -i '/static const struct spinand_info fmsh_spinand_table\[\] = {/,/};/ {
            /};/i\
	SPINAND_INFO("FM25G02B", 0xD2, SPINAND_HAS_QE_BIT, 64, 2048, 128, 64, 2048, 40, 1, 1, 1,\
		     SPINAND_ECCINFO(NULL, NULL))
        }' drivers/mtd/nand/spi/fmsh.c
        echo "✅ FM25G02B 已添加到 fmsh.c"
    else
        echo "✅ FM25G02B 已存在"
    fi
else
    echo "⚠️ fmsh.c 不存在，跳过"
fi

echo ""
echo "=========================================="
echo "✅ FM25G02B 驱动配置完成"
echo "=========================================="
EOF

echo "✅ diy-part1.sh 已更新"
