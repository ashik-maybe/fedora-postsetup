# Fedora Workstation Post Insatall Scripts

Scripts to run after a fresh Fedora Workstation installation.

> [IMPORTANT]
> On the very first boot after installation, ensure `Enable Third-Party Repositories` is checked in the initial setup process.

### FYI

If you only use an Intel iGPU, there's no need to keep AMD or NVIDIA GPU firmware updated. Removing them can save space and upgrade time:

```bash
sudo dnf remove amd-gpu-firmware
sudo dnf remove nvidia-gpu-firmware
```

> [CAUTION]
> Avoid installing `docker` on a system with `virt-manager` (virtualization) installed. It can interfere with VM network connections. Consider using `podman` instead.

### Usage

1.  Clone the repository:
    ```bash
    git clone https://github.com/ashik-maybe/fedora-fresh-install-scripts.git
    ```
2.  Navigate to the directory:
    ```bash
    cd fedora-fresh-install-scripts
    ```
3.  Run the script:
    ```bash
    ./fedora-postinstall-optimization.sh
    ```
