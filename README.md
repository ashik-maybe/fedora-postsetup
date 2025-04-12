# Fedora Fresh Installation Scripts

**Fedora Fresh Installation Scripts** is a collection of automated scripts designed to streamline the setup process on a fresh Fedora installation. These scripts optimize system performance, install essential software, configure third-party repositories, and set up tools like Cloudflare WARP, browsers (Google Chrome & Brave), and more. Whether you're a developer, power user, or just someone who wants a hassle-free Fedora experience, these scripts have got you covered!

---

## Features

- **System Optimization**:
  - Optimize `dnf.conf` for faster package management.
  - Enable `fstrim` for SSDs to improve longevity and performance.
  - Clean up unnecessary packages and cache after installation.

- **Third-Party Repositories**:
  - Add repositories for RPM Fusion, Visual Studio Code, GitHub Desktop, and Google Chrome.
  - Replace free FFmpeg with the proprietary version for better multimedia support.

- **Essential Tools**:
  - Install tools like `yt-dlp`, `aria2c`, `gnome-tweaks`, and `Extension Manager`.
  - Set up virtualization tools (`virt-manager`) for developers.

- **Cloudflare WARP CLI**:
  - Install and configure Cloudflare WARP for secure DNS and encrypted traffic.

- **Browsers**:
  - Install Google Chrome and Brave Browser.
  - Optional Wayland support for both browsers using custom `.desktop` files.

- **Flatpak Support**:
  - Ensure Flatpak and Flathub are configured for easy app installation.

- **Customizable**:
  - Prompts allow you to choose which components to install, ensuring flexibility.

---

## Files Included

| File Name                     | Description                                                                 |
|-------------------------------|-----------------------------------------------------------------------------|
| `fedora-postinstall.sh`       | Main script for post-installation tasks (optimizes system, installs tools). |
| `dev-setup.sh`                | Developer-focused script for setting up coding environments and tools.      |
| `force-browsers-wayland.sh`   | Enforces Wayland support for Brave and Chrome browsers.                     |
| `brave-browser.desktop`       | Custom `.desktop` entry for Brave to ensure Wayland support.                |
| `google-chrome.desktop`       | Custom `.desktop` entry for Chrome to ensure Wayland support.               |

---

## How to Use

### 1. Clone the Repository
```bash
git clone https://github.com/ashik-md/fedora-fresh-installation-scripts.git
cd fedora-fresh-installation-scripts
```

### 2. Make Scripts Executable
```bash
chmod +x *.sh
```

### 3. Run the Post-Installation Script
Execute the main script to optimize your system and install essential tools:
```bash
./fedora-postinstall.sh
```
Follow the on-screen prompts to customize the setup process.

### 4. (Optional) Force Wayland for Browsers
If you want to enable Wayland support for Brave and Chrome, run:
```bash
./force-browsers-wayland.sh
```

### 5. Developer Setup (Optional)
For a developer-focused environment, run:
```bash
./dev-setup.sh
```
This script installs tools like Git, VS Code, GitHub Desktop, Docker, and more.

---

## Notes

- **Wayland Support**: The custom `.desktop` files (`brave-browser.desktop` and `google-chrome.desktop`) ensure that Brave and Chrome use Wayland instead of X11. This is particularly useful for users running Fedora with GNOME on Wayland.
  
- **Customization**: The scripts are designed to be flexible. You can skip certain steps or modify the scripts to suit your specific needs.

- **Compatibility**: These scripts are tested on Fedora Workstation (GNOME desktop). If you're using a different desktop environment, some features (e.g., GNOME Tweaks) may not apply.

---

## Contributing

Contributions are welcome! If you have suggestions, bug fixes, or new features to add, feel free to open an issue or submit a pull request.

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## Credits

- Inspired by community-driven Fedora post-installation guides.
- Thanks to the Fedora, GNOME, and open-source communities for their amazing work.

---

Feel free to star ⭐ this repository if you find it helpful! 😊
