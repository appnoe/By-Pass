#!/bin/bash
# Increments CFBundleVersion (build number) on every build.
# This script is run as a pre-build Run Script phase in Xcode.

# Only increment when building for a device or simulator (not during indexing)
if [ "${ACTION}" == "indexbuild" ]; then
    exit 0
fi

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
SOURCE_PLIST="${SRCROOT}/Graviton/Info.plist"

# Read current build number from the source Info.plist
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${SOURCE_PLIST}" 2>/dev/null)

# If not set, start at 1
if [ -z "${CURRENT_BUILD}" ]; then
    CURRENT_BUILD=0
fi

# Increment
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update the source Info.plist so the number persists across builds
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" "${SOURCE_PLIST}"

echo "Build number incremented: ${CURRENT_BUILD} → ${NEW_BUILD}"
