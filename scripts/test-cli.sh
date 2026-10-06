#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc Sources/MacAndFiles/Localization.swift Sources/MacAndFiles/Types.swift Sources/MacAndFiles/TransferProgress.swift Sources/MacAndFiles/AppInfo.swift Sources/MacAndFiles/DeviceAccess.swift Sources/MacAndFiles/CLI.swift Tests/CLITests.swift -o .build/aft-cli-tests
.build/aft-cli-tests
