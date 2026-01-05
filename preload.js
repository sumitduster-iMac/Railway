const { contextBridge } = require('electron');
const { app } = require('electron');

contextBridge.exposeInMainWorld('electron', {
  platform: process.platform,
  version: process.versions.electron,
  appVersion: app.getVersion()
});

