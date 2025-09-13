#!/bin/bash

# Script to automatically update build number based on Git commit count
# This script should be run as a build phase in Xcode

# Get the project directory (should be the directory containing the .xcodeproj file)
PROJECT_DIR="${SRCROOT}"
PROJECT_FILE="${PROJECT_DIR}/net-worth.xcodeproj/project.pbxproj"

echo "🔄 Checking build number automation..."

# Check if we're in a Git repository
if [ ! -d "${PROJECT_DIR}/.git" ]; then
    echo "⚠️ Not in a Git repository. Build number will not be updated."
    exit 0
fi

# Get the total number of commits in the current branch
COMMIT_COUNT=$(git -C "${PROJECT_DIR}" rev-list --count HEAD 2>/dev/null || echo "1")

# Validate that we got a number
if ! [[ "$COMMIT_COUNT" =~ ^[0-9]+$ ]]; then
    echo "⚠️ Could not determine commit count. Using default build number."
    exit 0
fi

echo "📊 Current commit count: $COMMIT_COUNT"

# Check if the project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Could not find project.pbxproj file at $PROJECT_FILE"
    exit 0
fi

# Check current build number in project file
CURRENT_BUILD=$(grep -o "CURRENT_PROJECT_VERSION = [0-9]*;" "$PROJECT_FILE" | head -1 | grep -o "[0-9]*" || echo "0")

if [ "$CURRENT_BUILD" = "$COMMIT_COUNT" ]; then
    echo "✅ Build number ($COMMIT_COUNT) is already up to date"
    exit 0
fi

echo "🔧 Updating build number from $CURRENT_BUILD to $COMMIT_COUNT"

# Create a backup of the project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup" || {
    echo "❌ Failed to create backup of project file"
    exit 0
}

# Update the CURRENT_PROJECT_VERSION in the project file
# This uses sed to replace all instances of CURRENT_PROJECT_VERSION = <number>;
if sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $COMMIT_COUNT;/g" "$PROJECT_FILE"; then
    # Verify the change was made
    if grep -q "CURRENT_PROJECT_VERSION = $COMMIT_COUNT;" "$PROJECT_FILE"; then
        echo "✅ Build number successfully updated to: $COMMIT_COUNT"
        # Remove backup file since update was successful
        rm "$PROJECT_FILE.backup"
        exit 0
    else
        echo "❌ Failed to verify build number update. Restoring backup."
        mv "$PROJECT_FILE.backup" "$PROJECT_FILE"
        exit 0
    fi
else
    echo "❌ Failed to update build number. Restoring backup."
    mv "$PROJECT_FILE.backup" "$PROJECT_FILE"
    exit 0
fi
