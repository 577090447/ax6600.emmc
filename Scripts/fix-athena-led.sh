#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
WRT_DIR="$GITHUB_WORKSPACE/wrt"
TMP_REPO="$WRT_DIR/package/tmp_athena"

echo "== athena-led: upstream v2.5.0 =="

# 1. 临时克隆仓库到tmp目录
rm -rf "$TMP_REPO"
git clone "https://github.com/guangyin53222/JDC-AX6600-Athena-LED-Controller.git" "$TMP_REPO"
cd "$TMP_REPO"
git fetch origin "refs/tags/v2.5.0:refs/tags/v2.5.0"
git checkout -q "tags/v2.5.0"

# 2. 把两个包提取到package同级
rm -rf "$WRT_DIR/package/athena-led" "$WRT_DIR/package/luci-app-athena-led"
cp -r "$TMP_REPO/athena-led" "$WRT_DIR/package/"
cp -r "$TMP_REPO/luci-app-athena-led" "$WRT_DIR/package/"



# 4. 校验文件
echo "Checking upstream files/..."
ls -la "$WRT_DIR/package/athena-led/files/athena-led"
ls -la "$WRT_DIR/package/athena-led/files/athena_led.init"
ls -la "$WRT_DIR/package/athena-led/files/athena_led.config"
ls -la "$WRT_DIR/package/athena-led/files/find_button.sh"

# 5. 删除临时仓库目录
rm -rf "$TMP_REPO"

# 6. 清理编译缓存
rm -rf "$WRT_DIR"/build_dir/target-aarch64_cortex-a53_musl/athena-led-* 2>/dev/null || true

echo "OK: athena-led v2.5.0 ready"
