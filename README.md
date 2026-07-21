# MarkDownshift

MarkDownshift is a small, native Markdown editor for macOS. It opens and saves `.md` files directly—there is no import, export, cloud account, or file conversion.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black)
![License](https://img.shields.io/badge/license-MIT-gold)
![Version](https://img.shields.io/badge/version-1.2-red)

## Features

- Create, open, edit, save, and save Markdown files anywhere
- Open multiple documents in independent windows
- Open `.md` files directly from Finder
- Edit, split editor/preview, and preview-only modes
- Formatting toolbar for headings, bold, italic, strikethrough, lists, quotes, links, and inline code
- Native macOS document handling and unsaved-change protection
- Standard shortcuts: `⌘N`, `⌘O`, `⌘S`, `⇧⌘S`, `⌘W`, `⌘B`, and `⌘I`
- No telemetry, accounts, network access, or data collection

## Requirements

- macOS 14 Sonoma or newer
- Apple Silicon or Intel Mac when using a Universal release
- Command Line Tools for Xcode when building from source

## Install from source

Open Terminal in this folder and run:

```sh
./scripts/install.sh
```

This builds MarkDownshift and copies it to `/Applications/MarkDownshift.app`. Open it from Applications, then right-click its Dock icon and choose **Options → Keep in Dock**.

Because a locally built app is not App Store-signed, macOS may ask you to confirm the first launch. If necessary, right-click the app and choose **Open**.

## Build without installing

Build for the current Mac:

```sh
./scripts/build-app.sh
```

Build a Universal application for Apple Silicon and Intel Macs:

```sh
./scripts/build-universal-app.sh
```

The application is written to `dist/MarkDownshift.app`.

## Privacy

MarkDownshift works entirely on your Mac. It does not transmit documents, collect analytics, require an account, or connect to an external service. See [PRIVACY.md](PRIVACY.md).

## Contributing

Bug reports, ideas, documentation improvements, and code contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md).

## Why this project exists

MarkDownshift is a simple, useful Markdown editor for Mac. It is free to use, modify, and share.

## License

Copyright © 2026 Jean-Marc Frayret. Released under the [MIT License](LICENSE).
