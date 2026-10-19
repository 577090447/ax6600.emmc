#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
WRT_DIR="$GITHUB_WORKSPACE/wrt"
TMP_REPO="$WRT_DIR/package/tmp_athena"

echo "== athena-led: upstream v2.5.0 =="

# 删除immortalwrt自带luci-app-athena-led，解决包冲突
rm -rf "$WRT_DIR/package/emortal/luci-app-athena-led"

# 1. 临时克隆仓库
rm -rf "$TMP_REPO"
git clone "https://github.com/guangyin53222/JDC-AX6600-Athena-LED-Controller.git" "$TMP_REPO"
cd "$TMP_REPO"
git fetch origin "refs/tags/v2.5.0:refs/tags/v2.5.0"
git checkout -q "tags/v2.5.0"

# 2. 拷贝后端+luci前端，版本配套
rm -rf "$WRT_DIR/package/athena-led" "$WRT_DIR/package/luci-app-athena-led"
cp -r "$TMP_REPO/athena-led" "$WRT_DIR/package/"
cp -r "$TMP_REPO/luci-app-athena-led" "$WRT_DIR/package/"

# 3. 修改Makefile
sed -i 's/@TARGET_qualcommax_ipq807x/@TARGET_qualcommax/' "$WRT_DIR/package/athena-led/Makefile"
# 【核心修复】清空PKG_SOURCE和HASH，关闭远程下载
sed -i '/^PKG_SOURCE:=/d' "$WRT_DIR/package/athena-led/Makefile"
sed -i '/^PKG_HASH:=/d' "$WRT_DIR/package/athena-led/Makefile"
# 本地源码模式，添加
echo "PKG_SOURCE:=" >> "$WRT_DIR/package/athena-led/Makefile"

# 打印Makefile关键行，CI日志里可以核对
echo "==== Check Makefile ===="
grep -E "DEPENDS|PKG_SOURCE|PKG_HASH" "$WRT_DIR/package/athena-led/Makefile"

# 4. 权限修复
chmod -R 755 "$WRT_DIR/package/athena-led"
chmod -R 755 "$WRT_DIR/package/luci-app-athena-led"

# 5. 校验文件
echo "Checking upstream files/..."
ls -la "$WRT_DIR/package/athena-led/files/"

# 6. 删除临时仓库
rm -rf "$TMP_REPO"

# 7. 清理旧缓存
rm -rf "$WRT_DIR"/build_dir/target-aarch64_cortex-a53_musl/athena-led-* 2>/dev/null || true

echo "OK: athena-led v2.5.0 ready"
