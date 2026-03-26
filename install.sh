#!/bin/bash
# Focus — one-line installer
# curl -sL https://raw.githubusercontent.com/saifulapm/focus/main/install.sh | bash

set -e

REPO="https://github.com/saifulapm/focus.git"
TMP_DIR=$(mktemp -d)

git clone --quiet "$REPO" "$TMP_DIR/focus"
bash "$TMP_DIR/focus/skills/focus/scripts/install.sh"
rm -rf "$TMP_DIR"
