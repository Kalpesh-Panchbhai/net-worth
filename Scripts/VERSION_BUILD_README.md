# Automatic Version and Build Number Management

This directory contains scripts to automatically update the app's version and build number before each Git commit.

## 📋 Overview

The system automatically updates:
- **Build Number**: Total number of commits in the repository (including the current commit)
- **Version Number**: Calculated from build number using the formula: `1.[hundreds].[tens]`

### Version Formula Examples
| Build | Version | Calculation |
|-------|---------|-------------|
| 440   | 1.4.4   | 1.(440/100).(440%100/10) |
| 450   | 1.4.5   | 1.(450/100).(450%100/10) |
| 460   | 1.4.6   | 1.(460/100).(460%100/10) |
| 500   | 1.5.0   | 1.(500/100).(500%100/10) |

## 🚀 Installation

The pre-commit hook is already installed and active. If you need to reinstall it:

```bash
./Scripts/install_pre_commit_hook.sh
```

## 📝 How It Works

1. **Before each commit**, the Git pre-commit hook automatically runs
2. The script calculates the next build number (current commits + 1)
3. It updates both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`
4. The updated project file is automatically staged for the commit
5. Your commit proceeds with the updated version and build number

## 🧪 Testing

To test the version/build update without making a commit:

```bash
./Scripts/update_version_build.sh
```

This will:
- Show what the next version and build number will be
- Update the project file
- Stage the changes (you can unstage with `git reset HEAD`)

## 📂 Files

- **`update_version_build.sh`**: Main script that calculates and updates version/build
- **`install_pre_commit_hook.sh`**: Installation script for the Git pre-commit hook
- **`.git/hooks/pre-commit`**: The actual Git hook that runs before each commit

## 🔧 Manual Updates

If you need to manually update the version or build:

1. Edit `net-worth.xcodeproj/project.pbxproj`
2. Search for `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`
3. Update the values manually
4. Commit the changes

The pre-commit hook will adjust them based on the commit count on the next commit.

## ⚠️ Important Notes

- The hook runs automatically before **every** commit
- If the hook fails, the commit will be aborted
- The version and build are calculated from the total Git commit count
- Rebasing or squashing commits will affect the build number

## 🐛 Troubleshooting

### Hook not running?
Check if the hook is executable:
```bash
chmod +x .git/hooks/pre-commit
chmod +x Scripts/update_version_build.sh
```

### Want to skip the hook for one commit?
```bash
git commit --no-verify -m "Your message"
```

### Check current version/build:
```bash
grep "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" net-worth.xcodeproj/project.pbxproj | head -2
```

## 📊 Current Status

Run this to see your current version and build:
```bash
echo "Current commit count: $(git rev-list --count HEAD)"
grep -o "MARKETING_VERSION = [^;]*" net-worth.xcodeproj/project.pbxproj | head -1
grep -o "CURRENT_PROJECT_VERSION = [^;]*" net-worth.xcodeproj/project.pbxproj | head -1
```
