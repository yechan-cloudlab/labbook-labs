#!/usr/bin/env bash
# Build a minimal Java 21 Lambda zip (handler example.Handler::handleRequest).
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
DIST="$BASE/dist"
WK="$BASE/src/java/build"
mkdir -p "$DIST" "$WK"
rm -rf "$WK"/*
# Need javac 21+ and aws-lambda-java-core
if ! command -v javac >/dev/null; then
  echo "javac not found" >&2
  exit 1
fi
CORE="$WK/aws-lambda-java-core-1.2.3.jar"
if [[ ! -f "$CORE" ]]; then
  curl -fsSL -o "$CORE" \
    https://repo1.maven.org/maven2/com/amazonaws/aws-lambda-java-core/1.2.3/aws-lambda-java-core-1.2.3.jar
fi
javac --release 21 -cp "$CORE" -d "$WK/classes" "$BASE/src/java/src/example/Handler.java"
# zip: classes at root + the core jar at root? Lambda java runtime needs classes in zip root
# and dependencies in the zip as well (or as lib/). Put core jar at jar root is not auto-loaded.
# Standard is classes at root, deps in lib/.
mkdir -p "$WK/package/lib"
cp -r "$WK/classes/." "$WK/package/"
cp "$CORE" "$WK/package/lib/"
( cd "$WK/package" && zip -qr "$DIST/java-handler.zip" . )
echo "wrote $DIST/java-handler.zip"
unzip -l "$DIST/java-handler.zip"
