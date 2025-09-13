#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Fetching latest release info from just-every/code..."
release_info=$(curl -s https://api.github.com/repos/just-every/code/releases/latest)

# Extract version from tag name (removes 'v' prefix)
version=$(echo "$release_info" | jq -r '.tag_name' | sed 's/^v//')

echo "Latest version: $version"

# Update version in package.nix
sed -i "s/version = \"[^\"]*\"/version = \"$version\"/" package.nix

# Download and calculate hashes for each platform
declare -A platforms=(
  ["x86_64-linux"]="code-x86_64-unknown-linux-musl.tar.gz"
  ["aarch64-linux"]="code-aarch64-unknown-linux-musl.tar.gz"
  ["x86_64-darwin"]="code-x86_64-apple-darwin.tar.gz"
  ["aarch64-darwin"]="code-aarch64-apple-darwin.tar.gz"
)

for platform in "${!platforms[@]}"; do
  filename="${platforms[$platform]}"
  url="https://github.com/just-every/code/releases/download/v${version}/${filename}"

  echo "Calculating hash for ${platform}..."
  hash=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)

  # Update hash in package.nix
  sed -i "/${platform} = {/,/};/s|hash = \"sha256-[^\"]*\"|hash = \"$hash\"|" package.nix
done

echo "Update complete!"
