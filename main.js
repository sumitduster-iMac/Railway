const { app, BrowserWindow, shell } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
  const iconPath = path.join(__dirname, 'assets', 'icon.png');

  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    titleBarStyle: 'hiddenInset',
    backgroundColor: '#0F172A',
    icon: iconPath,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      // Note: sandbox must be false to enable webviewTag.
      // The <webview> itself runs in its own sandboxed process.
      sandbox: false,
      webviewTag: true
    },
    show: false,
    center: true
  });

  mainWindow.loadFile('index.html');

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // Open external links in default browser.
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http') || url.startsWith('https')) {
      shell.openExternal(url);
      return { action: 'deny' };
    }
    return { action: 'allow' };
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  // Customize the macOS "About" window (shown in the screenshot).
  if (process.platform === 'darwin') {
    try {
      app.setAboutPanelOptions({
        applicationName: 'Railway',
        applicationVersion: app.getVersion(),
        // Shows as a dedicated "Credits" line in the About panel on macOS.
        credits: 'Developed by Sumit Duster',
        website: 'https://railway.com',
        copyright: `Copyright © ${new Date().getFullYear()} Railway · Developed by Sumit Duster`,
      });
    } catch (_) {
      // Ignore if not supported in this Electron version/environment.
    }
  }

  // Ensure dock icon is correct in development builds on macOS.
  if (process.platform === 'darwin' && app.dock) {
    const iconPath = path.join(__dirname, 'assets', 'icon.png');
    try {
      const maybePromise = app.dock.setIcon(iconPath);
      if (maybePromise && typeof maybePromise.catch === 'function') {
        maybePromise.catch(() => {});
      }
    } catch (_) {
      // Ignore failures (e.g., missing icon in some dev setups).
    }
  }

  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

