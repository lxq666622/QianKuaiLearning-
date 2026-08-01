#!/usr/bin/env bash
# ============================================================================
# 【倩快学习】一键本地 Windows → iPhone 装包 自动化脚本 (需要 Sideloadly + 已授权Apple ID)
# 用法: bash scripts/deploy_iphone.bat (或Git Bash运行)
# ============================================================================

set -e

echo "========== 倩快学习 → iPhone 部署助手 =========="
echo ""

# 1. 检查用户 IPA 文件路径
IPA_PATH="${1:-}"
if [ -z "$IPA_PATH" ]; then
  echo "⚠️  请先下载 Codemagic/GitHub Actions 构建的 IPA 文件"
  echo "   用法： $0 /c/Users/倩/Desktop/QianKuaiLearning.ipa"
  echo ""
  read -p "或粘贴 IPA 文件绝对路径: " IPA_PATH
fi

# 2. Apple ID
if [ -z "$APPLE_ID" ]; then
  read -p "🔑 请输入你的 Apple ID (邮箱): " APPLE_ID
fi

# 3. 调起 Sideloadly 签名并安装
SIDLOADLY_EXE="/c/Program Files/Sideloadly/Sideloadly.exe"
if [ -f "$SIDLOADLY_EXE" ]; then
  echo ""
  echo "🚀 正在启动 Sideloadly 侧加载..."
  echo "   Apple ID: $APPLE_ID"
  echo "   IPA:      $IPA_PATH"
  echo ""
  echo "   → 出现密码/验证码提示时，输入 Apple ID 密码 + iPhone发来的双重认证码"
  echo ""
  "$SIDLOADLY_EXE" --appleid "$APPLE_ID" --ipa "$IPA_PATH" --autoinstall
  echo ""
  echo "✅ 完成！请在iPhone：设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID 后即可打开！"
  echo "📅 下次到期（7天）重跑本脚本一次即可续期"
else
  echo "⚠️  未找到 Sideloadly。安装地址: https://sideloadly.io/"
  echo "   装完再运行本脚本。"
fi
