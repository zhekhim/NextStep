# untitled

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Run these on terminal
flutter pub add supabase_flutter
flutter pub add sqflite
flutter pub add path
flutter pub add uuid
flutter pub add connectivity_plus
flutter pub add geolocator
flutter pub add flutter_local_notifications
flutter pub add http
flutter pub get

## Supabase credentials

The real Supabase config file is ignored by Git to avoid committing the secret
key. Create your local config from the example:

```sh
copy lib\core\supabase\supabase_config.example.dart lib\core\supabase\supabase_config.dart
```

Then put your actual Supabase URL and secret key in:

```text
lib/core/supabase/supabase_config.dart
```

Alternatively, run the app with the Supabase key supplied at build time:

```sh
flutter run --dart-define=SUPABASE_SECRET_KEY=your-secret-key
```

You can also override the project URL when needed:

```sh
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_SECRET_KEY=your-secret-key
```

