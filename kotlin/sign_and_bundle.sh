#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M2_DIR="$HOME/.m2/repository/io/github/dev-unii/unii-kotlin/0.1.0"

if [ ! -d "$M2_DIR" ] || [ ! -f "$M2_DIR/unii-kotlin-0.1.0.jar" ]; then
    echo "==> Building and publishing to Maven Local..."
    "$DIR/gradlew" -p "$DIR" publishToMavenLocal
fi

TMP_DIR="/tmp/central-bundle-kotlin/io/github/dev-unii/unii-kotlin/0.1.0"
rm -rf /tmp/central-bundle-kotlin
mkdir -p "$TMP_DIR"

echo "==> Copying JARs, POM, and metadata..."
cp "$M2_DIR/unii-kotlin-0.1.0.jar" "$TMP_DIR/"
cp "$M2_DIR/unii-kotlin-0.1.0.pom" "$TMP_DIR/"
if [ -f "$M2_DIR/unii-kotlin-0.1.0-sources.jar" ]; then
    cp "$M2_DIR/unii-kotlin-0.1.0-sources.jar" "$TMP_DIR/"
fi
if [ -f "$M2_DIR/unii-kotlin-0.1.0-javadoc.jar" ]; then
    cp "$M2_DIR/unii-kotlin-0.1.0-javadoc.jar" "$TMP_DIR/"
fi
if [ -f "$M2_DIR/unii-kotlin-0.1.0.module" ]; then
    cp "$M2_DIR/unii-kotlin-0.1.0.module" "$TMP_DIR/"
fi

cd "$TMP_DIR"

echo "==> Signing with GPG and computing checksums..."
for f in $(ls); do
    gpg --armor --detach-sign "$f"
    shasum -a 1 "$f" | awk '{print $1}' > "$f.sha1"
    md5 -q "$f" > "$f.md5"
    shasum -a 1 "$f.asc" | awk '{print $1}' > "$f.asc.sha1"
    md5 -q "$f.asc" > "$f.asc.md5"
done

BUNDLE_ZIP="$DIR/bundle-unii-kotlin-0.1.0.zip"
rm -f "$BUNDLE_ZIP"
cd /tmp/central-bundle-kotlin
zip -r "$BUNDLE_ZIP" io

echo "==> Successfully created Kotlin bundle:"
echo "$BUNDLE_ZIP"
