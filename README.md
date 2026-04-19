# Kinotask 🌌

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Samsung One UI](https://img.shields.io/badge/Design-Samsung_One_UI-034EA2?style=for-the-badge&logo=samsung&logoColor=white)](https://developer.samsung.com/one-ui)

**Kinotask** is a premium, high-performance productivity ecosystem for Android, meticulously designed to blend Samsung's One UI aesthetics with hardcore security and reliability.

---

## ✨ Features

### 🕒 Relentless Scheduling
- **Insistent Alarms**: High-priority tasks trigger a persistent alarm loop that ignores Do Not Disturb and won't stop until a randomized Captcha is solved.
- **Background Persistence**: Scheduled via `android_alarm_manager_plus`, ensuring triggers even if the app is closed or the device is in Deep Sleep.
- **Full-Screen Intent**: Alarms bypass the lock screen to demand immediate attention for high-stakes tasks.

### 🔐 Secure Vault
- **AES-256 Encryption**: Local data is encrypted via `HiveAesCipher` using secure keys managed by the Android Keystore.
- **Multi-Module Storage**:
  - **Passwords**: Secure password manager with visibility toggles and CSV import support.
  - **Cards**: OCR-powered credit card scanner with Luhn validation.
  - **Documents**: High-resolution document scanner with edge detection and in-app interactive preview.
  - **Notes**: Encrypted rich-text scratchpad for sensitive information.

### 🎨 Premium One UI Design
- **120Hz Fluidity**: Optimized repaint boundaries and custom `SquircleToggle` widgets ensure a stutter-free experience on high-refresh-rate displays.
- **Stitch Design System**: Custom glassmorphic elements, vibrant gradients, and haptic-responsive interactions.
- **Dynamic Interface**: Segmented controls and interactive progress rings for "Deep Work" focus timers.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Local Database**: [Hive](https://pub.dev/packages/hive) (Encrypted NoSQL)
- **Background Tasks**: [Android Alarm Manager Plus](https://pub.dev/packages/android_alarm_manager_plus)
- **OCR Engine**: [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)
- **Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **Animations**: [Flutter Animate](https://pub.dev/packages/flutter_animate)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- A physical Android device (recommended for testing 120Hz performance and Alarm captures)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Trapston3/Kinotask.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 🛡 Security Note

Kinotask is built for **local-first privacy**. No data leaves your device. Encryption keys are generated locally and stored in the secure hardware module (Secure Element/TEE) where available.

---

## 📜 License

Created with ❤️ by Trapston3. Distributed under the MIT License.
