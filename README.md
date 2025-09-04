# fedora_setup

This repository contains scripts to quickly set up a **Fedora development environment** and manage multiple Git repositories. It is designed to make Fedora workstations ready for software development with common tools, VS Code extensions, and repository synchronization.

---

## 🗂 Repository Contents

- `install-dev-tools-v3.sh`  
  Installs development tools on Fedora including:
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