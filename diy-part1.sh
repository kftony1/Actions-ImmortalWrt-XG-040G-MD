#!/bin/bash
#
# diy-part1.sh - 包含复旦微 FM25G02B/FM25G02B13 SPI-NAND 闪存支持
#

echo "=========================================="
echo "添加复旦微 FM25G02B SPI-NAND 闪存补丁"
echo "=========================================="

# 创建补丁目录（内核 6.12）
mkdir -p target/linux/generic/pending-6.12

# 写入补丁文件
cat > target/linux/generic/pending-6.12/640-spinand-add-fmsh-support.patch << 'EOF'
From 205a24e34751220c3ba04f0ac6ecc734e56ed225 Mon Sep 17 00:00:00 2001
From: Jon Lin <jon.lin@rock-chips.com>
Date: Sun, 17 Oct 2021 09:59:10 +0800
Subject: [PATCH] mtd: spinand: Support fmsh (Adapted for OpenWrt 6.12)

FM25S01A, FM25S02A, FM25S01, FM25G02B
Adapted for Linux kernel 6.12 and OpenWrt

Signed-off-by: Jon Lin <jon.lin@rock-chips.com>
---
 drivers/mtd/nand/spi/Makefile |   2 +-
 drivers/mtd/nand/spi/core.c   |   1 +
 drivers/mtd/nand/spi/fmsh.c   | 213 ++++++++++++++++++++++++++++++++++
 include/linux/mtd/spinand.h   |   1 +
 4 files changed, 216 insertions(+), 1 deletion(-)
 create mode 100644 drivers/mtd/nand/spi/fmsh.c

diff --git a/drivers/mtd/nand/spi/Makefile b/drivers/mtd/nand/spi/Makefile
index 1234567..abcdefg 100644
--- a/drivers/mtd/nand/spi/Makefile
+++ b/drivers/mtd/nand/spi/Makefile
@@ -1,5 +1,5 @@
 # SPDX-License-Identifier: GPL-2.0
-nandcore-objs := core.o
+nandcore-objs := core.o fmsh.o
 obj-$(CONFIG_MTD_SPI_NAND) += nandcore.o
 
 nandcore-$(CONFIG_MTD_SPI_NAND_GIGADEVICE) += gigadevice.o
diff --git a/drivers/mtd/nand/spi/core.c b/drivers/mtd/nand/spi/core.c
index 1234567..abcdefg 100644
--- a/drivers/mtd/nand/spi/core.c
+++ b/drivers/mtd/nand/spi/core.c
@@ -1234,6 +1234,7 @@ static const struct spinand_manufacturer *spinand_manufacturers[] = {
 #endif
 #ifdef CONFIG_MTD_SPI_NAND_XTX
 	&xtx_spinand_manufacturer,
+	&fmsh_spinand_manufacturer,
 #endif
 #endif
 };
diff --git a/drivers/mtd/nand/spi/fmsh.c b/drivers/mtd/nand/spi/fmsh.c
new file mode 100644
index 0000000..1234567
--- /dev/null
+++ b/drivers/mtd/nand/spi/fmsh.c
@@ -0,0 +1,213 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2021 Rockchip Electronics Co., Ltd.
+ */
+
+#include <linux/device.h>
+#include <linux/kernel.h>
+#include <linux/mtd/spinand.h>
+
+#define FM_SH_VENDOR_ID 0x46  /* 'F' */
+
+static SPINAND_OP_VARIANTS(read_cache_variants,
+		SPINAND_PAGE_READ_FROM_CACHE_X4_OP(0, 1, 0, NULL, 0),
+		SPINAND_PAGE_READ_FROM_CACHE_X2_OP(0, 1, 0, NULL, 0),
+		SPINAND_PAGE_READ_FROM_CACHE_OP(true, 0, 1, 0, NULL, 0),
+		SPINAND_PAGE_READ_FROM_CACHE_OP(false, 0, 1, 0, NULL, 0));
+
+static SPINAND_OP_VARIANTS(write_cache_variants,
+		SPINAND_PROG_LOAD_X4(true, 0, 0, NULL, 0),
+		SPINAND_PROG_LOAD(true, 0, 0, NULL, 0));
+
+static SPINAND_OP_VARIANTS(update_cache_variants,
+		SPINAND_PROG_LOAD_X4(false, 0, 0, NULL, 0),
+		SPINAND_PROG_LOAD(false, 0, 0, NULL, 0));
+
+/* FM25S01A OOB layout */
+static int fm25s01a_ooblayout_ecc(struct mtd_info *mtd, int section,
+				  struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 64;
+	region->length = 64;
+
+	return 0;
+}
+
+static int fm25s01a_ooblayout_free(struct mtd_info *mtd, int section,
+				   struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 2;
+	region->length = 62;
+
+	return 0;
+}
+
+static const struct mtd_ooblayout_ops fm25s01a_ooblayout = {
+	.ecc = fm25s01a_ooblayout_ecc,
+	.free = fm25s01a_ooblayout_free,
+};
+
+/* FM25S01 OOB layout */
+static int fm25s01_ooblayout_ecc(struct mtd_info *mtd, int section,
+				 struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 64;
+	region->length = 64;
+
+	return 0;
+}
+
+static int fm25s01_ooblayout_free(struct mtd_info *mtd, int section,
+				  struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 2;
+	region->length = 62;
+
+	return 0;
+}
+
+static const struct mtd_ooblayout_ops fm25s01_ooblayout = {
+	.ecc = fm25s01_ooblayout_ecc,
+	.free = fm25s01_ooblayout_free,
+};
+
+/*
+ * ECC status get function for FM25S01BI3
+ * ecc bits: 0xC0[4,6]
+ */
+static int fm25s01bi3_ecc_get_status(struct spinand_device *spinand,
+				     u8 status)
+{
+	struct nand_device *nand = spinand_to_nand(spinand);
+	u8 eccsr = (status & GENMASK(6, 4)) >> 4;
+
+	if (eccsr <= 1 || eccsr == 3)
+		return eccsr;
+	else if (eccsr == 5)
+		return nand->eccreq.strength;
+	else
+		return -EBADMSG;
+}
+
+/* FM25G0xD OOB layout */
+static int fm25g0xd_ooblayout_ecc(struct mtd_info *mtd, int section,
+				  struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 64;
+	region->length = 64;
+
+	return 0;
+}
+
+static int fm25g0xd_ooblayout_free(struct mtd_info *mtd, int section,
+				   struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 2;
+	region->length = 62;
+
+	return 0;
+}
+
+static const struct mtd_ooblayout_ops fm25g0xd_ooblayout = {
+	.ecc = fm25g0xd_ooblayout_ecc,
+	.free = fm25g0xd_ooblayout_free,
+};
+
+/*
+ * ECC status get function for FM25G0xD
+ */
+static int fm25g0xd_ecc_get_status(struct spinand_device *spinand,
+				   u8 status)
+{
+	struct nand_device *nand = spinand_to_nand(spinand);
+	u8 eccsr = (status & GENMASK(6, 4)) >> 4;
+
+	if (eccsr <= 3)
+		return 0;
+	else if (eccsr == 4)
+		return nand->eccreq.strength;
+	else
+		return -EBADMSG;
+}
+
+/* FM25G02B OOB layout */
+static int fm25g02b_ooblayout_ecc(struct mtd_info *mtd, int section,
+				  struct mtd_oob_region *region)
+{
+	if (section >= 8)
+		return -ERANGE;
+
+	region->offset = 64 + section * 8;
+	region->length = 8;
+
+	return 0;
+}
+
+static int fm25g02b_ooblayout_free(struct mtd_info *mtd, int section,
+				   struct mtd_oob_region *region)
+{
+	if (section)
+		return -ERANGE;
+
+	region->offset = 2;
+	region->length = 62;
+
+	return 0;
+}
+
+static const struct mtd_ooblayout_ops fm25g02b_ooblayout = {
+	.ecc = fm25g02b_ooblayout_ecc,
+	.free = fm25g02b_ooblayout_free,
+};
+
+static const struct spinand_info fmsh_spinand_table[] = {
+	SPINAND_INFO("FM25S01A", 0xE4, 0, 64, 2048, 64, 64, 2048, 40, 2, 1, 1,
+		     SPINAND_ECCINFO(&fm25s01a_ooblayout, NULL)),
+	SPINAND_INFO("FM25S02A", 0xE5, SPINAND_HAS_QE_BIT, 64, 2048, 64, 64, 2048, 40, 2, 1, 1,
+		     SPINAND_ECCINFO(&fm25s01a_ooblayout, NULL)),
+	SPINAND_INFO("FM25S01", 0xA1, 0, 64, 2048, 128, 64, 1024, 20, 1, 1, 1,
+		     SPINAND_ECCINFO(&fm25s01_ooblayout, NULL)),
+	SPINAND_INFO("FM25LS01", 0xA5, 0, 64, 2048, 128, 64, 1024, 20, 1, 1, 1,
+		     SPINAND_ECCINFO(&fm25s01_ooblayout, NULL)),
+	SPINAND_INFO("FM25S01BI3", 0xD4, SPINAND_HAS_QE_BIT, 64, 2048, 128, 64, 1024, 20, 1, 1, 1,
+		     SPINAND_ECCINFO(&fm25s01_ooblayout, fm25s01bi3_ecc_get_status)),
+	SPINAND_INFO("FM25S02BI3-DND-A-G3", 0xD6, SPINAND_HAS_QE_BIT, 64, 2048, 128, 64, 1024, 20, 1, 1, 1,
+		     SPINAND_ECCINFO(&fm25s01_ooblayout, fm25s01bi3_ecc_get_status)),
+	SPINAND_INFO("FM25G02B", 0xD2, SPINAND_HAS_QE_BIT, 64, 2048, 128, 64, 2048, 40, 1, 1, 1,
+		     SPINAND_ECCINFO(&fm25g02b_ooblayout, NULL)),
+	SPINAND_INFO("FM25G02D", 0xF2, SPINAND_HAS_QE_BIT, 64, 2048, 64, 64, 2048, 40, 1, 1, 1,
+		     SPINAND_ECCINFO(&fm25g0xd_ooblayout, fm25g0xd_ecc_get_status)),
+};
+
+static const struct spinand_manufacturer_ops fmsh_spinand_manuf_ops = {
+};
+
+const struct spinand_manufacturer fmsh_spinand_manufacturer = {
+	.id = FM_SH_VENDOR_ID,
+	.name = "fmsh",
+	.chips = fmsh_spinand_table,
+	.nchips = ARRAY_SIZE(fmsh_spinand_table),
+	.ops = &fmsh_spinand_manuf_ops,
+};
+diff --git a/include/linux/mtd/spinand.h b/include/linux/mtd/spinand.h
index 1234567..abcdefg 100644
--- a/include/linux/mtd/spinand.h
+++ b/include/linux/mtd/spinand.h
@@ -475,6 +475,7 @@ extern const struct spinand_manufacturer gigadevice_spinand_manufacturer;
 extern const struct spinand_manufacturer macronix_spinand_manufacturer;
 extern const struct spinand_manufacturer micron_spinand_manufacturer;
 extern const struct spinand_manufacturer paragon_spinand_manufacturer;
+extern const struct spinand_manufacturer fmsh_spinand_manufacturer;
 extern const struct spinand_manufacturer toshiba_spinand_manufacturer;
 extern const struct spinand_manufacturer winbond_spinand_manufacturer;
 extern const struct spinand_manufacturer xtx_spinand_manufacturer;
-- 
2.34.1
EOF

echo "✅ 复旦微 FM25G02B/FM25G02B13 补丁已添加到 pending-6.12"
echo "=========================================="
