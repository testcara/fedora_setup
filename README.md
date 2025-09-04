# fedora_setup

This repository contains scripts to quickly set up a **Fedora development environment** and manage multiple Git repositories. It is designed to make Fedora workstations ready for software development with common tools, VS Code extensions, and repository synchronization.

---

## 🗂 Repository Contents

- `install-dev-tools-v3.sh`  
  Installs development tools on Fedora including:
    - VIM  -> would also set it as the default editor
    - Slack (Flatpak) -> for team connection
    - Kdenlive (Flatpak) -> for video edition
    - Kooha (Flatpak) -> for screen recording
    - ffmpeg -> for convert video fomat
    - podman-desktop -> docker
    - Python3 + pip 
    - Go (golang)
    - Yarn
    - OpenShift CLI (oc)
    - kubectl
    - kustomize
    - Git
    - GitHub CLI (gh)
    - GNOME notification plugin -> libnotify, 提供 notify-send
    - VSCODE -> extentions for go, python, react would be installed at the same time
- `sync-repos.sh`
  Synchronizes your Git repositories with upstream forks.
- `repo-list.txt`
  A repo list file for `sync-repos.sh` to fork and optional upstream URLs

## Usages
```
# Run default installation  
./install-dev-tools-v3.sh

# Debug mode (verbose output)
bash -x ./install-dev-tools-v3.sh

# Sync repos to the current directory
./sync-repos.sh repo-list.txt .

# Sync repos to a specific folder
./sync-repos.sh repo-list.txt /home/wlin/workspaces

```