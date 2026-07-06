# 🐧 Fedora Workstation Post Installation Scripts

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff)](#)
[![Fedora](https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=fff)](#)

Scripts to run after a fresh Fedora Workstation installation.

> ⚠️ **[IMPORTANT]**
> On the very first boot after installation, ensure **`Enable Third-Party Repositories`** is checked in the initial setup process.

🎥 **Codecs & Hardware Acceleration for Intel iGPU** *(Run after RPM Fusion is enabled)*

```bash
# Enable Cisco OpenH264 repo for browser-based video calls
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Install full system multimedia codecs, GStreamer plugins, and OpenH264
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

# Install Mesa freeworld and Intel video drivers for hardware decoding
sudo dnf install -y mesa-va-drivers-freeworld intel-media-driver libva-utils
```

If you only use an **Intel iGPU**, there's no need to keep AMD or NVIDIA GPU firmware updated. Removing them saves disk space and shortens upgrade times:

```bash
# Keep intel-gpu-firmware and microcode, remove the rest
sudo dnf remove -y amd-gpu-firmware amd-ucode-firmware nvidia-gpu-firmware
```

> 🚫 **[CAUTION]**
> Installing `docker` on a system with `virt-manager` (virtualization) installed can interfere with VM network connections.
> 📘 [Fix Docker vs Virt-Manager Networking Conflict](https://www.google.com/search?q=scripts/dev-tools/fedora-docker-vm-networking-fix.md)

### ▶️ Usage

1. Clone the repository:
```bash
git clone [https://github.com/ashik-maybe/fedora-postsetup.git](https://github.com/ashik-maybe/fedora-postsetup.git)
```


2. Navigate to the directory:
```bash
cd fedora-postsetup
```


3. Run the script:
```bash
./fedora-postinstall-optimization.sh
```
