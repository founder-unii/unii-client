#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$DIR/target"
TMP_DIR="/tmp/central-bundle/io/github/dev-unii/unii-java-sdk/0.1.0"

echo "==> Preparing files for signing..."
rm -rf /tmp/central-bundle
mkdir -p "$TMP_DIR"

cp "$TARGET_DIR/unii-java-sdk-0.1.0.jar" "$TMP_DIR/"
cp "$TARGET_DIR/unii-java-sdk-0.1.0-sources.jar" "$TMP_DIR/"
cp "$TARGET_DIR/unii-java-sdk-0.1.0-javadoc.jar" "$TMP_DIR/"
cp "$DIR/pom.xml" "$TMP_DIR/unii-java-sdk-0.1.0.pom"

cd "$TMP_DIR"

echo "==> Signing files with GPG (.asc)..."
for f in unii-java-sdk-0.1.0.jar unii-java-sdk-0.1.0-sources.jar unii-java-sdk-0.1.0-javadoc.jar unii-java-sdk-0.1.0.pom; do
    gpg --armor --detach-sign "$f"
    shasum -a 1 "$f" | awk '{print $1}' > "$f.sha1"
    md5 -q "$f" > "$f.md5"
    shasum -a 1 "$f.asc" | awk '{print $1}' > "$f.asc.sha1"
    md5 -q "$f.asc" > "$f.asc.md5"
done

BUNDLE_ZIP="$DIR/bundle-unii-java-sdk-0.1.0.zip"
rm -f "$BUNDLE_ZIP"
cd /tmp/central-bundle
zip -r "$BUNDLE_ZIP" io

echo "==> Successfully created signed bundle:"
echo "$BUNDLE_ZIP"
