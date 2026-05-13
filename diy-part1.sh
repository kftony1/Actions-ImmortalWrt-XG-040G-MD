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
rm -f target/linux/generic/pending-6.12/342-mtd-spinand-Support-fmsh.patch
rm -f target/linux/generic/pending-6.6/342-mtd-spinand-Support-fmsh.patch
rm -f target/linux/generic/backport-6.12/640-spinand-add-fmsh-support.patch
rm -f target/linux/generic/backport-6.6/640-spinand-add-fmsh-support.patch
echo "✅ 冲突补丁已删除"

# ============================================
# 2. 直接写入 fmsh.c 文件
# ============================================
echo "=== 写入 fmsh.c 驱动 ==="

mkdir -p drivers/mtd/nand/spi

cat > drivers/mtd/nand/spi/fmsh.c << 'FMSH_EOF'
// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (c) 2021 Rockchip Electronics Co., Ltd.
 */

#include <linux/device.h>
#include <linux/kernel.h>
#include <linux/mtd/spinand.h>

#define SPINAND_MFR_FMSH		0x46  /* 'F' */

static SPINAND_OP_VARIANTS(read_cache_variants,
		SPINAND_PAGE_READ_FROM_CACHE_X4_OP(0, 1, 0, NULL, 0),
		SPINAND_PAGE_READ_FROM_CACHE_X2_OP(0, 1, 0, NULL, 0),
		SPINAND_PAGE_READ_FROM_CACHE_OP(true, 0, 1, 0, NULL, 0),
		SPINAND_PAGE_READ_FROM_CACHE_OP(false, 0, 1, 0, NULL, 0));

static SPINAND_OP_VARIANTS(write_cache_variants,
		SPINAND_PROG_LOAD_X4(true, 0, 0, NULL, 0),
		SPINAND_PROG_LOAD(true, 0, 0, NULL, 0));

static SPINAND_OP_VARIANTS(update_cache_variants,
		SPINAND_PROG_LOAD_X4(false, 0, 0, NULL, 0),
		SPINAND_PROG_LOAD(false, 0, 0, NULL, 0));

/* FM25G02B OOB layout */
static int fm25g02b_ooblayout_ecc(struct mtd_info *mtd, int section,
				  struct mtd_oob_region *region)
{
	if (section >= 8)
		return -ERANGE;

	region->offset = 64 + section * 8;
	region->length = 8;

	return 0;
}

static int fm25g02b_ooblayout_free(struct mtd_info *mtd, int section,
				   struct mtd_oob_region *region)
{
	if (section)
		return -ERANGE;

	region->offset = 2;
	region->length = 62;

	return 0;
}

static const struct mtd_ooblayout_ops fm25g02b_ooblayout = {
	.ecc = fm25g02b_ooblayout_ecc,
	.free = fm25g02b_ooblayout_free,
};

static const struct spinand_info fmsh_spinand_table[] = {
	SPINAND_INFO("FM25G02B",
		     SPINAND_ID(SPINAND_READID_METHOD_OPCODE_DUMMY, 0xD2),
		     NAND_MEMORG(1, 2048, 128, 64, 2048, 40, 1, 1, 1),
		     NAND_ECCREQ(40, 512),
		     SPINAND_INFO_OP_VARIANTS(&read_cache_variants,
					      &write_cache_variants,
					      &update_cache_variants),
		     SPINAND_HAS_QE_BIT,
		     SPINAND_ECCINFO(&fm25g02b_ooblayout, NULL)),
};

static const struct spinand_manufacturer_ops fmsh_spinand_manuf_ops = {
};

const struct spinand_manufacturer fmsh_spinand_manufacturer = {
	.id = SPINAND_MFR_FMSH,
	.name = "fmsh",
	.chips = fmsh_spinand_table,
	.nchips = ARRAY_SIZE(fmsh_spinand_table),
	.ops = &fmsh_spinand_manuf_ops,
};
FMSH_EOF

echo "✅ fmsh.c 已写入"

# ============================================
# 3. 修改 Makefile 添加 fmsh.o
# ============================================
echo "=== 修改 Makefile ==="
if [ -f drivers/mtd/nand/spi/Makefile ]; then
    if ! grep -q "fmsh.o" drivers/mtd/nand/spi/Makefile; then
        sed -i 's/spinand-objs := core.o otp.o/spinand-objs := core.o fmsh.o otp.o/' drivers/mtd/nand/spi/Makefile
        echo "✅ Makefile 已修改"
    fi
else
    echo "⚠️ Makefile 不存在"
fi

# ============================================
# 4. 修改 core.c 注册制造商
# ============================================
echo "=== 修改 core.c ==="
if [ -f drivers/mtd/nand/spi/core.c ]; then
    if ! grep -q "fmsh_spinand_manufacturer" drivers/mtd/nand/spi/core.c; then
        sed -i '/&xtx_spinand_manufacturer,/a\	&fmsh_spinand_manufacturer,' drivers/mtd/nand/spi/core.c
        echo "✅ core.c 已修改"
    fi
else
    echo "⚠️ core.c 不存在"
fi

# ============================================
# 5. 修改 spinand.h 添加声明
# ============================================
echo "=== 修改 spinand.h ==="
if [ -f include/linux/mtd/spinand.h ]; then
    if ! grep -q "fmsh_spinand_manufacturer" include/linux/mtd/spinand.h; then
        sed -i '/extern const struct spinand_manufacturer xtx_spinand_manufacturer;/a extern const struct spinand_manufacturer fmsh_spinand_manufacturer;' include/linux/mtd/spinand.h
        echo "✅ spinand.h 已修改"
    fi
else
    echo "⚠️ spinand.h 不存在"
fi

echo ""
echo "=========================================="
echo "✅ FM25G02B 驱动配置完成"
echo "=========================================="
