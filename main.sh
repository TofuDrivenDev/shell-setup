#!/bin/bash
set -e

# Add some color to the output for better readability
INFO="\033[1;34m" # Blue
SUCCESS="\033[1;32m" # Green
ERR="\033[1;31m" # Red
RESET="\033[0m"

# Helper function to check for a command and install a package if it's missing.
# Usage: install_package_if_missing <command_to_check> <package_to_install>
install_package_if_missing() {
    local cmd_check="$1"
    local pkg_name="$2"

    if ! command -v "$cmd_check" &> /dev/null; then
        echo -e "${INFO}🛠️ Installing $pkg_name...${RESET}"
        $PKG_CMD install "$pkg_name"
    fi

    echo -e "${SUCCESS}✅ $pkg_name has been installed.${RESET}"
}

# Helper function to ensure a line exists in a file.
#
# Usage: ensure_line_in_file <line_to_add> <file_path>
ensure_line_in_file() {
    local line="$1"
    local file="$2"

    if ! grep -qF "$line" "$file"; then
        # If the file is missing a trailing newline, add one first.
        if [ -s "$file" ] && [ "$(tail -c1 "$file")" != "" ]; then    
            echo "" >> "$file"
        fi
        
        echo "$line" >> "$file"
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
    echo -e "${SUCCESS}✅ Homebrew has been installed.${RESET}"

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


install_tldr() { # https://github.com/tldr-pages/tldr#how-do-i-use-it
    if ! command -v tldr &> /dev/null; then
        echo -e "${INFO}🛠️ Installing tldr...${RESET}"
        $PKG_CMD install tldr
    fi

    echo -e "${SUCCESS}✅ tldr has been installed.${RESET}"
}
install_tldr


install_bat() { # https://github.com/sharkdp/bat#installation
    if ! command -v bat &> /dev/null; then
        echo -e "${INFO}🛠️ Installing bat...${RESET}"
        $PKG_CMD install bat
    fi

    echo -e "${SUCCESS}✅ bat has been installed.${RESET}"
}
install_bat

install_jq() { # https://github.com/jqlang/jq#installation
    if ! command -v jq &> /dev/null; then
        echo -e "${INFO}🛠️ Installing jq...${RESET}"
        $PKG_CMD install jq
    fi

    echo -e "${SUCCESS}✅ jq has been installed.${RESET}"
}
install_jq


install_package_if_missing "zsh" "zsh"


install_ripgrep() {
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
    
    echo -e "${SUCCESS}✅ ripgrep has been installed.${RESET}"
}
install_ripgrep


install_autojump() {
     if ! command -v autojump &> /dev/null; then
        echo -e "${INFO}🛠️ Installing autojump...${RESET}"
        # TODO: debian needs manual activation
        # https://github.com/wting/autojump#installation
        $PKG_CMD install autojump 
    fi

    echo -e "${SUCCESS}✅ autojump has been installed.${RESET}"
}
install_autojump


install_autoenv() {
    if ! grep -q "autoenv/activate.sh" "$HOME/.zshrc"; then
        echo -e "${INFO}🛠️ Installing autoenv...${RESET}"
        curl -#fLo- 'https://raw.githubusercontent.com/hyperupcall/autoenv/main/scripts/install.sh' | sh
    fi

    echo -e "${SUCCESS}✅ autoenv has been installed.${RESET}"
}
install_autoenv


install_terminal_notifier() {
    if ! [[ "$PKG_MGR" == "brew" ]]; then
        echo -e "${INFO}🛠️ Installing terminal-notifier...${RESET}"
        install_package_if_missing "terminal-notifier" "terminal-notifier"
    fi

    echo -e "${SUCCESS}✅ terminal-notifier has been installed.${RESET}"
}
install_terminal_notifier


install_oh_my_zsh() {
    if ! [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${INFO}🛠️ Installing Oh My Zsh...${RESET}"
        # The installer might try to run zsh; pass a no-op command to prevent it from exiting the script
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    echo -e "${SUCCESS}✅ Oh My Zsh has been installed.${RESET}"
}
install_oh_my_zsh


configure_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${ERR}❌ ~/.oh-my-zsh is missing.${RESET}"
        exit 1
    fi
    
    echo -e "${INFO}🛠️ Configuring Oh My Zsh...${RESET}"
    local zshrc_file="$HOME/.zshrc"

    # Setup theme
    # risto re5et pygmalion obraun michelebologna lukerandall kafeitu
    sed -i '' 's#^ZSH_THEME="[^"]*"#ZSH_THEME="pygmalion"#' "$zshrc_file"
    
    # Setup plugins
    local plugins_line='plugins=(alias-finder autoenv autojump bgnotify colored-man-pages command-not-found gh git git-auto-fetch gradle node npm nvm pip pipenv safe-paste ssh vscode yarn zoxide zsh-interactive-cd)'
    sed -i '' "s#^plugins=(.*)#$plugins_line#" "$zshrc_file"

    # Setup alias-finder
    local settings=("autoload" "longer" "exact" "cheaper")
    for setting in "${settings[@]}"; do
        ensure_line_in_file "zstyle ':omz:plugins:alias-finder' $setting yes" "$zshrc_file"
    done
    
    # Setup zsh-interactive-cd 
    # https://github.com/junegunn/fzf#installation
    install_package_if_missing "fzf" "fzf"
    ensure_line_in_file 'source <(fzf --zsh)' "$zshrc_file"
    
    # Setup zoxide ()
    # https://github.com/ajeetdsouza/zoxide
    install_package_if_missing "zoxide" "zoxide"
    ensure_line_in_file 'eval "$(zoxide init zsh)" # This must be the last line of .zshrc' "$zshrc_file" 
    
    echo -e "${SUCCESS}✅ Oh My Zsh configured.${RESET}"
}
configure_oh_my_zsh
