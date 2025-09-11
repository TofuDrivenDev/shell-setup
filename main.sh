#!/bin/bash

# Determine the package manager based on the OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/debian_version ]]; then
        echo "Package manager set to apt"
        PACKAGE_MANAGER="sudo apt"

        if [[ "$1" == "-u" ]]; then
            sudo apt update
        fi
    elif [[ -f /etc/redhat-release ]]; then
        echo "Package manager set to yum"
        PACKAGE_MANAGER="sudo yum -y"
        
        if [[ "$1" == "-u" ]]; then
            sudo yum update -y
        fi
    else
        echo "Unsupported Linux distribution. Please configure the package manager manually."
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Package manager set to brew"
    PACKAGE_MANAGER="brew"
else
    echo "Unsupported OS. Please configure the package manager manually."
    exit 1
fi


# Update package registry
if [[ "$1" == "-u" ]]; then
    echo "Updating package manager..."
    $PACKAGE_MANAGER update
fi


# Install zsh
if ! command -v zsh &> /dev/null; then
    echo "Installing zsh..."
    $PACKAGE_MANAGER install zsh
else
    echo "zsh is already installed."
fi


# Install autojump
if ! command -v autojump &> /dev/null; then
    # TODO: debian needs manual activation
    # https://github.com/wting/autojump#installation
    echo "Installing autojump..."
    $PACKAGE_MANAGER install autojump 
else
    echo "autojump is already installed."
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
    PLUGINS="alias-tips autojump git"
    sed -i '' "/^plugins=/s/([^)]*)/($PLUGINS)/" "$HOME/.zshrc"
    echo "Plugins installed and added to .zshrc"

    # Setup theme
    # risto re5et pygmalion obraun michelebologna lukerandall kafeitu
    sed -i '' '/^ZSH_THEME=/s/"[^"]*"/"pygmalion"/' "$HOME/.zshrc"
    echo "Theme set to pygmalion in .zshrc."
else
    echo "Oh My Zsh is already installed."
fi
