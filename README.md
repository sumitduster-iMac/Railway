<p align="center">
  <img src="assets/icon.svg" alt="Railway Desktop" width="128" height="128">
</p>

<h1 align="center">Railway Desktop</h1>

<p align="center">
  <strong>A beautiful native macOS application for <a href="https://railway.com">Railway</a></strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#development">Development</a> •
  <a href="#building">Building</a> •
  <a href="#license">License</a>
</p>

---

## ✨ Features

- **Modern UI** — Glassmorphism design with smooth animations and a polished loading screen
- **Native Experience** — Full Railway.com access inside an embedded webview
- **Navigation Controls** — Back, forward, refresh, and home buttons
- **Status Indicator** — Real-time connection status and version display
- **Secure by Default** — Context isolation enabled with strict CSP policies
- **Dark Theme** — Beautiful dark navy background with gradient accents

## 🎨 Design

```
┌───────────────────────────────────────────────┐
│ Navigation Bar (draggable, glassmorphism)     │
│  ◄  ►  ⟳        🌐 railway.com            🏠   │
├───────────────────────────────────────────────┤
│                                               │
│            railway.com (webview)              │
│                                               │
├───────────────────────────────────────────────┤
│ ● Connected                    Railway Desktop │
└───────────────────────────────────────────────┘
```

**Visual Highlights:**
- Dark navy background gradient
- Blue → Pink accent gradient
- Frosted glass navigation and status bars
- Animated loading screen with logo pulse effect

## 📦 Installation

### Download

Download the latest release from the [Releases](../../releases) page.

### Build from Source

See the [Development](#development) section below.

## 🛠️ Development

### Requirements

- **Node.js** v20 or later
- **macOS** (Intel-based Mac target)

### Quick Start

1. **Clone the repository:**

```bash
git clone https://github.com/sumitduster-iMac/Railway.git
cd Railway
```

2. **Install dependencies:**

```bash
npm ci
```

3. **Run in development mode:**

```bash
npm start
```

## 🏗️ Building

### Build for Distribution

```bash
npm run build
```

The built application will be located in the `dist/` directory.

### Build DMG Installer

```bash
npm run build-dmg
```

## 🔄 GitHub Actions

The project includes automated CI/CD workflows:

| Workflow | Description |
|----------|-------------|
| **CI** | Validates project structure and code on every push/PR |
| **Build and Release** | Builds the macOS app and uploads artifacts; creates GitHub Releases for version tags (e.g., `v1.0.0`) |

## 📁 Project Structure

```
Railway/
├── assets/           # App icons and images
├── scripts/          # Build and icon generation scripts
├── Railway/          # Native Swift components (iOS/macOS)
├── main.js           # Electron main process
├── preload.js        # Electron preload script
├── index.html        # Main application window
├── styles.css        # Application styles
├── about.html        # About window
└── about.css         # About window styles
```

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for the Railway community
</p>
