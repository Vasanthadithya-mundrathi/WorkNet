# WorkNet

Passive proximity networking app for tech events.

## Overview

WorkNet enables professionals to discover and connect with others nearby at conferences and tech events through proximity-based networking. No business cards needed—just walk around and let the app do the talking.

## Features

- **Passive Discovery**: Automatically discover nearby professionals using BLE, Multipeer Connectivity, and UDP Broadcast
- **Nearby Feed**: Real-time feed of people in your vicinity
- **Profile Management**: Create and manage your professional profile
- **Privacy Controls**: Fine-tune what you share and with whom
- **Gossip Relay**: Spread your profile across the network through peer-to-peer relay

## Tech Stack

- **Framework**: Flutter 3.4+
- **State Management**: Riverpod
- **Local Storage**: Isar + Hive
- **Navigation**: GoRouter

## Getting Started

### Prerequisites

- Flutter SDK >= 3.4.0 < 4.0.0
- Dart SDK >= 3.4.0 < 4.0.0

### Installation

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for iOS

```bash
flutter build ios --release
```

### Build for Android

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── core/               # Core utilities, theme, router
├── data/               # Models and repositories
├── features/          # Feature modules
│   ├── feed/          # Nearby feed
│   ├── onboarding/    # Onboarding flow
│   ├── profile/       # Profile management
│   ├── search/       # Search functionality
│   └── settings/     # App settings
├── services/         # Business logic services
└── shared/           # Shared widgets
```

## Permissions

- **Bluetooth**: For proximity discovery
- **Local Network**: For local peer communication
- **Notifications**: For connection alerts

## Privacy

All data is stored locally on-device. Profile sharing is opt-in and controlled by the user.

## License

MIT License