#!/bin/bash
# =============================================================================
# Force Bash Shell Script
# =============================================================================
#
# Purpose:
#   This script forces the use of bash shell and removes any fish shell
#   configurations that might be interfering with terminal operation.
#
# =============================================================================

set -e

echo "Forcing bash shell configuration..."

# Change the default shell to bash for gitpod user
echo "Changing default shell to bash..."
sudo chsh -s /bin/bash gitpod

# Disable fish shell if it exists
if command -v fish &> /dev/null; then
    echo "Fish shell detected, disabling..."
    
    # Rename fish config to prevent autostart
    if [ -d ~/.config/fish ]; then
        echo "Backing up fish configuration..."
        mv ~/.config/fish ~/.config/fish.backup.$(date +%s)
    fi
fi

# Create a clean bashrc without fish invocation
echo "Creating clean bash configuration..."
cat > ~/.bashrc << 'EOF'
# Clean bashrc for gitpod - no fish shell

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Basic prompt
export PS1='\u@\h:\w\$ '

# Disable bracketed paste mode to prevent character corruption
printf '\e[?2004l'

# Source direnv if available
if command -v direnv &> /dev/null; then
    eval "$(direnv hook bash)"
fi

# Load RVM if available
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
fi
EOF

# Create a clean bash_profile
echo "Creating clean bash profile..."
cat > ~/.bash_profile << 'EOF'
# Clean bash_profile for gitpod

[[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc"

# Change to workspace directory if in SSH connection
if [[ -n $SSH_CONNECTION ]]; then 
    cd "/workspace/lago"
fi
EOF

echo "Bash shell configuration complete!"
echo "Please restart your terminal or run: exec bash" 