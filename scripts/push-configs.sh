#!/bin/bash
# push-configs.sh -- 从本机把配置推到服务器仓库（Filebrowser 的根目录）
#
# 用法：
#   HOST_IP=192.168.1.50 ./push-configs.sh
set -uo pipefail

HOST_IP=${HOST_IP:-192.168.1.50}
HOST_USER=${HOST_USER:-lumen}
BASE=${BASE:-/srv/repo}
KEY=${SSH_KEY:-$HOME/.ssh/id_ed25519}
HOST="$HOST_USER@$HOST_IP"

SSH="ssh -i $KEY -o IdentityAgent=none -o IdentitiesOnly=yes -o BatchMode=yes"

push_dir() {
    local src=$1 dst=$2
    if [ -d "$src" ]; then
        rsync -a --delete \
              --exclude '.git' --exclude 'build/' --exclude '*.bin' \
              --exclude 'installation.yaml' --exclude 'user.yaml' --exclude 'sync/' \
              --exclude 'README.md' \
              -e "$SSH" "$src/" "$HOST:$BASE/$dst/" && echo "  ✔ $dst"
    else
        echo "  - 跳过 $src（不存在）"
    fi
}

$SSH "$HOST" "mkdir -p $BASE/shell/linux $BASE/shell/wsl $BASE/shell/macos $BASE/shell/pwsh" || exit 1

echo "同步 kitty…"; push_dir "$HOME/.config/kitty"     kitty
echo "同步 rime…";  push_dir "$HOME/.config/ibus/rime"  rime

echo "同步 shell（本机 → shell/linux）…"
for f in "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.config/starship.toml"; do
    [ -f "$f" ] && rsync -a -e "$SSH" "$f" "$HOST:$BASE/shell/linux/" && echo "  ✔ $(basename "$f")"
done
