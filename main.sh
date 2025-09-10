#!/bin/bash

# Determine the package manager based on the OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/debian_version ]]; then
        PACKAGE_MANAGER="apt"
        sudo apt update
    elif [[ -f /etc/redhat-release ]]; then
        PACKAGE_MANAGER="yum -y"
        sudo yum update -y
    else
        echo "Unsupported Linux distribution. Please configure the package manager manually."
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    PACKAGE_MANAGER="brew"
    brew update
else
    echo "Unsupported OS. Please configure the package manager manually."
    exit 1
fi

# Install zsh
if ! command -v zsh &> /dev/null; then
    echo "zsh is not installed. Installing zsh..."
    sudo $PACKAGE_MANAGER install zsh
else
    echo "zsh is already installed."
fi

# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Oh My Zsh is not installed. Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh is already installed."
fi