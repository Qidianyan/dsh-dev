#!/bin/sh
# dsh-dev 一键安装：拷贝 Claude Code skill 并把 dshdev 链接进 PATH。
# 卸载：rm ~/.local/bin/dshdev ~/.claude/skills/dsh-dev
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.claude/skills/dsh-dev"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "$SKILL_DIR/scripts" "$BIN_DIR"
cp "$HERE/scripts/dshdev" "$SKILL_DIR/scripts/dshdev"
cp "$HERE/SKILL.md" "$SKILL_DIR/SKILL.md"
chmod +x "$SKILL_DIR/scripts/dshdev"
ln -sf "$SKILL_DIR/scripts/dshdev" "$BIN_DIR/dshdev"

echo "已安装:"
echo "  CLI   $BIN_DIR/dshdev"
echo "  Skill $SKILL_DIR/SKILL.md"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "注意: $BIN_DIR 不在 PATH 中，请将其加入 shell 配置" ;;
esac
echo "运行 dshdev doctor 检查环境。"
