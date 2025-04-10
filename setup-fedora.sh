#!/bin/bash

# Step 0: Completely purge Firefox and LibreOffice
echo "Purging Firefox and LibreOffice..."
sudo dnf remove --purge firefox libreoffice* -y

# Remove leftover configuration files for Firefox and LibreOffice
rm -rf ~/.mozilla/firefox
rm -rf ~/.config/libreoffice
rm -rf ~/.local/share/libreoffice
rm -rf ~/.cache/libreoffice
sudo rm -rf /etc/firefox
sudo rm -rf /usr/lib64/firefox
sudo rm -rf /usr/share/libreoffice

# Clean up unused dependencies
sudo dnf autoremove -y

echo "Firefox and LibreOffice purged successfully."

# Step 1: Change the DNF configuration
echo "Configuring /etc/dnf/dnf.conf..."

# Backup the original dnf.conf file (just in case)
sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.backup

# Write the new configuration to dnf.conf
sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
color=auto
EOF

echo "/etc/dnf/dnf.conf updated successfully."

# Step 2: Add repositories (RPM Fusion, VS Code, GitHub Desktop, Cloudflare WARP, Google Chrome, Brave Browser)
echo "Adding RPM Fusion repositories..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "Adding Visual Studio Code repository..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

echo "Adding GitHub Desktop repository..."
sudo rpm --import https://mirror.mwt.me/shiftkey-desktop/gpgkey
sudo sh -c 'echo -e "[mwt-packages]\nname=GitHub Desktop\nbaseurl=https://mirror.mwt.me/shiftkey-desktop/rpm\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://mirror.mwt.me/shiftkey-desktop/gpgkey" > /etc/yum.repos.d/mwt-packages.repo'

echo "Adding Cloudflare WARP repository..."
curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo

echo "Adding Google Chrome repository..."
sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

echo "Adding Brave Browser repository..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

echo "All repositories added successfully."

# Step 3: Replace ffmpeg-free with proprietary ffmpeg
echo "Replacing ffmpeg-free with proprietary ffmpeg..."
sudo dnf swap ffmpeg-free ffmpeg -y --allowerasing

echo "Proprietary ffmpeg installed successfully."

# Step 4: Update all package lists
echo "Updating package lists..."
sudo dnf makecache

echo "Package lists updated successfully."

# Step 5: Upgrade all packages
echo "Upgrading all packages..."
sudo dnf upgrade -y

echo "All packages upgraded successfully."

# Step 6: Install Cloudflare WARP, VS Code, GitHub Desktop, Google Chrome, and Brave Browser
echo "Installing Cloudflare WARP, VS Code, GitHub Desktop, Google Chrome, and Brave Browser..."
sudo dnf install -y cloudflare-warp code github-desktop google-chrome-stable brave-browser

echo "Cloudflare WARP, VS Code, GitHub Desktop, Google Chrome, and Brave Browser installed successfully."

# Step 7: Install GNOME Tweaks, Extension Manager, yt-dlp, aria2, and Flatseal
echo "Installing GNOME Tweaks, Extension Manager, yt-dlp, aria2, and Flatseal..."
sudo dnf install gnome-tweaks yt-dlp aria2 -y

# Install Extension Manager via Flatpak
echo "Installing Extension Manager via Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.mattjakeman.ExtensionManager -y

# Install Flatseal via Flatpak
echo "Installing Flatseal via Flatpak..."
flatpak install flathub com.github.tchx84.Flatseal -y

echo "GNOME Tweaks, Extension Manager, yt-dlp, aria2, and Flatseal installed successfully."

# Step 8: Install GNOME Extensions
echo "Installing GNOME Extensions..."

# List of GNOME extensions to install (UUIDs)
EXTENSIONS=(
    "AlphabeticalAppGrid@stuarthayhurst"       # Alphabetical App Grid
    "blur-my-shell@aunetx"                     # Blur My Shell
    "appindicatorsupport@rgcjonas.gmail.com"   # AppIndicator Support
    "dash-to-dock@micxgx.gmail.com"           # Dash to Dock
)

# Install each extension using Extension Manager
for EXTENSION in "${EXTENSIONS[@]}"; do
    echo "Installing extension: $EXTENSION"
    flatpak run com.mattjakeman.ExtensionManager install "$EXTENSION"
done

echo "GNOME Extensions installed successfully."

# Step 9: Restore Fonts and Dotfiles from GitHub
echo "Restoring fonts and dotfiles from GitHub..."

# Hardcoded repository URL for dotfiles
DOTFILES_REPO_URL="https://github.com/ashik-md/dotfiles.git"

# Clone the dotfiles repository
DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
else
    echo "Dotfiles directory already exists. Pulling latest changes..."
    cd "$DOTFILES_DIR" && git pull
fi

# Run the install.sh script from the dotfiles repository
echo "Running install.sh from dotfiles repository..."
chmod +x "$DOTFILES_DIR/install.sh"
"$DOTFILES_DIR/install.sh"

echo "Fonts and dotfiles restored successfully."

# Step 10: Enable Wayland Support for Google Chrome and Brave Browser (Optional)
read -p "Do you want to enable Wayland support for Google Chrome and Brave Browser? (y/n): " ENABLE_WAYLAND

if [[ "$ENABLE_WAYLAND" == "y" || "$ENABLE_WAYLAND" == "Y" ]]; then
    echo "Enabling Wayland support for Google Chrome and Brave Browser..."

    # Hardcoded repository URL for primary repo
    PRIMARY_REPO_URL="https://github.com/ashik-md/fedora-postinstall-scripts.git"
    PRIMARY_REPO_DIR="$HOME/fedora-postinstall-scripts"

    # Clone or update the primary repository
    if [ ! -d "$PRIMARY_REPO_DIR" ]; then
        echo "Cloning primary repository..."
        git clone "$PRIMARY_REPO_URL" "$PRIMARY_REPO_DIR"
    else
        echo "Primary repository directory already exists. Pulling latest changes..."
        cd "$PRIMARY_REPO_DIR" && git pull
    fi

    # Verify that Google Chrome and Brave Browser are not Flatpaks
    if ! rpm -q google-chrome-stable &>/dev/null; then
        echo "Google Chrome is not installed via RPM. Skipping Wayland setup for Google Chrome."
    else
        echo "Modifying Google Chrome .desktop file..."
        cp "$PRIMARY_REPO_DIR/google-chrome.desktop" ~/.local/share/applications/
        chmod +x ~/.local/share/applications/google-chrome.desktop
    fi

    if ! rpm -q brave-browser &>/dev/null; then
        echo "Brave Browser is not installed via RPM. Skipping Wayland setup for Brave Browser."
    else
        echo "Modifying Brave Browser .desktop file..."
        cp "$PRIMARY_REPO_DIR/brave-browser.desktop" ~/.local/share/applications/
        chmod +x ~/.local/share/applications/brave-browser.desktop
    fi

    # Update the application menu database
    echo "Updating the application menu database..."
    update-desktop-database ~/.local/share/applications/

    echo "Wayland support enabled for Google Chrome and Brave Browser."
else
    echo "Skipping Wayland support setup."
fi

echo "Setup complete! Enjoy your fresh Fedora installation."