# AAMIR MULTIMEDIA — Public-listener Android starter

The app is designed so listeners do not need accounts. It includes:
- Public home screen and nasheed list
- Play and download actions for published audio
- Separate admin login entry point
- Your supplied logo

## Current status
This is starter source code, not a finished APK. The admin upload screen is a placeholder;
file selection and secure upload still need to be implemented. Backend setup and Android
build/testing are also required.

## Backend setup
1. Create a Supabase project.
2. Enable Email authentication for the administrator only.
3. Run `supabase_schema.sql` in the SQL Editor.
4. Create the `nasheeds` storage bucket (the SQL attempts this).
5. Configure a secure admin allow-list and admin-only database/storage write policies.
   Do not expose service-role keys in the app.
6. Use the Project URL and anon/public key at build time.

## Build
Install Flutter and Android SDK on a computer or use a trusted cloud build service.
Run:
```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
flutter build apk --release --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

The release APK normally appears at:
`build/app/outputs/flutter-apk/app-release.apk`

## Important costs
Supabase free-tier limits apply. SMS is not needed for public listeners. Do not promise
unlimited free storage or bandwidth; review current provider limits before launch.
