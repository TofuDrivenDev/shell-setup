#!/bin/bash
set -e

# Add some color to the output for better readability
INFO="\033[1;34m" # Blue
OK="\033[1;32m" # Green
ERR="\033[1;31m" # Red
RESET="\033[0m"

# Helper function to check for a command and install a package if it's missing.
# Usage: install_package <command_to_check> [package_to_install]
install_package() {
    local cmd_check="$1"
    local pkg_name="${2:-$cmd_check}"

    if ! command -v "$cmd_check" &> /dev/null; then
        echo -e "${INFO}🛠️ Installing $pkg_name...${RESET}"
        $PKG_CMD install "$pkg_name"
    fi

    echo -e "${OK}✅ $pkg_name has been installed.${RESET}"
}

# Ensure a line exists in a file.
#
# Usage: ensure_line_in_file <line_to_add> <file_path>
ensure_line_in_file() {
    local line="$1"
    local file="$2"

    if ! grep -qF -- "$line" "$file"; then
        # If the file is missing a trailing newline, add one first.
        if [ -s "$file" ] && [ "$(tail -c1 "$file")" != "" ]; then    
            echo "" >> "$file"
        fi
        
        echo "$line" >> "$file"
    fi
}

# Remove app from quarantine on macOS
unquarantine_app() {
    local app_path="$1"

    if ! [[ -d "$app_path" ]]; then
        echo -e "${ERR}❌ $app_path does not exist.${RESET}"
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${INFO}🛠️ Removing $app_path from quarantine...${RESET}"
        xattr -d com.apple.quarantine "$app_path"
        echo -e "${OK}✅ Removed $app_path from quarantine.${RESET}"
    fi  
}


# Determine the package manager based on the OS
if [[ -f /etc/debian_version ]]; then
    PKG_MGR="apt"
    PKG_CMD="sudo apt"
elif [[ -f /etc/redhat-release ]]; then
    PKG_MGR="yum"
    PKG_CMD="sudo yum -y"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${INFO}🛠️ Installing Homebrew...${RESET}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo -e "${OK}✅ Homebrew has been installed.${RESET}"

    PKG_MGR="brew"
    PKG_CMD="brew"
else
    echo "Unsupported OS. Please configure the package manager manually."
    exit 1
fi
echo -e "${INFO}Package manager set to: $PKG_MGR${RESET}"


# Update package registry
if [[ "$1" == "-u" ]]; then
    echo -e "${INFO}Updating package manager...${RESET}"
    $PKG_CMD update
fi


install_package 'tldr' # https://github.com/tldr-pages/tldr#how-do-i-use-it
install_package 'bat' # https://github.com/sharkdp/bat#installation
install_package 'duf' # https://github.com/muesli/duf#installation
install_package 'lazygit' # https://github.com/jesseduffield/lazygit#installation
install_package 'lazydocker' # https://github.com/jesseduffield/lazydocker#installation
install_package 'tmux' # https://github.com/tmux/tmux#installation
install_package 'jq' # https://github.com/jqlang/jq#installation
install_package 'fzf' # https://github.com/junegunn/fzf#installation
install_package 'zoxide' # https://github.com/ajeetdsouza/zoxide#installation
install_package 'bruno' # https://github.com/usebruno/bruno#installation
install_package 'zstd' # https://facebook.github.io/zstd/


install_node() {
    # Can't use command -v bcuz nvm is weird
    if ! [ -n "$NVM_DIR" ] &> /dev/null; then
        echo -e "${INFO}🛠️ Installing NVM...${RESET}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
    fi
    echo -e "${OK}✅ NVM has been installed.${RESET}"

    if ! command -v node &> /dev/null; then
        echo -e "${INFO}🛠️ Installing Node.js...${RESET}"
        nvm install --lts
    fi
    echo -e "${OK}✅ Node.js has been installed.${RESET}"

    if ! command -v pnpm &> /dev/null; then
        echo -e "${INFO}🛠️ Installing pnpm...${RESET}"
        curl -fsSL https://get.pnpm.io/install.sh | sh -
    fi
    echo -e "${OK}✅ pnpm has been installed.${RESET}"
}
install_node


install_fd() { # https://github.com/sharkdp/fd#installation
    if ! command -v fd &> /dev/null; then
        echo -e "${INFO}🛠️ Installing fd...${RESET}"

        if [[ "$PKG_MGR" == "apt" ]]; then
            $PKG_CMD install fd-find
            ln -s "$(which fdfind)" /usr/local/bin/fd # fd -> fdfind
        else
            $PKG_CMD install fd
        fi
    fi

    echo -e "${OK}✅ fd has been installed.${RESET}"
}
install_fd


install_ripgrep() { # https://github.com/BurntSushi/ripgrep#installation
    if ! command -v rg &> /dev/null; then
        echo -e "${INFO}🛠️ Installing ripgrep...${RESET}"

        if [[ "$PKG_MGR" == "yum" ]]; then
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
            sudo yum install ripgrep
        else
            $PKG_CMD install ripgrep
        fi
    fi
    
    echo -e "${OK}✅ ripgrep has been installed.${RESET}"
}
install_ripgrep


install_autojump() { # https://github.com/wting/autojump#installation
     if ! command -v autojump &> /dev/null; then
        echo -e "${INFO}🛠️ Installing autojump...${RESET}"
        # TODO: debian needs manual activation
        # https://github.com/wting/autojump#installation
        $PKG_CMD install autojump 
    fi

    echo -e "${OK}✅ autojump has been installed.${RESET}"
}
install_autojump


install_autoenv() { # https://github.com/hyperupcall/autoenv#installation-automated
    if ! grep -q "autoenv/activate.sh" "$HOME/.zshrc"; then
        echo -e "${INFO}🛠️ Installing autoenv...${RESET}"
        curl -#fLo- 'https://raw.githubusercontent.com/hyperupcall/autoenv/main/scripts/install.sh' | sh
    fi

    echo -e "${OK}✅ autoenv has been installed.${RESET}"
}
install_autoenv


install_terminal_notifier() { # https://github.com/julienXX/terminal-notifier#download
    if [[ "$PKG_MGR" == "brew" ]]; then
        install_package 'terminal-notifier'
    fi
}
install_terminal_notifier


install_oh_my_zsh() { # https://github.com/ohmyzsh/ohmyzsh/wiki
    install_package 'zsh' # https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH

    if ! [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${INFO}🛠️ Installing Oh My Zsh...${RESET}"
        # The installer might try to run zsh; pass a no-op command to prevent it from exiting the script
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    echo -e "${OK}✅ Oh My Zsh has been installed.${RESET}"
}
install_oh_my_zsh


configure_oh_my_zsh() {
    local zshrc="$HOME/.zshrc"
    if ! [[ -f "$zshrc" ]]; then
        echo -e "${ERR}❌ $zshrc is missing.${RESET}"
        exit 1
    fi
    
    echo -e "${INFO}🛠️ Configuring Oh My Zsh...${RESET}"
    
    # Setup theme
    # risto re5et pygmalion obraun michelebologna lukerandall kafeitu
    sed -i '' 's#^ZSH_THEME="[^"]*"#ZSH_THEME="pygmalion"#' "$zshrc"
    
    # Setup plugins
    local plugins_line='plugins=(alias-finder autoenv autojump bgnotify colored-man-pages command-not-found gh git git-auto-fetch gradle node npm nvm pip pipenv safe-paste ssh vscode yarn zoxide zsh-interactive-cd)'
    sed -i '' "s#^plugins=(.*)#$plugins_line#" "$zshrc"

    # Setup alias-finder
    local settings=("autoload" "longer" "exact" "cheaper")
    for setting in "${settings[@]}"; do
        ensure_line_in_file "zstyle ':omz:plugins:alias-finder' $setting yes" "$zshrc"
    done
    
    # Setup zsh-interactive-cd 
    ensure_line_in_file 'source <(fzf --zsh)' "$zshrc"
    
    # Setup zoxide
    ensure_line_in_file 'eval "$(zoxide init zsh)" # This must be the last line of .zshrc' "$zshrc" 
    
    echo -e "${OK}✅ Oh My Zsh has been configured.${RESET}"
}
configure_oh_my_zsh
