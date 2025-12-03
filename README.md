
# Rate My Bowl (Yelp but for Public Restrooms)

*Rest in That Room*™

Everyone has been through the pain of having to use a subpar restroom. It always goes the same way: I walk in, have one look at the bathroom, and think "Dang, I should have gone somewhere else. But what's the point? I'm already here". But NO MORE! Now, with this app, and the help of all who contribute ratings, I will finally be able to rest in that room.

## Summary of features

Just what the name implies. Rate, review, and discover public restrooms on the go! Will allow you to pan around on a map and see all the available restrooms, each displaying their average rating, out of 5 stars. You will also be able to add a restroom to the map, or add a review to an existing one. You will be able to report the following information in each review:

- Overall cleanliness (out of 5 stars)
- Toilet paper quality (out of 5 stars)
- Notes about the restroom (text)

In addition, the following general information will be gathered about each restroom, and asked alongside the reviewing process:

- Type of sink (automatic with a sensor or manual with knobs)
- Hand-drying options (air blower, paper towel, or both)
- Does it require a key (i.e. from the receptionist's desk)

## Backend modes

The app can now run against either Supabase or a fully offline SQLite database.
By default Supabase is used, but you can swap backends at compile time with the `USE_SUPABASE` flag:

```bash
flutter run --dart-define=USE_SUPABASE=false
flutter build apk --dart-define=USE_SUPABASE=false
```

When `USE_SUPABASE=false`, the app boots a local SQLite database that mirrors the schema defined in `schema.sql`, seeds a few default restrooms, and includes a demo account (`demo@ratemybowl.app` / `Password123`). You can sign up for additional offline accounts and everything (reviews, new restrooms, auth state) is stored locally so it works without a network connection.

## Roadmap

The Roadmap can be viewed [here](roadmap.md).

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

## Contributing

- Please DO NOT COMMIT DIRECTLY TO MASTER
    - This *will* result in merge conflicts
    - Either create a new branch for a specific feature you're working on, or maintain your personal branch that you merge into master from
- Before making any pull requests to Master, ensure that you are able to run `flutter clean` and `flutter run` without any compilation issues or instant crashes. Thank you!
