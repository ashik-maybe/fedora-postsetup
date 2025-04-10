# Fedora Setup Scripts

**Fedora Setup Scripts** is a collection of automated scripts for streamlining the post-installation setup on a fresh Fedora system. It optimizes system settings, installs essential software, configures repositories, and sets up Cloudflare WARP and browsers (Chrome & Brave) with optional Wayland support.

## Features:
- Optimize `dnf` settings for faster package management.
- Add third-party repositories (e.g., RPM Fusion, Visual Studio Code, GitHub Desktop).
- Replace free FFmpeg with the proprietary version.
- Install essential tools like `yt-dlp`, `aria2c`, and `gnome-tweaks`.
- Set up Cloudflare WARP CLI.
- Install and optionally configure browsers (Google Chrome & Brave) with support for Wayland.

## Files:
- **`fedora-postinstall.sh`**: Main script for post-installation tasks (optimizes `dnf`, adds repos, installs software).
- **`force-browsers-wayland.sh`**: Script to enforce Wayland support for Brave and Chrome browsers (use after the main setup).
- **`brave-browser.desktop`**: Custom `.desktop` entry for Brave to ensure Wayland support.
- **`google-chrome.desktop`**: Custom `.desktop` entry for Chrome to ensure Wayland support.
- **`README.md`**: Documentation for the repo (this file).

## How to Use:

1. **Clone the repo**:
   ```bash
   git clone https://github.com/yourusername/fedora-setup-scripts.git
   cd fedora-setup-scripts
   ```

2. **Give execution permission**:
   ```bash
   chmod +x *.sh
   ```

3. **Run the Setup Script**:
   ```bash
   ./fedora-postinstall.sh
   ```

4. **Optional: Force Wayland for browsers (Brave & Chrome)**:
   If you need to configure Brave and Chrome to use Wayland, run:
   ```bash
   ./force-browsers-wayland.sh
   ```

   Follow the on-screen prompts to customize the Wayland setup for each browser.
