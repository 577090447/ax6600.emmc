#!/bin/bash
# ========== diy.sh - OpenWrt/ImmortalWrt 编译前自定义脚本 ==========

# 请在下方输入自定义命令(一般用来安装第三方插件)(可以留空)

# 编辑默认的lan口ip地址
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 编辑默认的主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-aurora/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 编辑默认的luci显示的固件名称
#sed -i 's/OpenWrt/ZWRT/g' package/base-files/files/bin/config_generate
#sed -i 's/ImmortalWrt/ZWRT/g' package/base-files/files/bin/config_generate

# 添加额外的软件包，echo 方式和git clone 方式二选一即可
#echo 'src-git kenzok8 https://github.com/kenzok8/openwrt-packages' feeds.conf.default
#echo 'src-git small https://github.com/kenzok8/small' feeds.conf.default
#echo 'src-git UA3F https://github.com/SunBK201/UA3F.git' feeds.conf.default
#git clone https://github.com/kenzok8/openwrt-packages.git package/openwrt-packages
#git clone https://github.com/kenzok8/small.git package/small
#git clone https://github.com/SunBK201/UA3F.git package/UA3F
#git clone https://github.com/stevenjoezhang/luci-app-adguardhome.git package/ADGH
# ============================================================
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

# ========== 4. Argon 主题 ==========
echo "设置 Argon 为默认主题..."
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# ========== 6. 克隆第三方插件 ==========
echo "克隆第三方插件..."

# store
rm -rf package/luci-app-store
git clone --depth=1 https://github.com/linkease/istore.git package/luci-app-store

# OpenAppFilter（锁 v6.1.8 tag）
rm -rf package/OpenAppFilter
git clone --depth 1 --branch v6.1.8 https://github.com/destan19/OpenAppFilter package/OpenAppFilter

# Gecoos AC
rm -rf package/luci-app-gecoosac
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac

# Harbor File
rm -rf package/luci-app-harbor-file
git clone --depth=1 https://github.com/destan19/luci-app-harbor-file package/luci-app-harbor-file

# ========== 7. 更新并安装 feeds ==========
echo "更新并安装 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# ========== 8. 写入插件配置到 .config（必须在 feeds install 之后） ==========
echo "写入插件配置到 .config..."
cat >> .config << 'EOF'
# -------------------- 雅典娜点阵屏 --------------------
CONFIG_PACKAGE_athena-led=y
CONFIG_PACKAGE_luci-app-athena-led=y
# iStore
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_xz-utils=y
CONFIG_PACKAGE_curl=y

# OpenAppFilter
CONFIG_PACKAGE_luci-app-oaf=y
CONFIG_PACKAGE_appfilter=y
CONFIG_PACKAGE_kmod-oaf=y

# Gecoos AC
CONFIG_PACKAGE_luci-app-gecoosac=y

# Harbor File
CONFIG_PACKAGE_luci-app-harbor-file=y
CONFIG_PACKAGE_luci-i18n-harbor-file-zh-cn=y
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_btrfs_progs=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_lsblk=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_mdadm=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Geoview=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-theme-argon=y
EOF


echo "执行 defconfig..."
make defconfig

echo "=========================================="
echo " diy.sh 执行完成"
echo "=========================================="
