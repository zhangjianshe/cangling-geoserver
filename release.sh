#!/bin/bash
bump_version() {
    local current_version=$(cat version.txt)

    if [[ "$current_version" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        local major=${BASH_REMATCH[1]}
        local minor=${BASH_REMATCH[2]}
        local patch=${BASH_REMATCH[3]}

        # Increment the patch number
        local new_patch=$((patch + 1))
        echo "${major}.${minor}.${new_patch}"
    else
        echo "Error: Version format ($current_version) is not recognized (expected X.Y.Z)." >&2
        return 1
    fi
}

NEW_VERSION=$(bump_version)

if [ $? -ne 0 ]; then
    exit 1 # Exit if bump_version failed
fi

echo $NEW_VERSION > version.txt

git add version.txt
git commit -m "publish version $NEW_VERSION"
git push
git tag v$NEW_VERSION
git push tag v$NEW_VERSION
