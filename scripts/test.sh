#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc Sources/MacAndFiles/Localization.swift Sources/MacAndFiles/Types.swift Sources/MacAndFiles/TransferProgress.swift Tests/TransferEngineTests.swift -o .build/bridge-tests
.build/bridge-tests
