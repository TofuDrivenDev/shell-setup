#!/bin/bash
set -e

# Determine the package manager based on the OS
if [[ -f /etc/debian_version ]]; then
    echo "Package manager set to apt"
    PKG_MGR="apt"
    PKG_CMD="sudo apt"
elif [[ -f /etc/redhat-release ]]; then
    echo "Package manager set to yum"
    PKG_MGR="yum"
    PKG_CMD="sudo yum -y"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Package manager set to brew"
    PKG_MGR="brew"
    PKG_CMD="brew"
else
    echo "Unsupported OS. Please configure the package manager manually."
    exit 1
fi


# Update package registry
if [[ "$1" == "-u" ]]; then
    echo "Updating package manager..."
    $PKG_CMD update
fi


# Install zsh
if ! command -v zsh &> /dev/null; then
    echo "Installing zsh..."
    $PKG_CMD install zsh
else
    echo "zsh is already installed."
fi


# Install ripgrep (for alias-finder)
if ! command -v rg &> /dev/null; then
    echo "Installing ripgrep..."

    if [[ "$PKG_MGR" == "yum" ]]; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
        sudo yum install ripgrep
    else
        $PKG_CMD ripgrep
    fi
else
    echo "ripgrep is already installed."
fi


# Install autojump
if ! command -v autojump &> /dev/null; then
    # TODO: debian needs manual activation
    # https://github.com/wting/autojump#installation
    echo "Installing autojump..."
    $PKG_CMD install autojump 
else
    echo "autojump is already installed."
fi

# Install autoenv
if ! command -v autoenv &> /dev/null; then
    echo "Installing autoenv..."
    curl -#fLo- 'https://raw.githubusercontent.com/hyperupcall/autoenv/main/scripts/install.sh' | sh
else
    echo "autoenv is already installed."
fi


# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh is already installed."
fi


# Setup Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    # Setup plugins
    PLUGINS="alias-finder autoenv autojump git"
    sed -i '' '/^plugins=/s/([^)]*)/('"$PLUGINS"')/' "$HOME/.zshrc"
    echo "Plugins installed and added to .zshrc"

    # Setup theme
    # risto re5et pygmalion obraun michelebologna lukerandall kafeitu
    sed -i '' '/^ZSH_THEME=/s/"[^"]*"/"pygmalion"/' "$HOME/.zshrc"
    echo "Theme set to pygmalion in .zshrc."
else
    echo "Oh My Zsh is already installed."
fi
