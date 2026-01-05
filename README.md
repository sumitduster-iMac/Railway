# Railway

A native macOS application that provides quick access to [Railway](https://railway.com) - a deployment platform for developers.

## Features

- Native macOS app built with SwiftUI
- Displays the Railway website in a native WebView
- Optimized for Intel Mac (x86_64 architecture)
- Clean, minimal interface with hidden title bar

## Building

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Intel Mac or Apple Silicon Mac

### Build Instructions

1. Clone the repository:
```bash
git clone https://github.com/sumitduster-iMac/Railway.git
cd Railway
```

2. Open the project in Xcode:
```bash
open Railway.xcodeproj
```

3. Build and run:
   - Select the Railway scheme
   - Choose your target device
   - Press `Cmd + R` to build and run

### Command Line Build

To build from the command line for Intel Mac:

```bash
xcodebuild \
  -project Railway.xcodeproj \
  -scheme Railway \
  -configuration Release \
  -arch x86_64 \
  -derivedDataPath build
```

The built app will be located at `build/Build/Products/Release/Railway.app`

## GitHub Actions

The project includes a GitHub Actions workflow that automatically builds the app on every push/PR to the main branches. The workflow:

- Runs on `macos-latest`
- Builds a universal app (`x86_64` + `arm64`)
- Uploads the built app as a zipped artifact

You can find the workflow configuration in `.github/workflows/build-macos.yml`.

## License

See [LICENSE](LICENSE) for details.