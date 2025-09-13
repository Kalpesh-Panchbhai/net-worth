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

✅ **Automation is Active**: The build number will automatically update every time you build your project.

- Current commit count: 384
- Build number automatically set to: 384
- Script integrated into Xcode build phases

## What Happens When You Push Changes

Every time you:
1. Make commits to your repository
2. Build your project in Xcode

The build number will automatically increment to match your total commit count. This means:
- **Commit 385** → Build number becomes 385
- **Commit 386** → Build number becomes 386
- And so on...

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
