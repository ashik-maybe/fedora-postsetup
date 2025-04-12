#!/bin/bash

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

error_handler() {
    echo -e "${RED}Error: $1${RESET}"
}

run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}Running: $cmd${RESET}"
    eval "$cmd"
    if [ $? -ne 0 ]; then
        error_handler "Command failed: $cmd"
        return 1
    fi
}

ask_yes_no() {
    local question="$1"
    while true; do
        echo -e "${YELLOW}$question (y/n): ${RESET}"
        read -r response
        case "$response" in
            [Yy]* ) return 0 ;;  # User answered "yes"
            [Nn]* ) return 1 ;;  # User answered "no"
            * ) echo -e "${RED}Please answer 'y' for yes or 'n' for no.${RESET}" ;;
        esac
    done
}

repo_exists() {
    local repo_name="$1"
    if grep -q "\[$repo_name\]" /etc/yum.repos.d/*.repo; then
        return 0
    else
        return 1
    fi
}

add_dev_repos() {
    echo -e "${GREEN}Adding developer repositories...${RESET}"

    if ! repo_exists "vscode"; then
        run_cmd "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
        run_cmd "echo -e \"[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc\" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null"
    fi

    if ! repo_exists "mwt-packages"; then
        run_cmd "sudo rpm --import https://mirror.mwt.me/shiftkey-desktop/gpgkey"
        run_cmd "sudo sh -c 'echo -e \"[mwt-packages]
name=GitHub Desktop
baseurl=https://mirror.mwt.me/shiftkey-desktop/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirror.mwt.me/shiftkey-desktop/gpgkey\" > /etc/yum.repos.d/mwt-packages.repo'"
    fi
}

install_core_dev_tools() {
    if ask_yes_no "Do you want to install Visual Studio Code?"; then
        run_cmd "sudo dnf install -y code"
    else
        echo -e "${YELLOW}Skipping Visual Studio Code installation.${RESET}"
    fi

    if ask_yes_no "Do you want to install GitHub Desktop?"; then
        run_cmd "sudo dnf install -y github-desktop"
    else
        echo -e "${YELLOW}Skipping GitHub Desktop installation.${RESET}"
    fi

    if ! command -v git &> /dev/null; then
        if ask_yes_no "Do you want to install Git?"; then
            run_cmd "sudo dnf install -y git"
        else
            echo -e "${YELLOW}Skipping Git installation.${RESET}"
        fi
    else
        echo -e "${YELLOW}Git is already installed. Skipping.${RESET}"
    fi
}

install_ml_tools() {
    if ask_yes_no "Do you want to install machine learning tools (Python, pandas, numpy, scikit-learn, TensorFlow)?"; then
        run_cmd "sudo dnf install -y python3 python3-pip"
        run_cmd "pip3 install --upgrade pip"
        run_cmd "pip3 install pandas numpy scikit-learn tensorflow jupyterlab"
    else
        echo -e "${YELLOW}Skipping machine learning tools installation.${RESET}"
    fi
}

install_web_dev_tools() {
    if ask_yes_no "Do you want to install web development tools (Node.js, React, Express.js, MongoDB)?"; then
        run_cmd "sudo dnf install -y nodejs npm"
        run_cmd "sudo npm install -g create-react-app express-generator"
        if ! command -v mongod &> /dev/null; then
            run_cmd "sudo dnf install -y mongodb mongodb-server"
            run_cmd "sudo systemctl enable mongod"
            run_cmd "sudo systemctl start mongod"
        fi
    else
        echo -e "${YELLOW}Skipping web development tools installation.${RESET}"
    fi
}

install_flutter() {
    if ask_yes_no "Do you want to install Flutter?"; then
        FLUTTER_DIR="$HOME/development/flutter"
        DOWNLOAD_DIR="$HOME/Downloads"
        run_cmd "mkdir -p $DOWNLOAD_DIR $FLUTTER_DIR"
        FLUTTER_URL=$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json | jq -r '.current_release.stable as $stable | .releases[] | select(.hash == $stable) | .archive')
        FLUTTER_ARCHIVE="$DOWNLOAD_DIR/$(basename $FLUTTER_URL)"
        run_cmd "curl -L --progress-bar $FLUTTER_URL -o $FLUTTER_ARCHIVE"
        run_cmd "tar -xf $FLUTTER_ARCHIVE -C $(dirname $FLUTTER_DIR)"
        run_cmd "mv $FLUTTER_DIR/flutter/* $FLUTTER_DIR/"
        run_cmd "rm -rf $FLUTTER_DIR/flutter"
        SHELL_CONFIG=""
        if [[ "$SHELL" == *"bash"* ]]; then
            SHELL_CONFIG="$HOME/.bashrc"
        elif [[ "$SHELL" == *"zsh"* ]]; then
            SHELL_CONFIG="$HOME/.zshrc"
        fi
        if ! grep -q "export PATH=\"\$HOME/development/flutter/bin:\$PATH\"" $SHELL_CONFIG; then
            run_cmd "echo 'export PATH=\"\$HOME/development/flutter/bin:\$PATH\"' >> $SHELL_CONFIG"
            run_cmd "source $SHELL_CONFIG"
        fi
        run_cmd "flutter doctor"
    else
        echo -e "${YELLOW}Skipping Flutter installation.${RESET}"
    fi
}

install_java_tools() {
    if ask_yes_no "Do you want to install Java development tools (OpenJDK, Maven, Gradle)?"; then
        run_cmd "sudo dnf install -y java-latest-openjdk java-latest-openjdk-devel maven gradle"
    else
        echo -e "${YELLOW}Skipping Java development tools installation.${RESET}"
    fi
}

install_rust_tools() {
    if ask_yes_no "Do you want to install Rust development tools?"; then
        if ! command -v rustc &> /dev/null; then
            run_cmd "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
            run_cmd "source $HOME/.cargo/env"
        fi
    else
        echo -e "${YELLOW}Skipping Rust development tools installation.${RESET}"
    fi
}

install_go_tools() {
    if ask_yes_no "Do you want to install Go development tools?"; then
        if ! command -v go &> /dev/null; then
            run_cmd "sudo dnf install -y golang"
        fi
    else
        echo -e "${YELLOW}Skipping Go development tools installation.${RESET}"
    fi
}

install_c_cpp_tools() {
    if ask_yes_no "Do you want to install C/C++ development tools (GCC, G++, Clang, Boost)?"; then
        run_cmd "sudo dnf install -y gcc gcc-c++ make cmake clang gdb boost boost-devel"
    else
        echo -e "${YELLOW}Skipping C/C++ development tools installation.${RESET}"
    fi
}

install_database_tools() {
    if ask_yes_no "Do you want to install database tools (MySQL, PostgreSQL, SQLite)?"; then
        run_cmd "sudo dnf install -y mysql mysql-server postgresql postgresql-server sqlite"
        if ! systemctl is-enabled postgresql &> /dev/null; then
            run_cmd "sudo postgresql-setup --initdb"
            run_cmd "sudo systemctl enable postgresql"
            run_cmd "sudo systemctl start postgresql"
        fi
        if ask_yes_no "Do you want to install pgAdmin (PostgreSQL GUI)?"; then
            run_cmd "flatpak install -y flathub org.pgadmin.pgadmin4"
        fi
    else
        echo -e "${YELLOW}Skipping database tools installation.${RESET}"
    fi
}

install_devops_tools() {
    if ask_yes_no "Do you want to install DevOps tools (Docker, Kubernetes, Terraform)?"; then
        if ! command -v docker &> /dev/null; then
            run_cmd "sudo dnf install -y docker"
            run_cmd "sudo systemctl enable docker"
            run_cmd "sudo systemctl start docker"
        fi
        if ! command -v minikube &> /dev/null; then
            run_cmd "sudo dnf install -y conntrack"
            run_cmd "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
            run_cmd "sudo install minikube-linux-amd64 /usr/local/bin/minikube"
        fi
        if ! command -v terraform &> /dev/null; then
            run_cmd "sudo dnf install -y dnf-plugins-core"
            run_cmd "sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
            run_cmd "sudo dnf install -y terraform"
        fi
    else
        echo -e "${YELLOW}Skipping DevOps tools installation.${RESET}"
    fi
}

install_scripting_languages() {
    if ask_yes_no "Do you want to install scripting languages (Ruby, PHP, Perl)?"; then
        if ! command -v ruby &> /dev/null; then
            run_cmd "sudo dnf install -y ruby ruby-devel"
            run_cmd "gem install bundler"
        fi
        if ! command -v php &> /dev/null; then
            run_cmd "sudo dnf install -y php php-cli php-json php-mbstring"
            run_cmd "curl -sS https://getcomposer.org/installer | php"
            run_cmd "sudo mv composer.phar /usr/local/bin/composer"
        fi
        if ! command -v perl &> /dev/null; then
            run_cmd "sudo dnf install -y perl perl-CPAN"
        fi
    else
        echo -e "${YELLOW}Skipping scripting languages installation.${RESET}"
    fi
}

clear
echo -e "${CYAN}Fedora Developer Setup Script Starting...${RESET}"
sudo -v || { echo -e "${RED}Failed to acquire sudo privileges. Exiting.${RESET}"; exit 1; }

add_dev_repos

if ask_yes_no "Do you want to install core development tools (VS Code, GitHub Desktop, Git)?"; then
    install_core_dev_tools
else
    echo -e "${YELLOW}Skipping core development tools installation.${RESET}"
fi

echo -e "${YELLOW}
What type of development setup do you need?
1. Web Development (MERN Stack)
2. Flutter
3. Machine Learning
4. Java Development
5. C/C++ Development
6. Rust Development
7. Go Development
8. Database Tools
9. DevOps Tools
10. Scripting Languages
11. Skip additional development tools
${RESET}"

read -r choice

case "$choice" in
    1) install_web_dev_tools ;;
    2) install_flutter ;;
    3) install_ml_tools ;;
    4) install_java_tools ;;
    5) install_c_cpp_tools ;;
    6) install_rust_tools ;;
    7) install_go_tools ;;
    8) install_database_tools ;;
    9) install_devops_tools ;;
    10) install_scripting_languages ;;
    11) echo -e "${YELLOW}Skipping additional development tools.${RESET}" ;;
    *) echo -e "${RED}Invalid choice. Skipping additional development tools.${RESET}" ;;
esac

echo -e "${CYAN}Script completed.${RESET}"
