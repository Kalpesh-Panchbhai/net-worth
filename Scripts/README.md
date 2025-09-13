# Automated Version & Build Number Management

This directory contains scripts to automatically manage both the version number (`MARKETING_VERSION`) and build number (`CURRENT_PROJECT_VERSION`) in your Xcode project based on Git commit count.

## Overview

The automation ensures that your app's version and build numbers are automatically updated to reflect your development progress using realistic semantic versioning. The system uses commit milestones to determine appropriate version increments.

## Files

- `update_build_number.sh` - Main script that updates both version and build number based on Git commit count
- `version_manager.sh` - Core version management logic with semantic versioning

## How It Works

1. **Git Commit Count**: The script uses `git rev-list --count HEAD` to get the total number of commits in the current branch
2. **Semantic Versioning**: Automatically calculates version numbers based on commit milestones:
   - **Major version**: Every 1000 commits (major releases)
   - **Minor version**: Every 100 commits (feature releases)  
   - **Patch version**: Every 10 commits (bug fixes/small updates)
   - **Early development**: For < 100 commits, uses 0.x.y versioning
3. **Project File Update**: Updates both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in your `project.pbxproj` file
4. **Build Phase Integration**: The script runs as a build phase in Xcode before compilation starts
5. **Backup & Safety**: Creates backups and validates changes to ensure project integrity

## Current Status

✅ **Full Automation is Active**: The build number will automatically update in two scenarios:

1. **Before Every Commit** (via Git pre-commit hook)
2. **During Xcode Builds** (via build phase script)

- Current commit count: 389
- Current version: 1.3.8 (automatically calculated from commits)
- Build number automatically set to: 389
- Script integrated into Xcode build phases
- Pre-commit hook installed and active

## What Happens When You Commit Changes

Every time you commit to Git, the pre-commit hook will:
1. Calculate the new commit number (current + 1)
2. Calculate the appropriate semantic version based on commit milestones
3. Update both version and build number in the Xcode project
4. Add the updated project file to your commit
5. Complete the commit with correct version and build numbers

This means:
- **Commit 390** → Version 1.3.9, Build 390
- **Commit 400** → Version 1.4.0, Build 400 (minor version bump at 400 commits)
- **Commit 1000** → Version 2.0.0, Build 1000 (major version bump at 1000 commits)

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
