#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
WRT_DIR="$GITHUB_WORKSPACE/wrt"
REPO_DIR="$WRT_DIR/package/JDC-AX6600-Athena-LED-Controller"

echo "== athena-led: upstream v2.5.0 =="

# 1. clone + checkout
rm -rf "$REPO_DIR"
git clone "https://github.com/guangyin53222/JDC-AX6600-Athena-LED-Controller.git" "$REPO_DIR"

cd "$REPO_DIR"
git fetch origin "refs/tags/v2.5.0:refs/tags/v2.5.0"
git checkout -q "tags/v2.5.0"

# 2. 验证 files/ 完整
echo "Checking upstream files/..."
ls -la athena-led/files/athena-led
ls -la athena-led/files/athena_led.init
ls -la athena-led/files/athena_led.config
ls -la athena-led/files/find_button.sh

# 3. 把上游 DEPENDS 改成 @TARGET_qualcommax（你这个 Makefile 已经是改好的，跳过）
# 如果你用的是原厂 checkout 出来的 Makefile，这行必须跑：
sed -i 's/@TARGET_qualcommax_ipq807x/@TARGET_qualcommax/' athena-led/Makefile
grep "DEPENDS" athena-led/Makefile

# 4. 清 build cache
rm -rf "$WRT_DIR"/build_dir/target-aarch64_cortex-a53_musl/athena-led-* 2>/dev/null || true

echo "OK: athena-led v2.5.0 ready"
