# Contributing

You can fork, modify and redistribute the project-owned source under MIT. Start with [AGENT.md](AGENT.md) for the architecture and safety invariants, then build locally using README.md. Preserve third-party licenses and Android attribution as described in THIRD_PARTY_NOTICES.md.

Submit focused changes with the problem, resulting behavior and verification. Transfer changes should pass scripts/test.sh; hardware claims need a designated device and recorded test result. Do not attach private file listings or raw diagnostics containing user names/files to public issues.

UI text follows native macOS localization, with English as the development language. Keep new controls native to macOS and use system accent colors. The authoritative icon is Resources/Icon/AppIcon-master.png; alternate concepts are in design/. Include the source artwork and update credits when replacing it.

New dependencies require their license, version, source and packaging implications to be documented. Update corresponding source archives if changing bundled LGPL library versions. Public releases follow docs/RELEASING.md.

## Translations

Read [docs/LOCALIZATION.md](docs/LOCALIZATION.md) for native language resources, plural rules and verification. Keep the English README and its linked translations aligned. Fluent-speaker improvements are welcome; preserve safety and license meaning, format placeholders and device/file names.
