#  Fedora Workstation Post Installation Scripts

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff)](#)
[![Fedora](https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=fff)](#)

Scripts to run after a fresh Fedora Workstation installation.

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
   ./fedora-postinstall.sh
   ```

<details>
<summary><b>📥 Download Essential Binaries (~/bin)</b></summary>
   
* [Zellij](https://github.com/zellij-org/zellij)
* [bottom](https://github.com/clementtsang/bottom)
* [FFmpeg Static Builds](https://johnvansickle.com/ffmpeg/)
* [yt-dlp](https://github.com/yt-dlp/yt-dlp)
* [Deno](https://github.com/denoland/deno)

</details>
