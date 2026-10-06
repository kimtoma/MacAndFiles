#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
COPYFILE_DISABLE=1 tar --exclude='./dist' --exclude='./.build' --exclude='./.git' --exclude='.DS_Store' --exclude='__pycache__' --exclude='*.pyc' --exclude='./.env*' --exclude='*.p12' --exclude='*.mobileprovision' --exclude='./.swiftpm' --exclude='./.vscode' --exclude='./.idea' -czf dist/MacAndFiles-source.tar.gz .
echo "Built: $PWD/dist/MacAndFiles-source.tar.gz"
