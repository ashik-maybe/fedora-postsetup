# scripts to run after a fresh fedora workstation installation

### fyi

if you don't have external or internal AMD / Nvidia; remove them with;

```bash
sudo dnf remove amd-gpu-firmware
sudo dnf remove nvidia-gpu-firmware
```

`fedora-postinstall.sh` optimizes dnf configs, adds rpm-fusion, swaps ffmpeg-free with non-free one, upgrades system, enables fstrim for ssd.

refrain from installing `docker` in a system that has `virt-manager` (virutalization) installed, it messes up the vm internet connection, go for `podman`.

### just paste this in the terminal

```bash
git clone https://github.com/ashik-maybe/fedora-fresh-installation-scripts.git
cd fedora-fresh-installation-scripts
```

then `./` the `.sh` file.

#### note to self

don't fix it, don't upgrade it, just don't touch it! just leave it be! **don't fix it if ain't broke.**
