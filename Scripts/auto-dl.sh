#!/bin/bash

# Script to update dab-downloader to the latest version with OS detection
# Author: Auto-generated script
# Description: Detects OS, removes old version, downloads latest from GitHub, and sets permissions

set -e  # Exit on any error

echo "Starting DAB Downloader update process..."

# Function to detect OS and architecture
detect_os_arch() {
    local os=""
    local arch=""
    local binary_name=""
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="macos" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *)          echo "❌ Unsupported operating system: $(uname -s)"; exit 1 ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        aarch64|arm64)  arch="arm64" ;;
        *)              echo "❌ Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac
    
    # Construct binary name
    if [ "$os" = "windows" ]; then
        binary_name="dab-downloader-${os}-${arch}.exe"
    else
        binary_name="dab-downloader-${os}-${arch}"
    fi
    
    echo "$binary_name"
}

# Detect the appropriate binary for this system
BINARY_NAME=$(detect_os_arch)
echo "Detected system: $(uname -s) $(uname -m)"
echo "Target binary: $BINARY_NAME"

# Remove existing binaries and symlinks if they exist (clean up any old versions)
echo "Cleaning up existing binaries..."
for old_binary in dab-downloader-linux-amd64 dab-downloader-linux-arm64 dab-downloader-macos-amd64 dab-downloader-windows-amd64.exe dab-downloader; do
    if [ -e "$old_binary" ] || [ -L "$old_binary" ]; then
        echo "Removing existing $old_binary..."
        rm -f "$old_binary"
        echo "✓ Removed $old_binary"
    fi
done

# Additional cleanup - remove any broken symlinks
if [ -L "$BINARY_NAME" ] && [ ! -e "$BINARY_NAME" ]; then
    echo "Removing broken symlink $BINARY_NAME..."
    rm -f "$BINARY_NAME"
fi

# Get the latest release URL from GitHub API
echo "Fetching latest release information..."
LATEST_URL=$(curl -s https://api.github.com/repos/PrathxmOp/dab-downloader/releases/latest | grep "browser_download_url.*$BINARY_NAME" | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "❌ Error: Could not find download URL for $BINARY_NAME"
    echo "Please check if the repository exists and has releases with this binary name"
    echo "Available binaries should be:"
    echo "  - dab-downloader-linux-amd64"
    echo "  - dab-downloader-linux-arm64" 
    echo "  - dab-downloader-macos-amd64"
    echo "  - dab-downloader-windows-amd64.exe"
    exit 1
fi

echo "Latest release URL: $LATEST_URL"

# Download the latest version with better error handling
echo "Downloading latest $BINARY_NAME..."

# Ensure we have a clean target file
rm -f "$BINARY_NAME" 2>/dev/null || true

# Download with verbose error reporting
if curl -L --fail --show-error --create-dirs -o "$BINARY_NAME" "$LATEST_URL"; then
    echo "✓ Download completed successfully"
    
    # Verify the download
    if [ ! -f "$BINARY_NAME" ] || [ ! -s "$BINARY_NAME" ]; then
        echo "❌ Error: Downloaded file is missing or empty"
        exit 1
    fi
    
    echo "✓ Download verified ($(du -h "$BINARY_NAME" | cut -f1) downloaded)"
else
    echo "❌ Error: Failed to download the binary"
    echo "URL attempted: $LATEST_URL"
    echo "Please check your internet connection and try again"
    exit 1
fi

# Make it executable (skip for Windows .exe files as they don't need chmod)
if [[ "$BINARY_NAME" != *.exe ]]; then
    echo "Setting executable permissions..."
    chmod +x "$BINARY_NAME"
    echo "✓ File permissions set successfully"
else
    echo "✓ Windows executable downloaded (no chmod needed)"
fi

# Create a generic symlink for easier usage
if [ ! "$BINARY_NAME" = "dab-downloader" ]; then
    echo "Creating generic symlink 'dab-downloader'..."
    ln -sf "$BINARY_NAME" dab-downloader
    echo "✓ Symlink created: dab-downloader -> $BINARY_NAME"
fi

# Verify the file
if [ -f "$BINARY_NAME" ]; then
    echo "✓ DAB Downloader update completed!"
    
    # Show file info
    echo ""
    echo "File information:"
    ls -la "$BINARY_NAME"
    
    if [ -L "dab-downloader" ]; then
        echo "Generic symlink:"
        ls -la dab-downloader
    fi
    
    # Try to show version if the binary supports it
    echo ""
    echo "Testing binary (attempting to show version):"
    if [[ "$BINARY_NAME" == *.exe ]]; then
        echo "Windows executable downloaded and ready to use"
        echo "Run with: ./$BINARY_NAME"
    else
        ./"$BINARY_NAME" --version 2>/dev/null || ./"$BINARY_NAME" -v 2>/dev/null || echo "Binary downloaded and ready to use (version info not available)"
        echo "You can also run with the generic name: ./dab-downloader"
    fi
    
else
    echo "❌ Error: Something went wrong with the download"
    exit 1
fi

echo ""
echo "🎉 Update process completed successfully!"
echo "Primary binary: ./$BINARY_NAME"
if [ -L "dab-downloader" ]; then
    echo "Generic shortcut: ./dab-downloader"
fi
