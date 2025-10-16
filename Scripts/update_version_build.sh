#!/bin/bash

# Script to automatically update version and build number before commit
# Build = total commit count (including current commit)
# Version formula: Build 440 -> 1.4.4, Build 450 -> 1.4.5, Build 460 -> 1.4.6
# Pattern: 1.[hundreds digit].[tens digit]

set -e

PROJECT_DIR="$(git rev-parse --show-toplevel)"
PROJECT_FILE="${PROJECT_DIR}/net-worth.xcodeproj/project.pbxproj"

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Could not find project.pbxproj file at: $PROJECT_FILE"
    exit 1
fi

# Get current commit count and add 1 for the upcoming commit
CURRENT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
NEW_BUILD=$((CURRENT_COUNT + 1))

# Calculate version based on the formula
# For build 440: 1.4.4 (hundreds=4, tens=4)
# For build 450: 1.4.5 (hundreds=4, tens=5)
# For build 460: 1.4.6 (hundreds=4, tens=6)
MAJOR=1
MINOR=$((NEW_BUILD / 100))
PATCH=$(((NEW_BUILD % 100) / 10))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Get current values
CURRENT_VERSION=$(grep -o "MARKETING_VERSION = [0-9]*\.[0-9]*\.[0-9]*;" "$PROJECT_FILE" | head -1 | grep -o "[0-9]*\.[0-9]*\.[0-9]*" || echo "1.0.0")
CURRENT_BUILD=$(grep -o "CURRENT_PROJECT_VERSION = [0-9]*;" "$PROJECT_FILE" | head -1 | grep -o "[0-9]*" || echo "1")

# Check if update is needed
if [ "$CURRENT_VERSION" = "$NEW_VERSION" ] && [ "$CURRENT_BUILD" = "$NEW_BUILD" ]; then
    echo "✅ Version ($NEW_VERSION) and Build ($NEW_BUILD) are already up to date"
    exit 0
fi

echo "🔧 Updating Version: $CURRENT_VERSION → $NEW_VERSION"
echo "🔧 Updating Build: $CURRENT_BUILD → $NEW_BUILD"

# Create backup
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

# Update MARKETING_VERSION
sed -i '' "s/MARKETING_VERSION = [0-9]*\.[0-9]*\.[0-9]*;/MARKETING_VERSION = $NEW_VERSION;/g" "$PROJECT_FILE"

# Update CURRENT_PROJECT_VERSION (build number)
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PROJECT_FILE"

# Verify changes
VERSION_COUNT=$(grep -c "MARKETING_VERSION = $NEW_VERSION;" "$PROJECT_FILE")
BUILD_COUNT=$(grep -c "CURRENT_PROJECT_VERSION = $NEW_BUILD;" "$PROJECT_FILE")

if [ "$VERSION_COUNT" -gt 0 ] && [ "$BUILD_COUNT" -gt 0 ]; then
    rm "$PROJECT_FILE.backup"
    
    # Stage the updated project file
    git add "$PROJECT_FILE"
    
    echo "✅ Successfully updated to Version $NEW_VERSION (Build $NEW_BUILD)"
    echo "📝 Changes staged for commit"
    exit 0
else
    echo "❌ Verification failed - restoring backup"
    mv "$PROJECT_FILE.backup" "$PROJECT_FILE"
    exit 1
fi
