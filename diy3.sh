#!/bin/bash
# ========== diy.sh - OpenWrt 25.12 编译前自定义脚本 ==========
# 适用：OpenWrt 25.12（IPQ60xx / JDCloud AX6600 Athena）
# 注意：25.12 产物为 .apk（运行时 apk），编译期仍是 make 体系

# ========== 1. 基础系统修改 ==========

# 编辑默认的 LAN 口 IP 地址
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 设置 Argon 为默认主题（提前做，避免 feeds 覆盖）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-aurora/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 编辑默认的 Luci 显示的固件名称（按需取消注释）
#sed -i 's/OpenWrt/ZWRT/g' package/base-files/files/bin/config_generate
#sed -i 's/ImmortalWrt/ZWRT/g' package/base-files/files/bin/config_generate

# ========== 2. 克隆第三方插件 ==========
echo "==> 克隆第三方插件..."

# ---- Athena LED 控制器（Rust 核心 + LuCI 界面）----
# 主仓库根目录不是 feed 布局，需 clone 后只取两个子目录
ATHENA_REPO="https://github.com/unraveloop/JDC-AX6600-Athena-LED-Controller.git"
rm -rf package/athena-led package/luci-app-athena-led /tmp/athena-led-repo
git clone --depth=1 "$ATHENA_REPO" /tmp/athena-led-repo
# 复制 Rust 核心包
cp -r /tmp/athena-led-repo/athena-led package/athena-led
# 复制 LuCI 界面包
cp -r /tmp/athena-led-repo/luci-app-athena-led package/luci-app-athena-led
# 清理临时目录
rm -rf /tmp/athena-led-repo
echo "    [✓] athena-led + luci-app-athena-led"

# iStore
rm -rf package/luci-app-store
git clone --depth=1 https://github.com/linkease/istore.git package/luci-app-store
echo "    [✓] luci-app-store"

# OpenAppFilter（锁 v6.1.8 tag）
rm -rf package/OpenAppFilter
git clone --depth 1 --branch v6.1.8 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
echo "    [✓] OpenAppFilter v6.1.8"

# Gecoos AC
rm -rf package/luci-app-gecoosac
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac
echo "    [✓] luci-app-gecoosac"

# Harbor File
rm -rf package/luci-app-harbor-file
git clone --depth=1 https://github.com/destan19/luci-app-harbor-file package/luci-app-harbor-file
echo "    [✓] luci-app-harbor-file"

# ========== 3. 更新并安装 feeds ==========
echo "==> 更新并安装 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 安装 athena-led 相关包（确保依赖被正确识别）
./scripts/feeds install athena-led 2>/dev/null || true
./scripts/feeds install luci-app-athena-led 2>/dev/null || true

# ========== 4. 写入插件配置到 .config（必须在 feeds install 之后） ==========
echo "==> 写入插件配置到 .config..."

# 先清理旧的 athena-led 相关配置（避免重复追加）
sed -i '/# ---- 雅典娜点阵屏/,/CONFIG_PACKAGE_luci-app-athena-led=y/d' .config 2>/dev/null || true

cat >> .config << 'EOF'

# -------------------- 雅典娜点阵屏 (Athena LED) --------------------
CONFIG_PACKAGE_athena-led=y
CONFIG_PACKAGE_luci-app-athena-led=y

# -------------------- iStore --------------------
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_xz-utils=y
CONFIG_PACKAGE_curl=y

# -------------------- OpenAppFilter --------------------
CONFIG_PACKAGE_luci-app-oaf=y
CONFIG_PACKAGE_appfilter=y
CONFIG_PACKAGE_kmod-oaf=y

# -------------------- Gecoos AC --------------------
CONFIG_PACKAGE_luci-app-gecoosac=y

# -------------------- Harbor File --------------------
CONFIG_PACKAGE_luci-app-harbor-file=y
CONFIG_PACKAGE_luci-i18n-harbor-file-zh-cn=y

# -------------------- 常用应用 --------------------
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-theme-argon=y

# -------------------- USB 硬盘支持 --------------------
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y

# -------------------- 4G 模块串口 (AT/诊断口) --------------------
CONFIG_PACKAGE_kmod-usb-serial=y
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-wwan=y

# -------------------- QMI/MBIM 拨号 (官方) --------------------
CONFIG_PACKAGE_uqmi=y
CONFIG_PACKAGE_umbim=y
CONFIG_PACKAGE_luci-proto-qmi=y
CONFIG_PACKAGE_luci-proto-mbim=y

EOF

echo "==> 执行 defconfig..."
make defconfig

echo "=========================================="
echo " diy.sh 执行完成"
echo "=========================================="
echo ""
echo "提示："
echo "  1. athena-led 为 Rust 核心，需 aarch64-unknown-linux-musl 二进制"
echo "     （默认从 GitHub Releases 下载预编译版本，无需本地装 Rust）"
echo "  2. 如果编译报 athena-led 下载失败，请检查网络或手动下载放 dl/"
echo "  3. 编译命令：make -j\$(nproc) V=s"
echo "=========================================="