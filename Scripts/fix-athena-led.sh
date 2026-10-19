#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
WRT_DIR="$GITHUB_WORKSPACE/wrt"
TMP_REPO="$WRT_DIR/package/tmp_athena"

echo "== athena-led: upstream v2.5.0 =="

# ==========核心：删除源码自带luci包，消除同名冲突==========
rm -rf "$WRT_DIR/package/emortal/luci-app-athena-led"

# 1. 临时克隆仓库
rm -rf "$TMP_REPO"
git clone "https://github.com/guangyin53222/JDC-AX6600-Athena-LED-Controller.git" "$TMP_REPO"
cd "$TMP_REPO"
git fetch origin "refs/tags/v2.5.0:refs/tags/v2.5.0"
git checkout -q "tags/v2.5.0"

# 2. 同时拷贝后端+luci前端，保证版本配套v2.5.0
rm -rf "$WRT_DIR/package/athena-led" "$WRT_DIR/package/luci-app-athena-led"
cp -r "$TMP_REPO/athena-led" "$WRT_DIR/package/"
cp -r "$TMP_REPO/luci-app-athena-led" "$WRT_DIR/package/"

# 3. 修改Makefile平台依赖 + 关闭远程源码下载（解决download报错）
sed -i 's/@TARGET_qualcommax_ipq807x/@TARGET_qualcommax/' "$WRT_DIR/package/athena-led/Makefile"
# 清空PKG_SOURCE，使用本地源码，不再联网下载
sed -i 's/^PKG_SOURCE:=.*$/PKG_SOURCE:=/' "$WRT_DIR/package/athena-led/Makefile"
sed -i 's/^PKG_MD5SUM:=.*$/PKG_MD5SUM:=/' "$WRT_DIR/package/athena-led/Makefile"
grep "DEPENDS\|PKG_SOURCE" "$WRT_DIR/package/athena-led/Makefile"

# 4. 权限修复
chmod -R 755 "$WRT_DIR/package/athena-led"
chmod -R 755 "$WRT_DIR/package/luci-app-athena-led"

# 5. 校验文件
echo "Checking upstream files/..."
ls -la "$WRT_DIR/package/athena-led/files/"
ls -la "$WRT_DIR/package/athena-led/files/athena_led.init"
ls -la "$WRT_DIR/package/athena-led/files/athena_led.config"
ls -la "$WRT_DIR/package/athena-led/files/find_button.sh"

# 6. 删除临时仓库目录
rm -rf "$TMP_REPO"

# 7. 清理编译缓存
rm -rf "$WRT_DIR"/build_dir/target-aarch64_cortex-a53_musl/athena-led-* 2>/dev/null || true

echo "OK: athena-led v2.5.0 ready"
