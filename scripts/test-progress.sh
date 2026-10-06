#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc Sources/MacAndFiles/Localization.swift Sources/MacAndFiles/Types.swift Sources/MacAndFiles/TransferProgress.swift Tests/ProgressTests.swift -o .build/progress-tests
.build/progress-tests
