#!/usr/bin/env python3
"""
Extension Loader for Gitpod Configuration
==========================================

This script loads VS Code extensions and JetBrains configurations from
separate YAML files and merges them into the main .gitpod.yml structure.
This allows us to keep the main .gitpod.yml file clean while maintaining
all extension configurations in organized separate files.
"""

import yaml
import os

def load_vscode_extensions():
    """Load VS Code extensions from separate YAML file."""
    try:
        with open('.gitpod/extensions/vscode.yml', 'r') as f:
            return yaml.safe_load(f)['extensions']
    except FileNotFoundError:
        print("Warning: VS Code extensions file not found")
        return []

def load_jetbrains_config():
    """Load JetBrains configuration from separate YAML file."""
    try:
        with open('.gitpod/extensions/jetbrains.yml', 'r') as f:
            return yaml.safe_load(f)['jetbrains']
    except FileNotFoundError:
        print("Warning: JetBrains configuration file not found")
        return {}

if __name__ == "__main__":
    print("Loading extension configurations...")
    vscode_extensions = load_vscode_extensions()
    jetbrains_config = load_jetbrains_config()
    
    print(f"Loaded {len(vscode_extensions)} VS Code extensions")
    print(f"Loaded JetBrains configuration with {len(jetbrains_config.get('intellij', {}).get('plugins', []))} plugins")
    
    # This script can be extended to actually merge configurations if needed
    # For now, it's just a utility to verify the configurations load correctly 