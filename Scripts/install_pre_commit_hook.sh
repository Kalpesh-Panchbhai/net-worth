#!/bin/bash

# Installation script for the pre-commit hook

echo "📦 Installing pre-commit hook for automatic version/build updates..."

PROJECT_DIR="$(git rev-parse --show-toplevel)"
HOOK_SOURCE="${PROJECT_DIR}/Scripts/pre-commit-hook.sh"
HOOK_DEST="${PROJECT_DIR}/.git/hooks/pre-commit"

# Create the pre-commit hook content
cat > "$HOOK_DEST" << 'EOF'
#!/bin/bash

# Pre-commit hook to automatically update version and build number

echo "🚀 Running pre-commit hook: Updating version and build number..."

# Get the project root directory
PROJECT_DIR="$(git rev-parse --show-toplevel)"

# Run the version/build update script
"${PROJECT_DIR}/Scripts/update_version_build.sh"

# Check if the script succeeded
if [ $? -ne 0 ]; then
    echo "❌ Failed to update version and build number"
    exit 1
fi

echo "✅ Pre-commit hook completed successfully"
exit 0
EOF

# Make the hook executable
chmod +x "$HOOK_DEST"
chmod +x "${PROJECT_DIR}/Scripts/update_version_build.sh"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "📝 How it works:"
echo "   - Before each commit, the hook will automatically run"
echo "   - Build number = total commits (including current commit)"
echo "   - Version format: 1.[hundreds].[tens]"
echo "   - Example: Build 440 → Version 1.4.4"
echo "   - Example: Build 450 → Version 1.4.5"
echo ""
echo "🧪 To test the hook without committing, run:"
echo "   ./Scripts/update_version_build.sh"
