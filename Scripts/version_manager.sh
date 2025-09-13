#!/bin/bash

# Version Manager - Handles automatic version and build number updates
# Uses semantic versioning: MAJOR.MINOR.PATCH

# Get current version from project file
get_current_version() {
    local project_file="$1"
    local version=$(grep -o "MARKETING_VERSION = [0-9]*\.[0-9]*\(\.[0-9]*\)\?;" "$project_file" | head -1 | grep -o "[0-9]*\.[0-9]*\(\.[0-9]*\)\?" || echo "1.0.0")
    
    # Convert X.Y format to X.Y.0 format
    if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        version="${version}.0"
    fi
    
    echo "$version"
}

# Parse version components
parse_version() {
    local version="$1"
    echo "$version" | tr '.' ' '
}

# Calculate new version based on commit count milestones
calculate_version() {
    local commit_count="$1"
    local current_version="$2"
    
    # Parse current version
    read -r major minor patch <<< "$(parse_version "$current_version")"
    
    # Version increment logic based on commit milestones
    # Major version: Every 1000 commits (major releases)
    # Minor version: Every 100 commits (feature releases)  
    # Patch version: Every 10 commits (bug fixes/small updates)
    
    local new_major=$((commit_count / 1000))
    local remaining_after_major=$((commit_count % 1000))
    local new_minor=$((remaining_after_major / 100))
    local remaining_after_minor=$((remaining_after_major % 100))
    local new_patch=$((remaining_after_minor / 10))
    
    # Ensure we don't go backwards
    if [ "$new_major" -lt "$major" ]; then
        new_major="$major"
    fi
    
    if [ "$new_major" -eq "$major" ] && [ "$new_minor" -lt "$minor" ]; then
        new_minor="$minor"
    fi
    
    if [ "$new_major" -eq "$major" ] && [ "$new_minor" -eq "$minor" ] && [ "$new_patch" -lt "$patch" ]; then
        new_patch="$patch"
    fi
    
    # For early development (< 100 commits), use 0.x.y versioning
    if [ "$commit_count" -lt 100 ]; then
        new_major=0
        new_minor=$((commit_count / 10))
        new_patch=$((commit_count % 10))
    fi
    
    echo "${new_major}.${new_minor}.${new_patch}"
}

# Update both version and build number in project file
update_project_version() {
    local project_file="$1"
    local new_version="$2"
    local new_build="$3"
    
    # Create backup
    cp "$project_file" "$project_file.backup" || return 1
    
    # Update MARKETING_VERSION - handle current format (1.0) and convert to semantic versioning
    if ! sed -i '' "s/MARKETING_VERSION = [0-9]*\.[0-9]*;/MARKETING_VERSION = $new_version;/g" "$project_file"; then
        mv "$project_file.backup" "$project_file"
        return 1
    fi
    
    # Update CURRENT_PROJECT_VERSION (build number)
    if ! sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $new_build;/g" "$project_file"; then
        mv "$project_file.backup" "$project_file"
        return 1
    fi
    
    # Verify changes
    if grep -q "MARKETING_VERSION = $new_version;" "$project_file" && grep -q "CURRENT_PROJECT_VERSION = $new_build;" "$project_file"; then
        rm "$project_file.backup"
        return 0
    else
        echo "❌ Verification failed - restoring backup"
        mv "$project_file.backup" "$project_file"
        return 1
    fi
}

# Main function
main() {
    local project_dir="${1:-${SRCROOT}}"
    local project_file="${project_dir}/net-worth.xcodeproj/project.pbxproj"
    local is_pre_commit="${2:-false}"
    
    # Check if project file exists
    if [ ! -f "$project_file" ]; then
        echo "❌ Could not find project.pbxproj file"
        return 1
    fi
    
    # Get commit count
    local commit_count
    if [ "$is_pre_commit" = "true" ]; then
        # For pre-commit, use current commit count (the commit being made will have this number)
        commit_count=$(git -C "$project_dir" rev-list --count HEAD 2>/dev/null || echo "1")
    else
        # For build phase, use current commit count
        commit_count=$(git -C "$project_dir" rev-list --count HEAD 2>/dev/null || echo "1")
    fi
    
    # Get current version and build number
    local current_version=$(get_current_version "$project_file")
    local current_build=$(grep -o "CURRENT_PROJECT_VERSION = [0-9]*;" "$project_file" | head -1 | grep -o "[0-9]*" || echo "1")
    
    # Calculate new version
    local new_version=$(calculate_version "$commit_count" "$current_version")
    
    # Check if updates are needed
    if [ "$current_version" = "$new_version" ] && [ "$current_build" = "$commit_count" ]; then
        echo "✅ Version ($new_version) and build ($commit_count) are up to date"
        return 0
    fi
    
    echo "🔧 Updating version from $current_version to $new_version, build from $current_build to $commit_count"
    
    # Update project file
    if update_project_version "$project_file" "$new_version" "$commit_count"; then
        echo "✅ Successfully updated to version $new_version (build $commit_count)"
        return 0
    else
        echo "❌ Failed to update version and build number"
        return 1
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
