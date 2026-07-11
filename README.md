#  Fedora Workstation Post Installation Scripts

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff)](#)
[![Fedora](https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=fff)](#)

Scripts to run after a fresh Fedora Workstation installation.

> ⚠️ **[IMPORTANT]**  
> On the very first boot after installation, ensure **`Enable Third-Party Repositories`** is checked in the initial setup process.

## ▶️ Usage & Automation

The main script automatically optimizes your DNF configuration, enables RPM Fusion, handles systemic cleanup, and installs all **baseline multimedia codecs** (FFmpeg swap, GStreamer plugins, and OpenH264 support).

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ashik-maybe/fedora-postsetup.git --depth=1
   ```

2. **Navigate to the directory:**
   ```bash
   cd fedora-postsetup
   ```

3. **Run the script:**
   ```bash
   ./fedora-postinstall-optimization.sh
   ```

<details>
<summary><strong> Optional: Bangla Font Installation (Recommended)</strong></summary>

If you notice text rendering looking "off" on heavy UI sites like Facebook or YouTube when mixing English and Bangla, install this modern, high-legibility Unicode font stack designed for long reading sessions.

### Download Fonts

Download these three dual-script Unicode engines from Google Fonts:

- **[Anek Bangla](https://fonts.google.com/specimen/Anek+Bangla)** (Ultra-modern tech/system UI font)  

- **[Hind Siliguri](https://fonts.google.com/specimen/Hind+Siliguri)** (Monolinear UI specialist for sharp, tiny text grids)  

- **[Tiro Bangla](https://fonts.google.com/specimen/Tiro+Bangla)** (Harvard-commissioned literary font for long-form essays)  

### Installation Steps

1. Move the `.ttf` or `.otf` files into your local user fonts directory:
   ```bash
   mkdir -p ~/.local/share/fonts
   cp ~/Downloads/*.ttf ~/.local/share/fonts/
   fc-cache -fv
   ```

2. Open your browser settings (Firefox/Chrome) → **Fonts**, and assign them exactly like this:
   - **Standard:** Anek Bangla
   - **Serif:** Tiro Bangla
   - **Sans-Serif:** Hind Siliguri

</details>

---

## ⚙️ Optional Hardware Optimizations

If you are running on specific hardware, apply these extra manual steps after running the main script above.

### 1. Intel iGPU Hardware Video Acceleration

For Intel Integrated Graphics, install the user-space driver and Mesa freeworld translation layers to enable hardware-accelerated video decoding in browsers and media players:

```bash
sudo dnf install -y intel-media-driver mesa-va-drivers-freeworld libva-utils
```

If you only use an **Intel iGPU**, there's no need to keep heavy AMD or NVIDIA GPU firmware packages updated on your system. Removing them saves significant disk space and shortens kernel upgrade times:

```bash
# Keep intel-gpu-firmware and microcode, remove the rest safely
sudo dnf remove -y amd-gpu-firmware amd-ucode-firmware nvidia-gpu-firmware
```

---

> 🚫 **[CAUTION]**  
> Installing `docker` on a system with `virt-manager` (virtualization) installed can interfere with VM network connections.  
> 📘 [Fix Docker vs Virt-Manager Networking Conflict](https://www.google.com/search?q=scripts/dev-tools/fedora-docker-vm-networking-fix.md)
