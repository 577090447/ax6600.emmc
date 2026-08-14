#!/bin/bash
set -e

# LAN IP
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 编辑默认的主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# ========== 第三方插件 ==========
# 1. JDC AX6600 Athena LED Controller
# 官方源: https://github.com/unraveloop/JDC-AX6600-Athena-LED-Controller
# 锁定版本: v2.4.0（官方已发布的稳定版，有预编译 Rust 二进制）
# 注意: main 分支已到 v2.5.0，但 release 尚未发布，直接编会 404
# ============================================================
echo "============================================"
echo " Adding JDC-AX6600 Athena LED Controller"
echo "============================================"

rm -rf package/JDC-AX6600-Athena-LED-Controller
git clone --depth=1 --branch v2.4.0 \
  https://github.com/unraveloop/JDC-AX6600-Athena-LED-Controller.git \
  package/JDC-AX6600-Athena-LED-Controller

# 验证版本号
if [ -f "package/JDC-AX6600-Athena-LED-Controller/athena-led/Makefile" ]; then
  PKG_VER=$(grep 'PKG_VERSION' \
    package/JDC-AX6600-Athena-LED-Controller/athena-led/Makefile \
    | head -1 | cut -d'=' -f2)
  echo "✅ athena-led Makefile PKG_VERSION=${PKG_VER}"
else
  echo "❌ athena-led Makefile not found! Abort."
  exit 1
fi

# ============================================================
# iStore (应用商店)
# ============================================================
rm -rf package/luci-app-store
git clone --depth=1 https://github.com/linkease/istore.git package/luci-app-store

# ============================================================
# OpenAppFilter (应用过滤) - 使用 tag v6.1.8
# ============================================================
rm -rf package/OpenAppFilter
git clone --depth=1 --branch v6.1.8 https://github.com/destan19/OpenAppFilter.git \
  package/OpenAppFilter

# ============================================================
# GecooSAC (高恪AC管理)
# ============================================================
rm -rf package/luci-app-gecoosac
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac.git \
  package/luci-app-gecoosac

# ============================================================
# Harbor File (文件管理)
# ============================================================
rm -rf package/luci-app-harbor-file
git clone --depth=1 https://github.com/destan19/luci-app-harbor-file.git \
  package/luci-app-harbor-file

# ========== feeds ==========
./scripts/feeds update -a
./scripts/feeds install -a

# ========== .config ==========
cat >> .config << 'EOF'
CONFIG_DEFAULT_luci-theme-argon=y

CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_xz-utils=y
CONFIG_PACKAGE_curl=y

CONFIG_PACKAGE_luci-app-oaf=y
CONFIG_PACKAGE_appfilter=y
CONFIG_PACKAGE_kmod-oaf=y

CONFIG_PACKAGE_luci-app-gecoosac=y

CONFIG_PACKAGE_luci-app-harbor-file=y
CONFIG_PACKAGE_luci-app-diskman=y

CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-theme-argon=y

CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y

CONFIG_PACKAGE_kmod-usb-serial=y
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-wwan=y

CONFIG_PACKAGE_uqmi=y
CONFIG_PACKAGE_umbim=y
CONFIG_PACKAGE_luci-proto-qmi=y
CONFIG_PACKAGE_luci-proto-mbim=y

# Athena LED
CONFIG_PACKAGE_athena-led=y
CONFIG_PACKAGE_luci-app-athena-led=y
EOF

make defconfig
