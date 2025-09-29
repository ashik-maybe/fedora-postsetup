# scripts to run after a fresh fedora workstation installation

### fyi

`run-this-before-fedora-postinstall.sh` cuts down on packages (like alot) to upgrade + remove amd / nvidia drivers, if only igpu is present.

`fedora-postinstall.sh` optimizes dnf configs, adds rpm-fusion, swaps ffmpeg-free with non-free one, upgrades system, enables fstrim for ssd.

refrain from installing docker in a system that has virt-manager (virutalization) installed, it messes up the vm internet connection, go for `podman`.

### just paste this in the terminal

```bash
git clone https://github.com/ashik-maybe/fedora-fresh-installation-scripts.git
cd fedora-fresh-installation-scripts
```

then `./` the `.sh` file.

#### note to self

don't fix it, don't upgrade it, just don't touch it! just leave it be! **don't fix it if ain't broke.**
