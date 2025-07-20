# 🚀 Fedora Fresh Installation Scripts

A collection of sleek, automated scripts to set up and optimize **Fedora Workstation** after a fresh install.

---

## ✨ Features

- ⚙️ **System Optimization** — DNF tweaks, SSD trim, cleanup
- 🧰 **Essential Tools** — yt-dlp, aria2, GNOME Tweaks, virt-manager
- 🌐 **3rd-Party Repos** — RPM Fusion, VS Code, GitHub Desktop, Chrome
- 🛡️ **Cloudflare WARP** — Easy install & config
- 🌍 **Browser Setup** — Chrome & Brave with optional Wayland support
- 📦 **Flatpak Support** — Flathub ready out of the box
- 💬 **Interactive & Modular** — Choose what to install, skip what you don't

---

## 📁 What's Inside

| File                         | Purpose                                  |
|-----------------------------|------------------------------------------|
| `fedora-postinstall.sh`     | Main post-install script (automated)     |
| `fedora-dev-setup.sh`       | Dev tools setup: Github Desktop, VS Code |
| `force-browsers-wayland.sh` | Optional Wayland tweaks for browsers     |
| `*.desktop`                 | Custom launchers for Wayland support     |

---

## 🚦 Quick Start

```bash
git clone https://github.com/ashik-maybe/fedora-fresh-installation-scripts.git
cd fedora-fresh-installation-scripts
chmod +x *.sh
./fedora-postinstall.sh
