# Agent CLI (`maf`)

The native MacAndFiles app includes a terminal interface. It runs locally over USB using the same libmtp backend and transfer safety rules as the GUI. No daemon, network port, account, ADB or USB debugging is required. MCP is not included; terminal-capable agents can invoke `maf` directly.

## Installation

After installing `/Applications/MacAndFiles.app`:

```sh
scripts/install-cli.sh
```

The installer creates a symlink to the bundled native launcher at `~/.local/bin/maf`. It also installs `aft` as a compatibility alias and migrates this project’s previous `aft` symlink. It refuses to overwrite unrelated commands, checking both names before changing either one. Add that directory to PATH if necessary. An optional second argument selects another writable bin directory; the first argument selects the app:

```sh
scripts/install-cli.sh "/Applications/MacAndFiles.app" "$HOME/.local/bin"
```

Without a source checkout, use the CLI inside the app directly:

```sh
"/Applications/MacAndFiles.app/Contents/MacOS/maf" help
```

The native launcher resolves its actual bundle location, even when invoked through a symlink, and executes the app's actual binary by its full bundle path so localizations and bundled libraries remain available. Opening the app normally starts its GUI. CLI commands, including invalid arguments, do not open a window.

## Commands

| Command | Required options | Optional options |
| --- | --- | --- |
| `help`, `--help` | None | None |
| `version`, `--version` | None | None |
| `devices` | None | None |
| `status` | none | Advisory USB ownership, no MTP session |
| `storages` | `--device ID` | None |
| `ls` | `--device ID --storage ID` | `--path /` |
| `upload` | `--device ID --storage ID --from LOCAL --to /REMOTE_FOLDER` | Repeat `--from`; `--progress` |
| `download` | `--device ID --storage ID --path /REMOTE_ITEM --to LOCAL_FOLDER` | `--progress` |
| `mkdir` | `--device ID --storage ID --path /NEW_FOLDER` | None |

IDs come from `devices` and `storages`; do not guess them. Device IDs describe the current USB connection and can change after reconnecting. Storage IDs are positive UInt32 values, in decimal or `0x` hexadecimal. Every connected command selects its device explicitly. Android paths are absolute and relative to the selected storage root. Paths match exact Unicode names; duplicate names produce `ambiguous_path`. Repeated or trailing slashes are normalized. Traversal (`.`/`..`), colon and NUL names are rejected.

`ls` lists a single folder; it is not a recursive search. `mkdir` creates one folder; its parent must exist. Uploads/downloads recurse through folders with the engine's depth limit. Download selects one file/folder beneath the storage root and copies it into an existing Mac directory. Upload may select multiple Mac files/folders. Quote paths containing spaces. `--from` accepts a single path per occurrence, with no shell glob expansion implemented by the CLI.

There are no overwrite, delete, rename or unrestricted shell-execution commands. Name collisions fail. Download bytes are staged, checked for size, then published; failed temporary files are removed. Symbolic links and special files are rejected. A later failure can leave earlier completed files/folders. Upload failures or cancellation can leave partial objects on Android.

## Output contract

Stdout contains exactly one UTF-8 JSON object and a trailing newline, on success and failure:

```json
{
  "schemaVersion": 1,
  "app": "MacAndFiles",
  "version": "1.0.0",
  "build": "8",
  "command": "devices",
  "ok": true,
  "result": { "devices": [] }
}
```

The `app` metadata is now `MacAndFiles`; commands, schemaVersion 1, error codes and exit statuses remain compatible with the previous `aft` interface.

Parse `ok` and `error.code`, not human-readable error messages. Messages may follow native macOS language settings or contain upstream English diagnostics. `schemaVersion` defines the envelope contract; consumers should tolerate additional fields. `devices` may succeed with an empty list. Listings use `kind`, `sizeBytes` and `modifiedUnixSeconds`. Capacity/free values are bytes.

Errors contain `error: {code, message, exitCode}` and `completed: []`. Transfer success contains `result.completed`. Each receipt includes direction, absolute localPath, storageID and kind (`file` or `folder_created`). Downloads and newly created Android folders include objectID. Uploaded file receipts include parentID, since the engine does not return their object ID. A folder-created receipt means the folder exists; it does not assert its children all succeeded.

`partialCompletionPossible` is conservative: it becomes true when a transfer/mkdir is attempted, even if preflight subsequently fails before writing. `androidPartialFilesPossible` applies to attempted uploads. Completed receipts cover confirmed engine milestones; a USB failure can prevent confirming an Android object that was physically written. Always inspect the device before retrying a failed upload, and do not infer rollback from an error.

`--progress` writes JSON lines with `event: "progress"` and `activeFileFraction` to stderr. `activeFileFraction` resets for each active item; `overallFraction` measures the batch. Upstream library diagnostics also go to stderr, so stderr is not exclusively JSON. Agents should use the final stdout envelope for the result.

| Exit status | Codes/meaning |
| --- | --- |
| `0` | Success |
| `1` | `transfer_failed`, `usb_open_failed`, `lock_failed`, `io_error`, or another operational failure |
| `2` | `invalid_arguments`, `invalid_path` |
| `3` | `device_not_found`, `storage_not_found`, `not_found` |
| `4` | `device_busy` (another cooperating GUI/CLI session owns this device) |
| `5` | `already_exists`, `ambiguous_path`, `unsupported_file`, `not_a_directory` |
| `130` | `cancelled` |

## Sessions, cancellation and agents

Disconnect the GUI's USB session before a CLI file operation. Each CLI process opens a session for its command and closes it before exiting. A per-device advisory lock serializes cooperating GUI, CLI and verification processes; crashing releases the kernel lock. Keep lock files in place. A third-party MTP app does not share this lock and can still prevent USB opening (`usb_open_failed`). The CLI never terminates another app or steals its connection.

Ctrl-C/SIGINT and SIGTERM request cooperative cancellation. The libmtp streaming callback stops the active transfer; completed entries remain. Non-streaming USB calls may return before cancellation can be handled. Cancellation has no rollback guarantee, particularly for Android uploads.

A terminal agent should discover devices, read the selected storage, list the destination, run the requested operation, then inspect its JSON and exit code. Device access alone is not authorization to inspect every personal file or upload unrelated data. Keep diagnostics and personal paths out of public logs. The CLI has no built-in approval interface; authorization comes from the calling agent/user.

## Diagnostics and testing

The app binary also retains `--diagnose`, `--probe` and `--verify-transfer [--report PATH]`. These legacy diagnostics do not use the versioned CLI envelope. Hardware verification writes disposable UUID fixtures; use it only on an explicitly authorized test device, with the GUI disconnected.

```sh
scripts/test.sh
scripts/test-cli.sh
scripts/test-localization.sh
```

CLI tests use an injectable backend for command validation, exact Unicode resolution, ambiguous paths, session cleanup, upload/download receipts, partial failure, cancellation and advisory-lock contention. Mock tests cannot establish physical USB transfer success. Record installed/extracted CLI and hardware validation separately in VALIDATION.md.

## Whole-operation status in build 9

`maf status` detects devices without opening MTP and reports each device’s `busy` advisory-lock status. It covers cooperating MacAndFiles processes; third-party USB owners are not detected. **More → Terminal and Agents** shows the GUI connection owner and installs `maf` plus the `aft` compatibility alias after checking for unrelated commands.

Transfers retain `schemaVersion: 1`. `--progress` emits JSON lines to stderr with `event: "progress"`, `totalFiles`, `completedFiles`, `totalBytes`, `transferredBytes`, `overallFraction`, `activeItem`, `activeFileFraction`, `bytesPerSecond`, `elapsedSeconds`, optional `remainingSeconds`, `finished` and `failedItems`. Successful results and transfer failures include a final `transfer` snapshot. File counts exclude directories; a file completes only after verification/publication. Inventory runs before the transfer. The operation stops at the first failure; unattempted files are not labeled failed. Average speed includes time spent in the transfer.

Device cancellation may wait for an MTP protocol timeout. On Ctrl-C the CLI skips a further CloseSession attempt after cancellation and exits after its JSON result; process exit releases USB handles and the lock. Some devices need USB reconnection after an interrupted session. Completed files remain; Android may retain partial files.
