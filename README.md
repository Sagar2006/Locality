# Locality

Locality is a Flutter app for borrowing/renting items within a local community. It provides authentication, item listings, image uploads, booking/requests, and profile management using Firebase for backend services and Cloudinary for image hosting.

## Features
- Email/password authentication (Firebase Auth)
- Item listings with images
- Add / edit items (image upload via Cloudinary)
- Request/booking flows between users
- Profile and "my items" management
- Provider-based app-wide state management
- Firebase-backed storage and rules included

## Quick start

Prerequisites
- Flutter SDK (match project's Flutter constraint)
- Android SDK / Xcode (for mobile targets)
- Firebase CLI (optional, for reconfiguration)
- An active Firebase project and Cloudinary account (for image uploads)

Clone and run
```bash
git clone https://github.com/Sagar2006/Locality.git
cd Locality
flutter pub get
flutter run
```

If you change the Firebase project:
- Generate new `firebase_options.dart` with the FlutterFire CLI:
  ```bash
  flutterfire configure
  ```
  or replace `lib/firebase_options.dart` with the one generated for your project.
- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) as needed.

Cloudinary
- The app uses a Cloudinary upload service (lib/services/cloudinary_service.dart). Provide your Cloudinary credentials (API key/secret or upload preset) securely; set them as environment variables or follow the service implementation to configure them.

Build
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

Run tests
```bash
flutter test
```

## Project structure
```
lib/
  main.dart               # App entrypoint, Firebase init, Provider wiring
  firebase_options.dart   # Generated Firebase config
  models/                 # item_model.dart, rental_model.dart, user_model.dart
  providers/              # theme_provider.dart, other providers
  screens/                # UI screens (home, item details, profile, auth, etc.)
    auth/                 # login, register, reset password
  services/               # auth_service.dart, database_service.dart, cloudinary_service.dart
  widgets/                # reusable widgets (item_card, category_tile, ...)
pubspec.yaml
firebase.json
database.rules.json
```

## Notable files
- `lib/main.dart` — initializes Firebase and launches app.
- `lib/services/database_service.dart` — database access (Firestore).
- `lib/services/cloudinary_service.dart` — image upload implementation.
- `lib/providers/theme_provider.dart` — theme management via Provider.
- `lib/screens/` — all screen-level UIs (home, add item, my items, profile, requests, bookings, auth).

## Contributing
- Please open issues for bugs or feature requests.
- If you submit a PR, include a short description and test steps.

## Notes / TODOs
- Confirm how Cloudinary credentials are provided for CI and production.
- Add automated tests for key flows (auth, item CRUD, upload).
- Consider secrets/config management (do not commit API secrets).

## License
Add a LICENSE file if you intend to open-source this project under a specific license.
