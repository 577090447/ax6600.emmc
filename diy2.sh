#!/bin/bash
set -e

# LAN IP
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 编辑默认的主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# ========== 第三方插件 ==========

# ============================================================
echo "============================================"
echo " Adding JDC-AX6600 Athena LED Controller (track main)"
echo "============================================"
rm -rf package/JDC-AX6600-Athena-LED-Controller
git clone --depth=1 \
  https://github.com/unraveloop/JDC-AX6600-Athena-LED-Controller.git \
  package/JDC-AX6600-Athena-LED-Controller

# 验证 athena-led (Rust 后端)
if [ -f "package/JDC-AX6600-Athena-LED-Controller/athena-led/Makefile" ]; then
  cd package/JDC-AX6600-Athena-LED-Controller
  HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  PKG_VER=$(grep 'PKG_VERSION' \
    package/JDC-AX6600-Athena-LED-Controller/athena-led/Makefile \
    | head -1 | cut -d'=' -f2)
  echo "athena-led Makefile PKG_VERSION=${PKG_VER} (head commit: ${HEAD_COMMIT})"
else
  echo "ERROR: athena-led Makefile not found! Abort."
  exit 1
fi

# ============================================================
# 关键修复：luci-app-athena-led 是上面仓库的子目录，不是独立仓库
# 直接将其复制到 package/ 下即可
# ============================================================
echo "============================================"
echo " Adding luci-app-athena-led (from submodule in same repo)"
echo "============================================"
rm -rf package/luci-app-athena-led
cp -r package/JDC-AX6600-Athena-LED-Controller/luci-app-athena-led \
      package/luci-app-athena-led

if [ -f "package/luci-app-athena-led/Makefile" ]; then
  cd package/luci-app-athena-led
  LUCOMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  LUVER=$(grep 'PKG_VERSION' package/luci-app-athena-led/Makefile \
    | head -1 | cut -d'=' -f2)
  echo "luci-app-athena-led PKG_VERSION=${LUVER} (head commit: ${LUCOMMIT})"
else
  echo "ERROR: luci-app-athena-led Makefile not found! Abort."
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
