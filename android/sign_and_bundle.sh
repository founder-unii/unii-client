#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AAR_FILE=$(find "$DIR/build/outputs/aar" -name "*release*.aar" 2>/dev/null | head -n 1)

if [ -z "$AAR_FILE" ] || [ ! -f "$AAR_FILE" ]; then
    echo "Error: No release AAR found."
    echo "Please build the library first by running: ./gradlew assembleRelease"
    exit 1
fi

TMP_DIR="/tmp/central-bundle-android/io/github/dev-unii/unii-compose/0.1.0"
rm -rf /tmp/central-bundle-android
mkdir -p "$TMP_DIR"

echo "==> Copying AAR, POM, and Sources..."
cp "$AAR_FILE" "$TMP_DIR/unii-compose-0.1.0.aar"
cp "$DIR/pom.xml" "$TMP_DIR/unii-compose-0.1.0.pom"

# Pack sources if available
cd "$DIR/src/main"
jar -cf "$TMP_DIR/unii-compose-0.1.0-sources.jar" kotlin AndroidManifest.xml
cd "$TMP_DIR"

echo "==> Signing with GPG and computing checksums..."
for f in unii-compose-0.1.0.aar unii-compose-0.1.0.pom unii-compose-0.1.0-sources.jar; do
    gpg --armor --detach-sign "$f"
    shasum -a 1 "$f" | awk '{print $1}' > "$f.sha1"
    md5 -q "$f" > "$f.md5"
    shasum -a 1 "$f.asc" | awk '{print $1}' > "$f.asc.sha1"
    md5 -q "$f.asc" > "$f.asc.md5"
done

BUNDLE_ZIP="$DIR/bundle-unii-compose-0.1.0.zip"
rm -f "$BUNDLE_ZIP"
cd /tmp/central-bundle-android
zip -r "$BUNDLE_ZIP" io

echo "==> Successfully created Android bundle:"
echo "$BUNDLE_ZIP"
