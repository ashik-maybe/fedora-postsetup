# Fedora Post-Install Scripts

Install baseline software on Fedora 44+. Scripts work on GNOME and Wayland.

## Install

    git clone https://github.com/ashik-maybe/fedora-postsetup.git --depth=1
    cd fedora-postsetup
    sudo ./fedora-postinstall.sh

`fedora-postinstall.sh` enables RPM Fusion and Flathub. It installs
multimedia codecs. It optimizes DNF. Run it first.

## Scripts

| Script | Purpose | Needs |
| --- | --- | --- |
| `fedora-postinstall.sh` | Baseline setup, codecs, RPM Fusion | root |
| `setup-intel-drivers.sh` | Intel VA-API, OpenCL, Vulkan, thermald | root |
| `add_gnome-extensions.sh` | Install 3 GNOME Shell extensions | GNOME |
| `remove-gnome-packages.sh` | Remove unused GNOME packages. Destructive. | `sudo` |
| `scripts/setup-virtualization.sh` | Install Virt-Manager and KVM. Use `--remove` to remove. | `sudo` |
| `scripts/setup-cloudflare-warp-wireguard.sh` | Install Cloudflare WARP. Use `--remove` to remove. | `sudo` |
| `scripts/setup-appimage-manager.sh` | Install Gear Lever and FUSE support | `sudo` for dnf |
| `scripts/browsers/install-brave-browser.sh` | Install Brave Browser | `sudo` for dnf |
| `scripts/browsers/install-google-chrome.sh` | Install Google Chrome | `sudo` for dnf |
| `scripts/patch/setup-bangla-fonts.sh` | Install Noto Bengali fonts | `sudo` for dnf |
| `scripts/dev-tools/setup-git-config.sh` | Install Git, SSH key, and commit signing | user |
| `scripts/dev-tools/install-vscodium.sh` | Install VSCodium. Validates repo first. | `sudo` for dnf |
| `scripts/dev-tools/install-cursor.sh` | Install Cursor IDE from the official repo | `sudo` for dnf |

Each script accepts `--dry-run` (no changes) and `--yes` (no prompts).
Each script is independent. Run it alone. Safe to re-run.

## Download to ~/bin

No scripts install this tool. Download it by hand. Put it in `~/bin`.

- [FFmpeg Static Builds](https://johnvansickle.com/ffmpeg/) — FFmpeg without dnf

## Notes

- Scripts target Fedora 44 and newer.
- `remove-gnome-packages.sh` deletes packages. Run `--dry-run` first.
- `add_gnome-extensions.sh` installs extensions. It does not enable them.
  Enable them in the Extensions app.
