# Automated Build Number Management

This directory contains scripts to automatically manage the build number in your Xcode project based on Git commit count.

## Overview

The automation ensures that your app's build number (`CURRENT_PROJECT_VERSION`) is automatically updated to reflect the total number of commits in your Git repository. This provides a reliable and incrementing build number that correlates with your development progress.

## Files

- `update_build_number.sh` - Main script that updates the build number based on Git commit count

## How It Works

1. **Git Commit Count**: The script uses `git rev-list --count HEAD` to get the total number of commits in the current branch
2. **Project File Update**: It automatically updates the `CURRENT_PROJECT_VERSION` setting in your `project.pbxproj` file
3. **Build Phase Integration**: The script runs as a build phase in Xcode before compilation starts
4. **Backup & Safety**: Creates backups and validates changes to ensure project integrity

## Current Status

✅ **Full Automation is Active**: The build number will automatically update in two scenarios:

1. **Before Every Commit** (via Git pre-commit hook)
2. **During Xcode Builds** (via build phase script)

- Current commit count: 386
- Build number automatically set to: 386
- Script integrated into Xcode build phases
- Pre-commit hook installed and active

## What Happens When You Commit Changes

Every time you commit to Git, the pre-commit hook will:
1. Calculate the new commit number (current + 1)
2. Update the build number in the Xcode project
3. Add the updated project file to your commit
4. Complete the commit with the correct build number

This means:
- **Before commit 387** → Build number becomes 387
- **Before commit 388** → Build number becomes 388
- And so on...

## Git Pre-Commit Hook

A Git pre-commit hook has been installed at `.git/hooks/pre-commit` that:
- Runs automatically before every commit
- Updates the build number to match the upcoming commit number
- Includes the updated project file in the commit
- Ensures your build number is always current when pushing to GitHub

## Manual Testing

To manually test the script:

```bash
# From the project root directory
SRCROOT=/Users/kalpesh.panchbhai/Developer/Personal/net-worth ./Scripts/update_build_number.sh
```

## Troubleshooting

### Script Not Running
- Ensure the script has execute permissions: `chmod +x Scripts/update_build_number.sh`
- Check that the build phase is properly configured in Xcode

### Build Number Not Updating
- Verify you're in a Git repository
- Check that Git is accessible from the build environment
- Review Xcode build logs for script output

### Backup Recovery
If something goes wrong, the script creates automatic backups:
- Backup file: `project.pbxproj.backup`
- The script will restore from backup if updates fail

## Benefits

1. **Automatic Incrementing**: No manual build number management required
2. **Git Integration**: Build numbers reflect actual development progress
3. **Consistent Versioning**: Each commit gets a unique build number
4. **App Store Compliance**: Ensures incrementing build numbers for App Store submissions
5. **Team Synchronization**: All team members get consistent build numbers

## Technical Details

- **Script Language**: Bash shell script
- **Xcode Integration**: PBXShellScriptBuildPhase
- **Git Command**: `git rev-list --count HEAD`
- **File Modified**: `net-worth.xcodeproj/project.pbxproj`
- **Build Phase**: Runs before Sources compilation

The automation is now fully configured and will work automatically with every build!
# Test change for pre-commit hook
