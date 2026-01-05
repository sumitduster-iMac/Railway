# Railway Desktop App

A beautiful native macOS application for [Railway](https://railway.com) with an enhanced, modern UI (Lovable-style shell).

## Features

- Enhanced modern UI: loading screen, glassmorphism navigation bar, status bar
- Full web access to Railway.com inside an embedded webview
- Navigation controls: back, forward, refresh, home
- Status indicator: connected/offline + version display
- Secure Electron config: context isolation enabled

## Building

### Requirements
- Node.js (v20+ recommended)
- macOS (Intel-based Mac target, matching reference)

### Build Instructions

1. Clone the repository:
```bash
git clone https://github.com/sumitduster-iMac/Railway.git
cd Railway
```

2. Install dependencies:

```bash
npm ci
```

3. Run in development:

```bash
npm start
```

### Building the App

```bash
npm run build
```

The built app will be located in `dist/`.

## GitHub Actions

The project includes two GitHub Actions workflows:

- `CI`: validates structure and code on push/PR
- `Build and Release`: builds the macOS app and uploads artifacts; pushing a tag like `v1.0.0` creates a GitHub Release

## License

See [LICENSE](LICENSE) for details.