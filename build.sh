#!/bin/bash
set -e

APP_NAME="MonitorApp"
BUNDLE_NAME="${APP_NAME}.app"
OUTPUT_DIR="build"
CONTENTS_DIR="${OUTPUT_DIR}/${BUNDLE_NAME}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
MODULE_CACHE="/tmp/module-cache"

mkdir -p "${MODULE_CACHE}"

case "$1" in
    clean)
        echo "🧹 Cleaning build artifacts..."
        rm -rf "${OUTPUT_DIR}"
        echo "✨ Done."
        exit 0
        ;;
    run)
        $0
        echo "🚀 Launching ${APP_NAME}..."
        open "${OUTPUT_DIR}/${BUNDLE_NAME}"
        exit 0
        ;;
    install)
        $0
        TARGET_DIR="/Applications"
        mkdir -p "${TARGET_DIR}"
        echo "📦 Installing to ${TARGET_DIR}/${BUNDLE_NAME}..."
        rm -rf "${TARGET_DIR}/${BUNDLE_NAME}"
        cp -R "${OUTPUT_DIR}/${BUNDLE_NAME}" "${TARGET_DIR}/"
        echo "✅ Installed! You can launch it from Spotlight or ${TARGET_DIR}."
        exit 0
        ;;
esac

echo "🔨 Building ${APP_NAME} for macOS..."

# Create directory structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Collect swift sources
SOURCES=$(find Sources/MonitorApp -name "*.swift")
SDK_PATH=$(xcrun --show-sdk-path)
TMP_DIR=$(mktemp -d /tmp/monitorapp_build.XXXXXX)

echo "⚙️ Compiling Swift sources (Universal 2: arm64 + x86_64)..."

ARM64_BIN="${TMP_DIR}/${APP_NAME}_arm64"
X86_BIN="${TMP_DIR}/${APP_NAME}_x86_64"

# Compile Apple Silicon slice
echo "  -> Compiling for Apple Silicon (arm64)..."
swiftc -parse-as-library -O \
    -sdk "${SDK_PATH}" \
    -target arm64-apple-macosx14.0 \
    -module-cache-path "${MODULE_CACHE}" \
    ${SOURCES} \
    -o "${ARM64_BIN}"

# Compile Intel slice
echo "  -> Compiling for Intel (x86_64)..."
swiftc -parse-as-library -O \
    -sdk "${SDK_PATH}" \
    -target x86_64-apple-macosx14.0 \
    -module-cache-path "${MODULE_CACHE}" \
    ${SOURCES} \
    -o "${X86_BIN}"

# Combine into Universal binary
echo "  -> Merging architectures with lipo..."
lipo -create -output "${MACOS_DIR}/${APP_NAME}" "${ARM64_BIN}" "${X86_BIN}"
rm -rf "${TMP_DIR}"

# Copy Info.plist
echo "📋 Creating Info.plist and PkgInfo..."
cp Info.plist "${CONTENTS_DIR}/Info.plist"
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Copy Icon if present
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

# Ad-hoc code sign
echo "🔏 Code-signing application bundle..."
codesign --force --deep --sign - "${OUTPUT_DIR}/${BUNDLE_NAME}"

echo "🎉 Build succeeded! Bundle created at: ${OUTPUT_DIR}/${BUNDLE_NAME}"
echo "Run './build.sh run' to launch the app."
