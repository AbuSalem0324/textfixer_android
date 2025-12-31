#!/bin/bash

# Android SDK location from local.properties
SDK_DIR="/mnt/c/Users/adam/AppData/Local/Android/Sdk"

# Check if sdkmanager exists
if [ ! -f "$SDK_DIR/cmdline-tools/latest/bin/sdkmanager" ]; then
    echo "❌ sdkmanager not found. Please install Android command line tools first."
    echo "Download from: https://developer.android.com/studio#command-tools"
    exit 1
fi

echo "📦 Installing Android NDK..."

# Install NDK (latest version)
"$SDK_DIR/cmdline-tools/latest/bin/sdkmanager" --install "ndk;27.0.12077973"

# Or install the latest NDK version:
# "$SDK_DIR/cmdline-tools/latest/bin/sdkmanager" --install "ndk-bundle"

echo "✅ NDK installation complete!"
echo ""
echo "Installed to: $SDK_DIR/ndk/27.0.12077973"
