#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc Sources/MacAndFiles/Localization.swift Sources/MacAndFiles/Types.swift Sources/MacAndFiles/TransferProgress.swift Sources/MacAndFiles/CLIInstallation.swift Tests/InstallationTests.swift -o .build/installation-tests
.build/installation-tests
