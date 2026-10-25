# inSOL8 Mobile

The inSOL8 Mobile is the mobile application for the inSOL8 system. It is intended for users to monitor and interact with the inSOL8 smart solar-powered laundry drying system through a mobile application.

## Technology Stack

- Flutter
- Dart
- Android
- Android SDK
- Android SDK Platform-Tools
- ADB (Android Debug Bridge)

## Prerequisites

Before running the project locally, make sure the following are installed:

- Flutter SDK
- Dart SDK
- Android SDK
- Android SDK Platform-Tools
- Git
- Visual Studio Code
- A physical Android device

You can verify your Flutter installation with:

```bash
flutter --version
dart --version
git --version
```

You can verify your Android development environment with:

```bash
flutter doctor
```

The Android toolchain and a connected Android device should be detected successfully.

## Getting Started

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone <repository-url>
```

Navigate to the project directory:

```bash
cd insol8_mobile
```

### 2. Install Dependencies

Install the project's Flutter dependencies:

```bash
flutter pub get
```

### 3. Connect an Android Device

The project is developed and tested using physical Android devices instead of an Android emulator.

Enable **Developer Options** and **USB Debugging** on your Android device, then connect the device to your computer using a USB cable.

Verify that ADB detects the device:

```bash
adb devices
```

A connected device should appear in the output:

```text
List of devices attached
<device-id>    device
```

You can also verify that Flutter detects the device:

```bash
flutter devices
```

### 4. Start the Development Application

Run the Flutter application:

```bash
flutter run
```

If multiple devices are connected, specify the desired device:

```bash
flutter run -d <device-id>
```

The application will be built and launched directly on the connected Android device.

## Available Commands

| Command | Description |
| ------------------------- | ------------------------------------------------------------ |
| `flutter pub get` | Installs project dependencies. |
| `flutter run` | Builds and runs the application on a connected device. |
| `flutter devices` | Lists devices recognized by Flutter. |
| `flutter doctor` | Checks the Flutter development environment. |
| `flutter analyze` | Analyzes the project for potential code issues. |
| `flutter test` | Runs the project's automated tests. |
| `dart format .` | Formats Dart source files. |
| `flutter build apk` | Builds an Android APK. |
| `flutter build apk --release` | Builds a release APK. |

## Project Structure

The project uses a modular Flutter structure to separate application responsibilities and make the codebase easier to maintain as development progresses.

```text
insol8_mobile/
├── android/                 # Android-specific configuration
├── ios/                     # iOS-specific configuration
├── lib/
│   ├── app/                # Application configuration and routing
│   ├── core/               # Shared constants, utilities, and core services
│   ├── models/             # Application data models
│   ├── screens/             # Application screens and views
│   ├── services/            # API and external service integrations
│   ├── widgets/             # Reusable UI components
│   └── main.dart            # Application entry point
│
├── test/                    # Automated tests
├── web/                     # Web platform configuration
├── windows/                 # Windows platform configuration
├── linux/                   # Linux platform configuration
├── macos/                   # macOS platform configuration
│
├── .gitignore               # Files excluded from version control
├── analysis_options.yaml    # Dart and Flutter analysis configuration
├── pubspec.yaml             # Project metadata and dependencies
└── README.md                # Project documentation
```

The project structure may be expanded or reorganized as new application requirements and features are implemented.

## Environment Variables

Environment-specific configuration should not be committed to the repository.

If environment variables are required by the application, use an appropriate local environment configuration file or configuration mechanism for the Flutter project.

Do not commit API keys, credentials, tokens, device credentials, or other sensitive information to the repository.

## Development Guidelines

Before committing changes, make sure the project passes the available checks:

```bash
flutter analyze
flutter test
```

Developers should:

* Follow the existing project structure.
* Use Dart and Flutter conventions for application code.
* Keep reusable UI components within `lib/widgets`.
* Keep page-level screens within `lib/screens`.
* Keep API and external service communication within `lib/services`.
* Keep shared application models within `lib/models`.
* Keep shared application configuration and utilities within `lib/core`.
* Avoid committing environment files containing sensitive information.
* Test application changes on a physical Android device when applicable.
* Keep commits focused on a specific change or task.

## Git Workflow

Development should follow the team's established Git workflow.

Before starting work:

```bash
git pull
```

Create a feature or task branch rather than working directly on the protected default branch:

```bash
git checkout -b <branch-name>
```

After completing changes:

```bash
flutter analyze
flutter test
```

Then commit the changes:

```bash
git add .
git commit -m "<commit-message>"
```

Push the branch:

```bash
git push -u origin <branch-name>
```

Changes should be submitted through a pull request for review according to the team's repository workflow.

## Physical Device Development

The inSOL8 Mobile application is developed and tested using physical Android devices.

Android Studio and Android Emulator are not required for the project's development workflow.

ADB is used to communicate with connected Android devices.

To check connected devices:

```bash
adb devices
```

If device detection becomes problematic, restart the ADB service:

```bash
adb kill-server
adb start-server
adb devices
```

Flutter can then be used to verify the available development devices:

```bash
flutter devices
```

## Repository

This repository is maintained under the shared inSOL8 GitHub account.

Repository:

`<repository-url>`

Access should be granted only to authorized project members.

## Project Status

This repository currently contains the initial Flutter and Dart application setup. The Android development environment and physical-device testing workflow have been configured successfully.

Application-specific screens, components, services, device communication, and other functionality will be developed as the inSOL8 system progresses.

## License

This project is currently intended for the inSOL8 project team and is not licensed for public redistribution.
