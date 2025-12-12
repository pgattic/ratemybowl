
# Rate My Bowl (Yelp but for Public Restrooms)

*Rest in That Room*™

Everyone has been through the pain of having to use a subpar restroom. It always goes the same way: I walk in, have one look at the bathroom, and think "Dang, I should have gone somewhere else. But what's the point? I'm already here". But NO MORE! Now, with this app, and the help of all who contribute ratings, I will finally be able to rest in that room.

## Summary of features

Just what the name implies. Rate, review, and discover public restrooms on the go! This app allows you to pan around on a map and see all the available restrooms, each displaying their average rating, out of 5 stars. In your reviews, you can report the following, each up to 5 stars:

- Baby Changing Station
- Bidet
- Ease of Access
- Feminine Hygiene Products
- Hand-Drying Options
- Personal Space
- Smell
- Toilet Paper Quality
- Wheelchair Accessibility

When `USE_SUPABASE=false`, the app boots a local SQLite database that mirrors the schema defined in `schema.sql`, seeds a few default restrooms, and includes a demo account (`demo@ratemybowl.app` / `Password123`). You can sign up for additional offline accounts and everything (reviews, new restrooms, auth state) is stored locally so it works without a network connection.

## Screenshots

| Login Screen | Map Screen | Reviews Popup | Review Screen | Nearby Screen | Options Screen |
| - | - | - | - | - | - |
| ![Login Screen](screenshots/login_screen.png) | ![Map Screen](screenshots/map_screen.png) | ![Reviews Popup](screenshots/reviews.png) | ![Review Screen](screenshots/review_screen.png) | ![Nearby Screen](screenshots/nearby_screen.png) | ![Options Screen](screenshots/options_screen.png) |

## Dev Environment

### Nix (with Flakes enabled)

- `nix develop`

This will provide a dev shell with a preconfigured Android emulator and system image, Flutter, Android SDK and cmdline-tools, the `firebase-tools` package, and more. Thanks to PlayXDead for his awesome [example flake](https://github.com/PlayXDead/nix-flake-flutter-android-dev-env), off of which ours is based ([Reddit post](https://www.reddit.com/r/NixOS/comments/1ngt889/my_first_flake_flutterandroid_dev_enviroment_with/)).

### Windows

- Follow the [Windows -> Android instructions](https://docs.flutter.dev/get-started/install/windows/mobile) on the Flutter documentation
- Install the [Firebase CLI](https://firebase.google.com/docs/cli)

### MacOS

- Follow the [MacOS instructions](https://docs.flutter.dev/get-started/install/macos) on the Flutter Documentation (choose between iOS and Android)
- Install the [Firebase CLI](https://firebase.google.com/docs/cli)

### Backend modes

The app can be compiled to run against either Supabase or a fully offline SQLite database. By default Supabase is used, but you can swap backends at compile time with the `USE_SUPABASE` flag:

```bash
flutter run --dart-define=USE_SUPABASE=false
flutter build apk --dart-define=USE_SUPABASE=false
```

## Contributing

- Before making any pull requests to `master`, ensure that you are able to run `flutter clean` and `flutter run` without any compilation issues or instant crashes. Thank you!

