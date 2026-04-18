#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_JSON="$REPO_ROOT/pkgs/openclaw/version.json"
LOCKFILE="$REPO_ROOT/pkgs/openclaw/package-lock.json"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION=$(curl -fsSL https://registry.npmjs.org/openclaw/latest | jq -r .version)
fi

OLD=$(jq -r .version "$VERSION_JSON")

if [[ "$OLD" == "$VERSION" ]]; then
  echo "openclaw: already up to date ($VERSION)"
  exit 0
fi

TARBALL_URL="https://registry.npmjs.org/openclaw/-/openclaw-${VERSION}.tgz"

echo "openclaw: fetching tarball hash for $VERSION..."
TARBALL_HASH_NIX32=$(nix-prefetch-url "$TARBALL_URL")
TARBALL_HASH=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "$TARBALL_HASH_NIX32")

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "openclaw: generating package-lock.json..."
curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMPDIR"
(cd "$TMPDIR/package" && npm install --package-lock-only --legacy-peer-deps 2>/dev/null)

echo "openclaw: computing npm deps hash..."
NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps -- "$TMPDIR/package/package-lock.json" 2>/dev/null)

cp "$TMPDIR/package/package-lock.json" "$LOCKFILE"

jq -n --arg v "$VERSION" --arg t "$TARBALL_HASH" --arg n "$NPM_DEPS_HASH" \
  '{version:$v, tarballHash:$t, npmDepsHash:$n}' > "$VERSION_JSON.tmp"
mv "$VERSION_JSON.tmp" "$VERSION_JSON"

echo "openclaw: $OLD → $VERSION"
