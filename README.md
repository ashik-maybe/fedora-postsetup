# 🐧 Fedora Workstation Post Insatall Scripts

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff)](#)
[![Fedora](https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=fff)](#)

Scripts to run after a fresh Fedora Workstation installation.

> ⚠️ **[IMPORTANT]**
> On the very first boot after installation, ensure **`Enable Third-Party Repositories`** is checked in the initial setup process.

⚠️ **Codecs for Intel iGPU** *(install after rpm-fusion is enabled)*

```bash
sudo dnf install intel-media-driver libva-utils
```

<details>

<summary> 💡 FYI: GPU Firmware Cleanup </summary>

If you only use an **Intel iGPU**, there's no need to keep AMD or NVIDIA GPU firmware updated. Removing them can save space and upgrade time:

```bash
sudo dnf remove amd-gpu-firmware amd-ucode-firmware
sudo dnf remove nvidia-gpu-firmware
```

</details>

> 🚫 **[CAUTION]**
> Installing `docker` on a system with `virt-manager` (virtualization) installed can interfere with VM network connections.
> 📘 [Fix Docker vs Virt-Manager Networking Conflict](scripts/dev-tools/fedora-docker-vm-networking-fix.md)

### ▶️ Usage

1.  Clone the repository:
    ```bash
    git clone https://github.com/ashik-maybe/fedora-postsetup.git
    ```
2.  Navigate to the directory:
    ```bash
    cd fedora-postsetup
    ```
3.  Run the script:
    ```bash
    ./fedora-postinstall-optimization.sh
    ```
