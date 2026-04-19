# dotfiles

Personal environment setup for MacOS and Linux.

## Quick start

```bash
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## What it do

1. **Bootstrap** — detects OS and architecture, validates dependencies (git, curl), checks bash version
2. **Link dotfiles** — symlinks everything in `dots/` into `$HOME`, backing up any existing files to `.bak`
3. **Install packages** — reads `packages/brew.txt` (macOS) or `packages/apt.txt` (Linux), installs missing packages
4. **OS-specific setup** — applies macOS system preferences via `defaults write`, or runs Linux-specific config


## Repository layout

```
dotfiles/
  install.sh                  # entry point
  packages/
    brew.txt                  # macOS packages
    apt.txt                   # Linux packages
    post_install_macos.sh     # manual/post-brew steps (placeholder)
    post_install_linux.sh     # manual/post-apt steps (placeholder)
  scripts/
    bootstrap.sh              # OS/arch detection, dep checks
    link_dots.sh              # symlinker
    install_packages.sh       # package installation
    macos_defaults.sh         # macOS system preferences
    linux_setup.sh            # Linux-specific config
    verify.sh                 # post-install summary
  dots/
    .bashrc
    .bash_aliases
    .vimrc
    .tmux.conf
  lib/
    log.sh                    # shared logging
    utils.sh                  # shared helpers
```

## macOS: default shell

The installer sets Homebrew bash (`$(brew --prefix)/bin/bash`) as the default shell. 

