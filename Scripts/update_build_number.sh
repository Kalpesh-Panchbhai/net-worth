#!/bin/bash

# Script to automatically update version and build number based on Git commit count
# This script should be run as a build phase in Xcode

echo "🔄 Checking version and build number automation..."

# Get the project directory (should be the directory containing the .xcodeproj file)
PROJECT_DIR="${SRCROOT}"

# Check if we're in a Git repository
if [ ! -d "${PROJECT_DIR}/.git" ]; then
    echo "⚠️ Not in a Git repository. Version and build number will not be updated."
    exit 0
fi

# Source the version manager script
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/version_manager.sh"

# Run the version manager for build phase (not pre-commit)
main "$PROJECT_DIR" "false"
