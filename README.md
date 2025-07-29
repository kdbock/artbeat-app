# ARTbeat - Creative Content Discovery Platform

<div align="center">
  <img src="assets/logo.png" alt="ARTbeat Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.32.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.8.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?style=flat&logo=firebase)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  
  **A comprehensive Flutter application for creative content discovery, artist showcasing, and community engagement**
</div>

---

## 🎨 About ARTbeat

ARTbeat is a modular Flutter application that serves as a platform for creative content discovery, artist showcasing, and community engagement. The app features robust authentication, social networking, and specialized features for artists, galleries, and art enthusiasts.

### ✨ Key Features

- **🔐 Complete Authentication System** - Email/password login, registration, and password recovery
- **👤 Rich Profile Management** - User profiles with stats, photo management, and social features
- **🎭 Artist Subscription Tiers** - Basic (Free), Pro ($9.99/month), and Gallery ($49.99/month) plans
- **🖼️ Artwork Management** - Upload, showcase, and discover art collections
- **🚶‍♂️ Art Walk Discovery** - Interactive map-based discovery of public art with custom walking routes
- **💬 Social Features** - Follow/unfollow, comments, likes, and real-time messaging
- **⚙️ Comprehensive Settings** - Account management, privacy controls, and notification preferences
- **💳 Payment Integration** - Complete Stripe integration for subscription management
- **📱 Offline Support** - Firebase offline persistence and local data caching

---

## 🏗️ Architecture

ARTbeat is built using a **modular architecture** where each feature is encapsulated in its own Flutter package. This approach provides:

- **🔧 Improved Maintainability** - Isolated features for easier debugging and updates
- **👥 Parallel Development** - Multiple developers can work on different modules simultaneously
- **🧪 Better Testing** - Each module can be tested independently
- **♻️ Code Reusability** - Components can be reused across projects

### 📦 Module Structure

```
packages/
├── artbeat_core/         # 🏛️ Shared functionality and UI components
├── artbeat_auth/         # 🔐 User authentication flows
├── artbeat_profile/      # 👤 User profile management
├── artbeat_artist/       # 🎭 Artist and gallery management
├── artbeat_artwork/      # 🖼️ Artwork-related features
├── artbeat_art_walk/     # 🚶‍♂️ Public art discovery
├── artbeat_community/    # 💬 Social and interaction features
├── artbeat_capture/      # 📸 Image capture and processing
├── artbeat_messaging/    # 💌 User messaging system
├── artbeat_events/       # 📅 Event creation and management
├── artbeat_settings/     # ⚙️ User preferences and account management
├── artbeat_admin/        # 👑 Administrative features
└── artbeat_ads/          # 📢 Advertisement management
```

---

## 🚀 Getting Started

### 📋 Prerequisites

- **Flutter SDK**: 3.32.0 or higher
- **Dart SDK**: 3.8.0 or higher
- **Development Environment**: Android Studio / Xcode
- **Firebase Project**: With Authentication, Firestore, and Storage enabled
- **Google Maps API Key**: For Art Walk feature
- **Stripe Account**: For payment processing

### 🛠️ Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/artbeat.git
   cd artbeat
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up Firebase**

   ```bash
   # Copy the template file
   cp lib/firebase_options.template.dart lib/firebase_options.dart

   # Update with your Firebase configuration
   # See Firebase Configuration section below
   ```

4. **Configure environment variables**

   ```bash
   cp .env.example .env
   # Update .env with your API keys and configuration
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

### 🔥 Firebase Configuration

> **⚠️ SECURITY NOTICE:** Never commit `firebase_options.dart` to version control!

1. **Get Firebase Configuration**

   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project → Project Settings
   - Add your app and get configuration details

2. **Update Configuration File**

   ```dart
   // lib/firebase_options.dart
   static const FirebaseOptions currentPlatform = FirebaseOptions(
     apiKey: 'YOUR_API_KEY',
     appId: 'YOUR_APP_ID',
     messagingSenderId: 'YOUR_SENDER_ID',
     projectId: 'YOUR_PROJECT_ID',
   );
   ```

3. **Enable Required Services**
   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage
   - Firebase Analytics
   - Firebase App Check

---

## 🏃‍♂️ Development

### 🔧 Running Individual Modules

Each module can be run independently for faster development:

```bash
# Using the provided script
./scripts/run_module.sh artbeat_auth

# Or manually
cd packages/artbeat_auth
flutter run -t lib/bin/main.dart
```

### 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests for specific module
cd packages/artbeat_core
flutter test

# Run integration tests
flutter test integration_test/
```

### 🏗️ Building

```bash
# Android
./scripts/build_android.sh

# iOS
./scripts/build_ios.sh

# Release builds
flutter build appbundle --release  # Android
flutter build ios --release        # iOS
```

---

## 🛠️ Tech Stack

### 📱 Frontend

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **Material Design** - UI components

### ☁️ Backend & Services

- **Firebase Authentication** - User management
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File storage
- **Firebase Functions** - Server-side logic (Node.js 22)
- **Firebase Analytics** - Usage tracking

### 🗺️ Maps & Location

- **Google Maps Flutter** - Interactive maps
- **Geolocator** - Location services
- **Geocoding** - Address conversion

### 💳 Payments

- **Stripe** - Payment processing
- **Subscription Management** - Recurring billing

### 🔧 Development Tools

- **GitHub Actions** - CI/CD pipeline
- **Flutter Lints** - Code quality
- **Mockito** - Testing framework

---

## 📊 Subscription Tiers

| Feature            | Basic (Free) | Pro ($9.99/month) | Gallery ($49.99/month) |
| ------------------ | ------------ | ----------------- | ---------------------- |
| Artist Profile     | ✅           | ✅                | ✅                     |
| Artwork Listings   | 5            | Unlimited         | Unlimited              |
| Analytics          | Basic        | Advanced          | Advanced               |
| Community Features | ✅           | ✅                | ✅                     |
| Featured Placement | ❌           | ✅                | ✅                     |
| Event Creation     | ❌           | ✅                | ✅                     |
| Multiple Artists   | ❌           | ❌                | ✅                     |
| Priority Support   | ❌           | ✅                | ✅                     |

---

## 🔄 CI/CD Pipeline

The project uses **GitHub Actions** for continuous integration:

- **Automated Testing** - Runs tests for all modules on push/PR
- **Multi-Module Strategy** - Tests each package independently
- **Integration Tests** - Full app testing on PR to main
- **Flutter Version** - 3.19.0 stable channel

```yaml
# Modules tested automatically
- artbeat_core
- artbeat_auth
- artbeat_profile
- artbeat_artwork
- artbeat_artist
- artbeat_art_walk
- artbeat_community
- artbeat_settings
- artbeat_messaging
```

---

## 📁 Project Structure

```
artbeat/
├── 📱 lib/                    # Main application code
│   ├── main.dart             # App entry point
│   ├── firebase_options.dart # Firebase configuration
│   └── ...
├── 📦 packages/              # Feature modules
│   ├── artbeat_core/         # Core components
│   ├── artbeat_auth/         # Authentication
│   └── ...
├── ⚡ functions/             # Firebase Cloud Functions
│   ├── src/                  # TypeScript source
│   └── package.json          # Node.js dependencies
├── 🤖 android/               # Android-specific code
├── 🍎 ios/                   # iOS-specific code
├── 🌐 web/                   # Web platform support
├── 🧪 test/                  # Test files
├── 📜 scripts/               # Build and utility scripts
├── 🎨 assets/                # Images, fonts, resources
└── 📋 docs/                  # Documentation
```

---

## 🔒 Security Features

- **🔐 Firebase App Check** - App integrity verification
- **🛡️ Firestore Security Rules** - Data access control
- **🔑 Secure API Key Management** - Environment-based configuration
- **🚫 Input Validation** - Client and server-side validation
- **📊 Analytics Privacy** - GDPR-compliant tracking

---

## 🚀 Deployment

### 📱 Mobile App Stores

- **Google Play Store** - Android App Bundle (AAB)
- **Apple App Store** - iOS Archive via Xcode
- **TestFlight** - iOS beta testing
- **Google Play Console** - Android internal/closed testing

### ☁️ Backend Services

- **Firebase Hosting** - Web deployment
- **Firebase Functions** - Server-side logic
- **Firestore** - Database deployment
- **Firebase Storage** - File storage

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed deployment instructions.

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Follow code conventions** (Dart style guide)
4. **Write tests** for new functionality
5. **Commit changes** (`git commit -m 'Add amazing feature'`)
6. **Push to branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### 📝 Code Conventions

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use Provider pattern for state management
- Keep UI and business logic separate
- Document public APIs and complex functionality
- Write unit tests for new features

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support & Contact

- **🐛 Bug Reports**: [GitHub Issues](https://github.com/your-username/artbeat/issues)
- **💡 Feature Requests**: [GitHub Discussions](https://github.com/your-username/artbeat/discussions)
- **📧 Email**: support@artbeat.app
- **🌐 Website**: [artbeat.app](https://artbeat.app)

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Firebase Team** - For the comprehensive backend services
- **Google Maps** - For location and mapping services
- **Stripe** - For payment processing
- **Open Source Community** - For the incredible packages and tools

---

<div align="center">
  <p><strong>Made with ❤️ by the ARTbeat Team</strong></p>
  <p><em>Connecting artists and art lovers worldwide</em></p>
</div>
