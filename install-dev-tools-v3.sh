#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
# ============================================================
# 📦 Fedora 一键开发环境安装脚本
#
# 支持安装的软件：
#   - Slack (Flatpak)
#   - Kdenlive (Flatpak)
#   - Kooha (Flatpak)
#   - ffmpeg
#   - podman-desktop
#   - Python3 + pip
#   - Go (golang)
#   - Yarn
#   - OpenShift CLI (oc)
#   - kubectl
#   - kustomize
#   - Git
#   - GitHub CLI (gh)
#   - GNOME notification plugin (libnotify, 提供 notify-send)
#
# ✅ 特性：
#   1. 已安装的包会自动跳过。
#   2. 如果命令已存在 + Flatpak 版本也安装 → 自动卸载 Flatpak，避免重复。
#   3. 默认安装 Docker Engine，如需 Docker Desktop 可传参。
#
# 🔧 参数：
#   INSTALL_DOCKER_DESKTOP=true   安装 Docker Desktop（默认 false，安装 Docker Engine）
#
# 🚀 用法示例：
#   # 直接安装（默认 Docker Engine）
#   ./install-dev-tools-v3.sh
#
#   # 强制安装 Docker Desktop
#   INSTALL_DOCKER_DESKTOP=true ./install-dev-tools-v3.sh
#
#   # 调试模式运行（显示执行过程）
#   bash -x ./install-dev-tools-v3.sh
#
#   # 显示帮助
#   ./install-dev-tools-v3.sh --help
#
# 📋 脚本执行后会：
#   - 确认安装状态
#   - 卸载重复的 Flatpak 应用
#   - 最终只保留一个可用版本
# ============================================================
EOF
}

# 如果用户传了 -h 或 --help，直接显示帮助并退出
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

# ===== Helpers =====
has_cmd() { command -v "$1" &>/dev/null; }

flatpak_remove_if_duplicate() {
  local bin="$1"
  local app="$2"
  if has_cmd "$bin" && flatpak info "$app" &>/dev/null; then
    echo "⚠️  Both native ($bin) and Flatpak ($app) found. Removing Flatpak version..."
    flatpak uninstall -y "$app"
  fi
}

install_flatpak_if_missing() {
  local bin="$1"      # 可执行名
  local app="$2"      # Flatpak ID
  if has_cmd "$bin"; then
    echo "$bin already present (native). Skip Flatpak install."
    flatpak_remove_if_duplicate "$bin" "$app"
    return
  fi
  if flatpak info "$app" &>/dev/null; then
    echo "$app (Flatpak) already installed. Skip."
    return
  fi
  echo "Installing $app via Flatpak..."
  flatpak install -y flathub "$app"
}

install_dnf_pkg_if_missing() {
  local bin="$1"
  local pkg="$2"
  if has_cmd "$bin"; then
    echo "$bin already present. Skip."
    return
  fi
  echo "Installing $pkg via dnf..."
  sudo dnf install -y "$pkg"
}

# ===== Ensure base =====
sudo dnf -y install dnf-plugins-core curl wget git flatpak
if ! flatpak remotes | grep -q flathub; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ===== Apps =====
install_flatpak_if_missing "slack" "com.slack.Slack"
install_flatpak_if_missing "kdenlive" "org.kde.kdenlive"
install_flatpak_if_missing "kooha" "io.github.seadve.Kooha"
install_dnf_pkg_if_missing "ffmpeg" "ffmpeg"

# ===== Podman Desktop =====
if has_cmd podman; then
  echo "Podman already installed."
else
  echo "Installing Podman..."
  sudo dnf install -y podman
fi

# Podman Desktop (GUI)
if flatpak info io.podman_desktop.PodmanDesktop &>/dev/null; then
  echo "Podman Desktop (Flatpak) already installed. Skip."
else
  echo "Installing Podman Desktop via Flatpak..."
  flatpak install -y flathub io.podman_desktop.PodmanDesktop
fi

# ===== VS Code =====
if has_cmd code; then
  echo "VS Code already installed. Skip."
else
  echo "Installing Visual Studio Code..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  sudo dnf install -y code
fi

# ===== VS Code Plugins =====
VSCODE_EXTS=(
  "ms-vscode.vscode-typescript-next"
  "dbaeumer.vscode-eslint"
  "esbenp.prettier-vscode"
  "dsznajder.es7-react-js-snippets"
  "firsttris.vscode-jest-runner"
  "ms-python.python"
  "ms-python.vscode-pylance"
  "golang.go"
)

if has_cmd code; then
  for ext in "${VSCODE_EXTS[@]}"; do
    if code --list-extensions | grep -q "$ext"; then
      echo "VS Code extension $ext already installed. Skip."
    else
      echo "Installing VS Code extension: $ext"
      code --install-extension "$ext" --force
    fi
  done
fi

# ===== CLI tools =====
install_dnf_pkg_if_missing "python3" "python3"
has_cmd pip3 || sudo dnf install -y python3-pip
install_dnf_pkg_if_missing "go" "golang"

if has_cmd yarn || has_cmd yarnpkg; then
  echo "yarn already present. Skip."
  flatpak_remove_if_duplicate "yarn" "com.yarnpkg.yarn"
else
  sudo dnf install -y yarnpkg
  sudo ln -sf /usr/bin/yarnpkg /usr/bin/yarn
fi

# ===== OpenShift CLI (oc) =====
if has_cmd oc; then
  echo "oc already installed. Skip."
else
  echo "Installing OpenShift CLI..."
  TMP_DIR=$(mktemp -d)
  OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz"

  echo "Downloading OpenShift CLI from $OC_URL..."
  if ! curl -L -o "$TMP_DIR/oc.tar.gz" "$OC_URL"; then
    echo "❌ Failed to download OpenShift CLI. Check network or URL."
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo "Extracting..."
  if ! tar -xzf "$TMP_DIR/oc.tar.gz" -C "$TMP_DIR"; then
    echo "❌ Failed to extract OpenShift CLI."
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo "Installing binaries to /usr/local/bin..."
  sudo mv "$TMP_DIR/oc" "$TMP_DIR/kubectl" /usr/local/bin/
  rm -rf "$TMP_DIR"
  echo "OpenShift CLI (oc) and kubectl installed."
fi

if has_cmd kustomize; then
  echo "kustomize already present. Skip."
else
  if dnf list --available kustomize &>/dev/null; then
    sudo dnf install -y kustomize
  else
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize /usr/local/bin/
  fi
fi

install_dnf_pkg_if_missing "git" "git"
install_dnf_pkg_if_missing "gh" "gh"
install_dnf_pkg_if_missing "notify-send" "libnotify"

echo "✅ All tools checked. Flatpak duplicates removed if any."

