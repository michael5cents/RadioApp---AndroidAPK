# Popz Place Radio 📻

[![Flutter](https://img.shields.io/badge/Flutter-^3.6.0-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-red.svg)](LICENSE)

A modern radio streaming application built with Flutter, optimized for foldable Android devices, particularly the Samsung Galaxy Fold 3.

## ✨ Features

- 🎵 High-quality audio streaming
- 📱 Optimized for foldable displays
- 🎨 Material Design UI
- 🌙 Background playback support
- 💾 Persistent settings
- 📡 Network state handling

## 📋 Requirements

- Flutter SDK ^3.6.0
- Android SDK 24 or higher
- Device running Android 7.0 or higher
- Internet connection for streaming

## 🔧 Dependencies

| Package | Version | Description |
|---------|---------|-------------|
| flutter | ^3.6.0 | Flutter SDK |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| http | ^1.1.2 | HTTP networking |
| audioplayers | ^5.2.1 | Audio playback |
| shared_preferences | ^2.2.2 | Local storage |
| js | ^0.6.7 | JavaScript interop |

## 🚀 Installation

### For Users

1. **Enable Unknown Sources**
   ```
   Settings > Security > Install Unknown Apps
   ```

2. **Download APK**
   - Download the latest release from [Releases](https://github.com/michael5cents/radio_flutter/releases)
   - Transfer to your Android device

3. **Install**
   - Open the APK file
   - Follow installation prompts
   - Grant required permissions

### For Developers

1. **Clone Repository**
   ```bash
   git clone https://github.com/michael5cents/radio_flutter.git
   cd radio_flutter
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run Development Build**
   ```bash
   flutter run
   ```

4. **Create Release Build**
   ```bash
   flutter build apk --release
   ```

## 📱 Device Support

- Primary Target: Samsung Galaxy Fold 3
- Minimum Android Version: 7.0 (API 24)
- Optimized for:
  - Foldable displays
  - Multi-window support
  - Dynamic screen resizing

## 🔒 Permissions

| Permission | Purpose |
|------------|---------|
| INTERNET | Required for streaming audio |
| ACCESS_NETWORK_STATE | Monitor network connectivity |
| WAKE_LOCK | Prevent sleep during playback |
| FOREGROUND_SERVICE | Background audio playback |

## 🛠️ Configuration

The app can be configured through:
- Android manifest settings
- build.gradle configurations
- Flutter environment variables

See [DEPLOYMENT_LOG.md](./DEPLOYMENT_LOG.md) for detailed configuration options.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit changes
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

## 🐛 Bug Reports

Report bugs by opening a new issue. Include:
- Detailed description
- Steps to reproduce
- Expected behavior
- Screenshots if applicable
- Device information

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Michael** - *Initial work* - [michael5cents](https://github.com/michael5cents)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- AudioPlayers package maintainers
- The open-source community

---
Made with ❤️ using Flutter
