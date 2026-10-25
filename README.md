# Financio

A lightweight native macOS app for tracking **monthly recurring costs**, with a focus on subscriptions and financing.

No Electron, no browser, no cloud — just Swift + AppKit, local storage, and automatic light/dark mode via system appearance.

![macOS](https://img.shields.io/badge/macOS-14%2B-black)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)

## Features

- Monthly total of all active expenses at a glance
- Categories: **Subscription**, **Financing**, **Other**
- Entries with amount (€), billing day, and optional note
- Sidebar filters, search, and toggle for inactive items
- Follows macOS light / dark / auto appearance
- Persisted as JSON at  
  `~/Library/Application Support/Financio/expenses.json`

## Requirements

- macOS 14 or later
- [Xcode Command Line Tools](https://developer.apple.com/xcode/) (`xcode-select --install`)

Full Xcode is not required.

## Build & Run

```bash
git clone https://github.com/FleXtheCoder/financio.git
cd financio
./Scripts/build.sh
open dist/Financio.app
```

Install permanently (optional):

```bash
cp -R dist/Financio.app /Applications/
```

Release build (default):

```bash
./Scripts/build.sh release
```

Debug build:

```bash
./Scripts/build.sh debug
```

## Keyboard Shortcuts

| Action | Shortcut |
| --- | --- |
| New entry | ⌘N |
| Edit | ⌘E or double-click |
| Delete | ⌫ |
| Quit | ⌘Q |

Toolbar: show/hide inactive items, search, add a new entry.

## Project Structure

```
financio/
├── Package.swift          # Swift package manifest
├── Sources/Financio/      # App source
│   ├── Models/            # Expense model & categories
│   ├── Store/             # JSON persistence
│   └── Views/             # AppKit UI
├── Resources/             # Info.plist, app icon
├── Scripts/build.sh       # Release build → .app bundle
└── ios_icons/             # Source assets for the app icon
```

## Privacy

All data stays on your Mac. No telemetry, no accounts, no network access from the app.

## License

No license file yet. Feel free to add one (e.g. MIT) if you fork or contribute.
