#!/usr/bin/env bash
set -euo pipefail

# Get the directory of this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_file="$script_dir/package.nix"

echo "Fetching latest release info from google-gemini/gemini-cli..."
release_info=$(curl -s https://api.github.com/repos/google-gemini/gemini-cli/releases/latest)
latest_version=$(echo "$release_info" | jq -r '.tag_name' | sed 's/^v//')
echo "Latest version: $latest_version"

current_version=$(nix eval .#gemini-cli.version --raw)
echo "Current version: $current_version"

if [ "$latest_version" = "$current_version" ] && [ "${FORCE_UPDATE:-}" != "true" ]; then
  echo "Package is already up to date!"
  echo "Use FORCE_UPDATE=true to force hash updates"
  exit 0
fi

if [ "$latest_version" = "$current_version" ]; then
  echo "Forcing hash update for version $current_version"
else
  echo "Update available: $current_version -> $latest_version"
fi

# Update version in package.nix
sed -i "s/version = \"${current_version}\";/version = \"${latest_version}\";/" "$package_file"

# Set a dummy hash to trigger Nix to tell us the right one
sed -i 's|hash = \"sha256-[^\"]*\";|hash = \"sha256-0000000000000000000000000000000000000000000=\";|' "$package_file"

# Build to capture the correct hash from the failure message
if output=$(nix build "$script_dir/../.."#gemini-cli 2>&1); then
  echo "ERROR: Build unexpectedly succeeded with dummy hash!"
  exit 1
else
  if real_hash=$(echo "$output" | grep -A2 "error: hash mismatch" | grep "got:" | head -1 | sed 's/.*got: *//' | xargs); then
    echo "Real hash: $real_hash"
    sed -i "s|sha256-0000000000000000000000000000000000000000000=|$real_hash|" "$package_file"
  else
    echo "ERROR: Could not extract real hash from build output"
    echo "$output" | tail -50
    exit 1
  fi
fi

echo "Verifying build..."
nix build "$script_dir/../.."#gemini-cli

echo "Update completed successfully!"
if [ "$latest_version" = "$current_version" ]; then
  echo "Hashes have been updated for gemini-cli $current_version"
else
  echo "gemini-cli has been updated from $current_version to $latest_version"
fi
