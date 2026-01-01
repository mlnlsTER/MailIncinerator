# Mail Incinerator

macOS utility for scanning and deleting Apple Mail cache data.

<APP ICON>

---

## Overview

**Mail Incinerator** helps reclaim disk space by detecting and deleting cache directories created by Apple Mail.
The application scans Mail-related cache locations, calculates their size, and allows safe, explicit removal.

The tool does **not** modify mail databases, accounts, or message content.

---

## Features

- Scans Apple Mail cache directories
- Displays detected folders and their sizes
- Shows exactly what will be deleted
- Opens any detected folder in Finder
- Permanently removes selected cache data
- Cancellation-safe scanning
- Localized UI
- No background services

---

## Screenshots

<Screenshots>

---

## Requirements

- macOS 14 or newer
- Apple Mail (built-in Mail.app)
- Developer ID build (not Mac App Store)

---

## Permissions & Privacy

### Mail access

Apple Mail must be **closed** before scanning.
The app checks whether Mail is running and requests the user to quit it before continuing.

### Disk access

Depending on the distribution type:

- **Public (GitHub) build**  
  Requires *Full Disk Access* to scan Mail cache directories.

- **App Store build (planned)**  
  Uses user-selected folder access via `NSOpenPanel`.

No data is collected or transmitted.

---

## Usage

1. Quit Apple Mail
2. Launch Mail Incinerator
3. Start scanning
4. Review detected cache folders and sizes
5. Delete selected data

Deleted data **cannot be recovered**.

> [!NOTE]
> Mail Incinerator is not affiliated with Apple Inc.
> Use at your own risk.

---

## License

GPL v3.0
