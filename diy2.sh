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

# 验证版本号（main 滚动，打 PKG_VERSION + HEAD commit）
if [ -f "package/JDC-AX6600-Athena-LED-Controller/athena-led/Makefile" ]; then
  cd package/JDC-AX6600-Athena-LED-Controller
  HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  PKG_VER=$(grep 'PKG_VERSION' \
    package/JDC-AX6600-Athena-LED-Controller/athena-led/Makefile \
    | head -1 | cut -d'=' -f2)
  echo "athena-led Makefile PKG_VERSION=${PKG_VER} (head commit: ${HEAD_COMMIT})"
else
  echo "athena-led Makefile not found! Abort."
  exit 1
fi

# ============================================================
echo "============================================"
echo " Adding luci-app-athena-led (track main)"
echo "============================================"
rm -rf package/luci-app-athena-led
git clone --depth=1 \
  https://github.com/unraveloop/luci-app-athena-led.git \
  package/luci-app-athena-led

if [ -f "package/luci-app-athena-led/Makefile" ]; then
  cd package/luci-app-athena-led
  LUCOMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  cd - >/dev/null
  LUVER=$(grep 'PKG_VERSION' package/luci-app-athena-led/Makefile \
    | head -1 | cut -d'=' -f2)
  echo "luci-app-athena-led PKG_VERSION=${LUVER} (head commit: ${LUCOMMIT})"
else
  echo "luci-app-athena-led Makefile not found! Abort."
  exit 1
fi



rm -rf package/luci-app-store
git clone --depth=1 https://github.com/linkease/istore.git package/luci-app-store

rm -rf package/OpenAppFilter
git clone --depth=1 --branch v6.1.8 https://github.com/destan19/OpenAppFilter package/OpenAppFilter

rm -rf package/luci-app-gecoosac
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac

rm -rf package/luci-app-harbor-file
git clone --depth=1 https://github.com/destan19/luci-app-harbor-file package/luci-app-harbor-file

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
CONFIG_PACKAGE_luci-i18n-harbor-file-zh-cn=y
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

# 暂时关闭易炸包
CONFIG_PACKAGE_athena-led=y
CONFIG_PACKAGE_luci-app-athena-led=y
# CONFIG_PACKAGE_luci-app-openclash=n
# CONFIG_PACKAGE_luci-app-passwall=n
EOF

make defconfig
